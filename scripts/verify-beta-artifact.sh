#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/verify-beta-artifact.sh path/to/gridOS.dmg-or-zip-or-app

Verifies a signed and notarized Beta artifact and writes sanitized evidence to:
  .planning/phases/12-beta/evidence/beta-artifact-verification.md
USAGE
}

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  [[ $# -eq 1 ]] && exit 0
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/.planning/phases/12-beta/evidence"
REPORT_FILE="$EVIDENCE_DIR/beta-artifact-verification.md"
MANIFEST_FILE=".planning/phases/12-beta/evidence/beta-artifact-manifest.md"
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
    echo "BETA_VERIFY_BLOCKED: pass artifacts from a local output directory, not .planning" >&2
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
    echo "BETA_VERIFY_BLOCKED: ZIP must contain a single top-level gridOS.app; otherwise pass the extracted app" >&2
    exit 1
  fi

  TMP_EXTRACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gridos-beta-verify.XXXXXX")"
  ditto -x -k "$zip_path" "$TMP_EXTRACT_DIR"

  if [[ ! -d "$TMP_EXTRACT_DIR/gridOS.app" ]]; then
    echo "BETA_VERIFY_BLOCKED: extracted ZIP did not contain gridOS.app" >&2
    exit 1
  fi

  APP_PATH="$TMP_EXTRACT_DIR/gridOS.app"
}

mount_single_gridos_app() {
  local dmg_path="$1"
  local app_count
  local app_path

  DMG_MOUNT_POINT="$(mktemp -d "${TMPDIR:-/tmp}/gridos-beta-dmg.XXXXXX")"
  hdiutil attach "$dmg_path" -nobrowse -readonly -mountpoint "$DMG_MOUNT_POINT" >/dev/null

  app_count="$(find "$DMG_MOUNT_POINT" -maxdepth 1 -name 'gridOS.app' -type d -print | wc -l | tr -d ' ')"
  if [[ "$app_count" != "1" ]]; then
    echo "BETA_VERIFY_BLOCKED: DMG must contain a single top-level gridOS.app" >&2
    exit 1
  fi

  APP_PATH="$(find "$DMG_MOUNT_POINT" -maxdepth 1 -name 'gridOS.app' -type d -print | head -1)"
}

sanitized_codesign_metadata() {
  local app_path="$1"

  codesign -dv "$app_path" 2>&1 |
    awk -F= '
      /^(Identifier|Format|CodeDirectory|Signature|Authority|TeamIdentifier|Runtime|Timestamp)=/ {
        if ($1 == "Authority") {
          print "Authority=present"
        } else {
          print
        }
      }
    '
}

if [[ ! -e "$INPUT_PATH" ]]; then
  echo "BETA_VERIFY_BLOCKED: artifact does not exist" >&2
  exit 1
fi

INPUT_ABS="$(absolute_path "$INPUT_PATH")"
fail_if_planning_path "$INPUT_ABS"

INPUT_TYPE=""
ARTIFACT_BASENAME="$(basename "$INPUT_ABS")"
ARTIFACT_CHECKSUM="not_applicable"
STAPLER_TARGET=""

case "$INPUT_ABS" in
  *.app|*.app/)
    INPUT_TYPE="app"
    APP_PATH="$INPUT_ABS"
    STAPLER_TARGET="$INPUT_ABS"
    ;;
  *.zip)
    INPUT_TYPE="zip"
    ARTIFACT_CHECKSUM="$(file_checksum "$INPUT_ABS")"
    extract_single_gridos_app "$INPUT_ABS"
    STAPLER_TARGET="$APP_PATH"
    ;;
  *.dmg)
    INPUT_TYPE="dmg"
    ARTIFACT_CHECKSUM="$(file_checksum "$INPUT_ABS")"
    mount_single_gridos_app "$INPUT_ABS"
    STAPLER_TARGET="$INPUT_ABS"
    ;;
  *)
    echo "BETA_VERIFY_BLOCKED: pass a .app bundle, .zip artifact, or .dmg artifact" >&2
    exit 1
    ;;
esac

fail_if_planning_path "$(absolute_path "$APP_PATH")"

INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ ! -f "$INFO_PLIST" ]]; then
  echo "BETA_VERIFY_BLOCKED: app Info.plist is missing" >&2
  exit 1
fi

BUNDLE_ID="$(plist_value "$INFO_PLIST" CFBundleIdentifier)"
VERSION="$(plist_value "$INFO_PLIST" CFBundleShortVersionString)"
BUILD="$(plist_value "$INFO_PLIST" CFBundleVersion)"
APP_CHECKSUM="$(bundle_checksum "$APP_PATH")"
TIMESTAMP_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

if codesign --verify --deep --strict --verbose=2 "$APP_PATH" >/dev/null 2>&1; then
  CODESIGN_STATUS="PASS"
else
  CODESIGN_STATUS="FAIL"
fi

CODESIGN_METADATA="$(sanitized_codesign_metadata "$APP_PATH" || true)"
if [[ -z "$CODESIGN_METADATA" ]]; then
  CODESIGN_METADATA="Metadata=unavailable"
fi

if xcrun stapler validate "$STAPLER_TARGET" >/dev/null 2>&1; then
  STAPLER_STATUS="PASS"
else
  STAPLER_STATUS="FAIL"
fi

if spctl --assess --type execute --verbose=4 "$APP_PATH" >/dev/null 2>&1; then
  GATEKEEPER_STATUS="PASS"
else
  GATEKEEPER_STATUS="FAIL"
fi

if [[ "$CODESIGN_STATUS" == "PASS" && "$STAPLER_STATUS" == "PASS" && "$GATEKEEPER_STATUS" == "PASS" ]]; then
  RESULT="PASS"
else
  RESULT="FAIL"
fi

mkdir -p "$EVIDENCE_DIR"

{
  printf '# Beta artifact verification\n\n'
  printf -- '- Timestamp UTC: %s\n' "$TIMESTAMP_UTC"
  printf -- '- Beta artifact manifest: %s\n' "$MANIFEST_FILE"
  printf -- '- Artifact basename: %s\n' "$ARTIFACT_BASENAME"
  printf -- '- Input type: %s\n' "$INPUT_TYPE"
  printf -- '- Artifact SHA-256: %s\n' "$ARTIFACT_CHECKSUM"
  printf -- '- App bundle SHA-256: %s\n' "$APP_CHECKSUM"
  printf -- '- Verification command: codesign --verify --deep --strict --verbose=2\n'
  printf -- '- codesign status: %s\n' "$CODESIGN_STATUS"
  printf -- '- Stapler command: xcrun stapler validate\n'
  printf -- '- Stapler status: %s\n' "$STAPLER_STATUS"
  printf -- '- Gatekeeper command: spctl --assess --type execute --verbose=4\n'
  printf -- '- Gatekeeper status: %s\n' "$GATEKEEPER_STATUS"
  printf -- '- Bundle ID: %s\n' "$BUNDLE_ID"
  printf -- '- Version: %s\n' "$VERSION"
  printf -- '- Build: %s\n' "$BUILD"
  printf -- '- Result: %s\n\n' "$RESULT"
  printf '## Sanitized codesign -dv metadata\n\n'
  printf '```text\n'
  printf '%s\n' "$CODESIGN_METADATA"
  printf '```\n'
} > "$REPORT_FILE"

printf 'BETA_ARTIFACT_VERIFICATION %s\n' "$RESULT"
printf 'BETA_VERIFICATION_REPORT %s\n' "$REPORT_FILE"

if [[ "$RESULT" != "PASS" ]]; then
  exit 1
fi
