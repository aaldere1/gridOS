#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/write-beta-release-manifest.sh path/to/gridOS.dmg-or-zip-or-app

Writes a sanitized Beta release manifest to:
  .planning/phases/12-beta/beta-release-manifest.json
USAGE
}

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  [[ $# -eq 1 ]] && exit 0
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_FILE="$ROOT_DIR/.planning/phases/12-beta/beta-release-manifest.json"
INPUT_PATH="$1"
TMP_EXTRACT_DIR=""
DMG_MOUNT_POINT=""

cleanup() {
  if [[ -n "$DMG_MOUNT_POINT" && -d "$DMG_MOUNT_POINT" ]]; then
    hdiutil detach "$DMG_MOUNT_POINT" -quiet >/dev/null 2>&1 || true
    rmdir "$DMG_MOUNT_POINT" >/dev/null 2>&1 || true
  fi
  if [[ -n "$TMP_EXTRACT_DIR" && -d "$TMP_EXTRACT_DIR" ]]; then
    rm -rf "$TMP_EXTRACT_DIR"
  fi
}
trap cleanup EXIT

absolute_path() {
  local path="$1"
  local dir
  local base
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  printf '%s/%s' "$(cd "$dir" && pwd -P)" "$base"
}

fail_if_planning_path() {
  local path="$1"
  local planning_dir
  planning_dir="$(cd "$ROOT_DIR/.planning" && pwd -P)"
  if [[ "$path" == "$planning_dir" || "$path" == "$planning_dir/"* ]]; then
    echo "BETA_MANIFEST_BLOCKED: pass artifacts from a local output directory, not .planning" >&2
    exit 1
  fi
}

plist_value() {
  local plist="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist"
}

file_checksum() {
  local path="$1"
  shasum -a 256 "$path" | awk '{ print $1 }'
}

bundle_checksum() {
  local app_path="$1"
  find "$app_path" -type f -print |
    LC_ALL=C sort |
    while IFS= read -r file; do
      shasum -a 256 "$file" | awk '{ print $1 }'
    done |
    shasum -a 256 |
    awk '{ print $1 }'
}

zip_entries() {
  zipinfo -1 "$1"
}

extract_single_gridos_app() {
  local zip_path="$1"
  local app_roots
  local app_count

  app_roots="$(zip_entries "$zip_path" | awk -F/ '$1 ~ /\.app$/ { print $1 }' | sort -u)"
  app_count="$(printf '%s\n' "$app_roots" | sed '/^$/d' | wc -l | tr -d ' ')"

  if [[ "$app_count" != "1" || "$app_roots" != "gridOS.app" ]]; then
    echo "BETA_MANIFEST_BLOCKED: ZIP must contain a single top-level gridOS.app" >&2
    exit 1
  fi

  TMP_EXTRACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gridos-beta-manifest.XXXXXX")"
  ditto -x -k "$zip_path" "$TMP_EXTRACT_DIR"

  if [[ ! -d "$TMP_EXTRACT_DIR/gridOS.app" ]]; then
    echo "BETA_MANIFEST_BLOCKED: extracted ZIP did not contain gridOS.app" >&2
    exit 1
  fi

  printf '%s\n' "$TMP_EXTRACT_DIR/gridOS.app"
}

mount_single_gridos_app() {
  local dmg_path="$1"
  local app_count
  local app_path

  DMG_MOUNT_POINT="$(mktemp -d "${TMPDIR:-/tmp}/gridos-beta-manifest-dmg.XXXXXX")"
  hdiutil attach "$dmg_path" -nobrowse -readonly -mountpoint "$DMG_MOUNT_POINT" >/dev/null

  app_count="$(find "$DMG_MOUNT_POINT" -maxdepth 1 -name 'gridOS.app' -type d -print | wc -l | tr -d ' ')"
  if [[ "$app_count" != "1" ]]; then
    echo "BETA_MANIFEST_BLOCKED: DMG must contain a single top-level gridOS.app" >&2
    exit 1
  fi

  app_path="$(find "$DMG_MOUNT_POINT" -maxdepth 1 -name 'gridOS.app' -type d -print | head -1)"
  printf '%s\n' "$app_path"
}

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

if [[ ! -e "$INPUT_PATH" ]]; then
  echo "BETA_MANIFEST_BLOCKED: artifact does not exist" >&2
  exit 1
fi

INPUT_ABS="$(absolute_path "$INPUT_PATH")"
fail_if_planning_path "$INPUT_ABS"

case "$INPUT_ABS" in
  *.app|*.app/)
    ARTIFACT_TYPE="app"
    ARTIFACT_SHA256="$(bundle_checksum "$INPUT_ABS")"
    APP_PATH="$INPUT_ABS"
    ;;
  *.zip)
    ARTIFACT_TYPE="zip"
    ARTIFACT_SHA256="$(file_checksum "$INPUT_ABS")"
    APP_PATH="$(extract_single_gridos_app "$INPUT_ABS")"
    ;;
  *.dmg)
    ARTIFACT_TYPE="dmg"
    ARTIFACT_SHA256="$(file_checksum "$INPUT_ABS")"
    APP_PATH="$(mount_single_gridos_app "$INPUT_ABS")"
    ;;
  *)
    echo "BETA_MANIFEST_BLOCKED: pass a .app bundle, .zip artifact, or .dmg artifact" >&2
    exit 1
    ;;
esac

INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ ! -f "$INFO_PLIST" ]]; then
  echo "BETA_MANIFEST_BLOCKED: app Info.plist is missing" >&2
  exit 1
fi

ARTIFACT_NAME="$(basename "$INPUT_ABS")"
BUNDLE_ID="$(plist_value "$INFO_PLIST" CFBundleIdentifier)"
VERSION="$(plist_value "$INFO_PLIST" CFBundleShortVersionString)"
BUILD="$(plist_value "$INFO_PLIST" CFBundleVersion)"
SOURCE_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
GENERATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

mkdir -p "$(dirname "$MANIFEST_FILE")"

cat > "$MANIFEST_FILE" <<EOF
{
  "channel": "beta",
  "artifact": {
    "name": "$(json_escape "$ARTIFACT_NAME")",
    "type": "$(json_escape "$ARTIFACT_TYPE")",
    "sha256": "$(json_escape "$ARTIFACT_SHA256")"
  },
  "sha256": "$(json_escape "$ARTIFACT_SHA256")",
  "bundleIdentifier": "$(json_escape "$BUNDLE_ID")",
  "version": "$(json_escape "$VERSION")",
  "build": "$(json_escape "$BUILD")",
  "sourceCommit": "$(json_escape "$SOURCE_COMMIT")",
  "generatedAt": "$(json_escape "$GENERATED_AT")",
  "notarization": {
    "status": "pending",
    "evidence": ".planning/phases/12-beta/evidence/beta-notarization.md"
  },
  "gatekeeper": {
    "status": "pending",
    "evidence": ".planning/phases/12-beta/evidence/beta-artifact-verification.md"
  },
  "releaseNotes": "docs/beta-distribution.md",
  "updateInstructions": "docs/beta-distribution.md#update-from-beta-n-to-beta-n1",
  "rollback": "docs/beta-distribution.md#rollback"
}
EOF

printf 'BETA_RELEASE_MANIFEST_WRITTEN %s\n' "$MANIFEST_FILE"
