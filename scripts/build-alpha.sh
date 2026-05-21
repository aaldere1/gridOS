#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/build-alpha.sh

Creates a signed internal alpha archive and ZIP artifact when local signing
configuration is present. Build products are written only to the local output
directory, which defaults to build/alpha.

Required environment:
  GRIDOS_DEVELOPMENT_TEAM   Apple development team identifier
  GRIDOS_SIGNING_IDENTITY   Local code signing identity name

Optional environment:
  GRIDOS_ALPHA_OUTPUT_DIR   Local artifact output directory (default: build/alpha)
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFLIGHT_SCRIPT="$ROOT_DIR/scripts/alpha-signing-preflight.sh"
EVIDENCE_DIR="$ROOT_DIR/.planning/phases/11-alpha/evidence"
MANIFEST_FILE="$EVIDENCE_DIR/alpha-artifact-manifest.md"
OUTPUT_DIR_INPUT="${GRIDOS_ALPHA_OUTPUT_DIR:-build/alpha}"

if [[ "$OUTPUT_DIR_INPUT" = /* ]]; then
  OUTPUT_DIR="$OUTPUT_DIR_INPUT"
else
  OUTPUT_DIR="$ROOT_DIR/$OUTPUT_DIR_INPUT"
fi

absolute_path() {
  local path="$1"
  local dir
  local base
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  mkdir -p "$dir"
  printf '%s/%s' "$(cd "$dir" && pwd -P)" "$base"
}

fail_if_planning_path() {
  local path
  local planning_dir
  path="$(absolute_path "$1")"
  planning_dir="$(cd "$ROOT_DIR/.planning" && pwd -P)"
  if [[ "$path" == "$planning_dir" || "$path" == "$planning_dir/"* ]]; then
    echo "ALPHA_OUTPUT_BLOCKED: artifacts must not be written under .planning" >&2
    exit 1
  fi
}

project_setting() {
  local key="$1"
  awk -v key="$key" '
    /^  gridOS:$/ { in_target = 1; next }
    in_target && /^  [A-Za-z0-9_]+:$/ { exit }
    in_target && $1 == key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "")
      print
      exit
    }
  ' "$ROOT_DIR/project.yml" | sed -E 's/^"?(.*?)"?$/\1/'
}

plist_value() {
  local plist="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist"
}

fail_if_planning_path "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" "$EVIDENCE_DIR"

# Always run the signing preflight first. When signing inputs are missing, this
# writes presence-only SIGNING_BLOCKED evidence and stops before archive work.
"$PREFLIGHT_SCRIPT"

cd "$ROOT_DIR"
xcodegen generate --use-cache

ARCHIVE_PATH="$OUTPUT_DIR/gridOS.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/gridOS.app"

rm -rf "$ARCHIVE_PATH"

# Archive command: xcodebuild archive
xcodebuild \
  -project gridOS.xcodeproj \
  -scheme gridOS \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$GRIDOS_DEVELOPMENT_TEAM" \
  CODE_SIGN_IDENTITY="$GRIDOS_SIGNING_IDENTITY" \
  CODE_SIGN_STYLE=Manual \
  archive

if [[ ! -d "$APP_PATH" ]]; then
  echo "ALPHA_ARCHIVE_BLOCKED: gridOS.app missing from archive" >&2
  exit 1
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
VERSION="$(plist_value "$INFO_PLIST" CFBundleShortVersionString)"
BUILD="$(plist_value "$INFO_PLIST" CFBundleVersion)"
BUNDLE_ID="$(plist_value "$INFO_PLIST" CFBundleIdentifier)"
SOURCE_COMMIT="$(git rev-parse --short HEAD)"
TIMESTAMP_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
HARDENED_RUNTIME="$(project_setting ENABLE_HARDENED_RUNTIME)"
ARTIFACT_NAME="gridOS-${VERSION}-${BUILD}-${SOURCE_COMMIT}.zip"
ZIP_PATH="$OUTPUT_DIR/$ARTIFACT_NAME"

rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

CHECKSUM="$(shasum -a 256 "$ZIP_PATH" | awk '{ print $1 }')"

cat > "$MANIFEST_FILE" <<EOF
# Alpha artifact manifest

- Timestamp UTC: $TIMESTAMP_UTC
- Source commit: $SOURCE_COMMIT
- Bundle ID: $BUNDLE_ID
- Version: $VERSION
- Build: $BUILD
- Artifact basename: $ARTIFACT_NAME
- SHA-256: $CHECKSUM
- Signing identity: present
- Development team: present
- Hardened runtime: ${HARDENED_RUNTIME:-missing}
- Artifact path policy: local output directory only; no artifacts are stored under .planning.
- Verification command: scripts/verify-alpha-artifact.sh <local-output-dir>/$ARTIFACT_NAME
EOF

printf 'ALPHA_ARTIFACT_READY %s\n' "$ZIP_PATH"
printf 'ALPHA_MANIFEST_WRITTEN %s\n' "$MANIFEST_FILE"
