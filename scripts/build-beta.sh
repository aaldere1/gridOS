#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/build-beta.sh

Creates a signed Beta archive, ZIP, and DMG artifact when local signing and
notary configuration are present. Build products are written only to the local
output directory, which defaults to build/beta.

Required configuration:
  One notary credential mode accepted by scripts/beta-notarization-preflight.sh

Optional signing overrides:
  GRIDOS_DEVELOPMENT_TEAM   Apple development team identifier
  GRIDOS_SIGNING_IDENTITY   Local Developer ID Application identity name

Optional environment:
  CURRENT_PROJECT_VERSION   Override project build number
  GRIDOS_BETA_OUTPUT_DIR    Local artifact output directory (default: build/beta)
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFLIGHT_SCRIPT="$ROOT_DIR/scripts/beta-notarization-preflight.sh"
EVIDENCE_DIR="$ROOT_DIR/.planning/phases/12-beta/evidence"
MANIFEST_FILE="$EVIDENCE_DIR/beta-artifact-manifest.md"
OUTPUT_DIR_INPUT="${GRIDOS_BETA_OUTPUT_DIR:-build/beta}"
STAGING_DIR=""

cleanup() {
  if [[ -n "$STAGING_DIR" && -d "$STAGING_DIR" ]]; then
    rm -rf "$STAGING_DIR"
  fi
}
trap cleanup EXIT

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
    echo "BETA_OUTPUT_BLOCKED: artifacts must not be written under .planning" >&2
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
  ' "$ROOT_DIR/project.yml" |
    sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^"//; s/"$//'
}

plist_value() {
  local plist="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist"
}

developer_id_identity() {
  security find-identity -v -p codesigning 2>/dev/null |
    awk -F\" '/"Developer ID Application:/ { print $2; exit }'
}

team_id_from_identity() {
  local identity="$1"
  sed -nE 's/.*\(([A-Z0-9]{10})\)$/\1/p' <<< "$identity"
}

file_checksum() {
  local path="$1"
  shasum -a 256 "$path" | awk '{ print $1 }'
}

fail_if_planning_path "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" "$EVIDENCE_DIR"

# The Beta lane requires both signing and a notary credential mode before
# archiving, so missing external release inputs stop before artifacts are built.
GRIDOS_SIGNING_IDENTITY="${GRIDOS_SIGNING_IDENTITY:-$(developer_id_identity || true)}"
GRIDOS_DEVELOPMENT_TEAM="${GRIDOS_DEVELOPMENT_TEAM:-$(team_id_from_identity "$GRIDOS_SIGNING_IDENTITY")}"
export GRIDOS_DEVELOPMENT_TEAM
export GRIDOS_SIGNING_IDENTITY
CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:-$(project_setting CURRENT_PROJECT_VERSION)}"
if [[ -z "$CURRENT_PROJECT_VERSION" ]]; then
  echo "BETA_ARCHIVE_BLOCKED: CURRENT_PROJECT_VERSION could not be resolved" >&2
  exit 1
fi
export CURRENT_PROJECT_VERSION
"$PREFLIGHT_SCRIPT"

cd "$ROOT_DIR"
xcodegen generate --use-cache

ARCHIVE_PATH="$OUTPUT_DIR/gridOS.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/gridOS.app"

rm -rf "$ARCHIVE_PATH"

xcodebuild \
  -project gridOS.xcodeproj \
  -scheme gridOS \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$GRIDOS_DEVELOPMENT_TEAM" \
  CODE_SIGN_IDENTITY="$GRIDOS_SIGNING_IDENTITY" \
  CURRENT_PROJECT_VERSION="$CURRENT_PROJECT_VERSION" \
  CODE_SIGN_STYLE=Manual \
  archive

if [[ ! -d "$APP_PATH" ]]; then
  echo "BETA_ARCHIVE_BLOCKED: gridOS.app missing from archive" >&2
  exit 1
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
VERSION="$(plist_value "$INFO_PLIST" CFBundleShortVersionString)"
BUILD="$(plist_value "$INFO_PLIST" CFBundleVersion)"
BUNDLE_ID="$(plist_value "$INFO_PLIST" CFBundleIdentifier)"
SOURCE_COMMIT="$(git rev-parse --short HEAD)"
TIMESTAMP_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
HARDENED_RUNTIME="$(project_setting ENABLE_HARDENED_RUNTIME)"
ARTIFACT_STEM="gridOS-${VERSION}-${BUILD}-${SOURCE_COMMIT}"
ZIP_NAME="${ARTIFACT_STEM}.zip"
DMG_NAME="${ARTIFACT_STEM}.dmg"
ZIP_PATH="$OUTPUT_DIR/$ZIP_NAME"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"

rm -f "$ZIP_PATH" "$DMG_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gridos-beta-dmg.XXXXXX")"
ditto "$APP_PATH" "$STAGING_DIR/gridOS.app"
hdiutil create -volname gridOS -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

ZIP_CHECKSUM="$(file_checksum "$ZIP_PATH")"
DMG_CHECKSUM="$(file_checksum "$DMG_PATH")"

cat > "$MANIFEST_FILE" <<EOF
# Beta artifact manifest

- Timestamp UTC: $TIMESTAMP_UTC
- Source commit: $SOURCE_COMMIT
- Bundle ID: $BUNDLE_ID
- Version: $VERSION
- Build: $BUILD
- ZIP basename: $ZIP_NAME
- ZIP SHA-256: $ZIP_CHECKSUM
- DMG basename: $DMG_NAME
- DMG SHA-256 before notarization/stapling: $DMG_CHECKSUM
- Signing identity: present
- Development team: present
- Hardened runtime: ${HARDENED_RUNTIME:-missing}
- Artifact path policy: local output directory only; no artifacts are stored under .planning.
- Notarization command: scripts/notarize-beta-artifact.sh <local-output-dir>/$DMG_NAME
- Verification command: scripts/verify-beta-artifact.sh <local-output-dir>/$DMG_NAME
- Final distribution SHA-256 is recorded after stapling in .planning/phases/12-beta/beta-release-manifest.json and .planning/phases/12-beta/evidence/beta-artifact-verification.md.
EOF

printf 'BETA_ARTIFACT_READY %s\n' "$DMG_PATH"
printf 'BETA_ZIP_READY %s\n' "$ZIP_PATH"
printf 'BETA_MANIFEST_WRITTEN %s\n' "$MANIFEST_FILE"
