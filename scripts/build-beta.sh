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
DMG_LAYOUT_MOUNT_POINT=""
DMG_LAYOUT_SCRIPT=""
RW_DMG_PATH=""

cleanup() {
  if [[ -n "$DMG_LAYOUT_MOUNT_POINT" && -d "$DMG_LAYOUT_MOUNT_POINT" ]]; then
    hdiutil detach "$DMG_LAYOUT_MOUNT_POINT" -quiet >/dev/null 2>&1 || true
    rmdir "$DMG_LAYOUT_MOUNT_POINT" >/dev/null 2>&1 || true
  fi
  if [[ -n "$DMG_LAYOUT_SCRIPT" && -f "$DMG_LAYOUT_SCRIPT" ]]; then
    rm -f "$DMG_LAYOUT_SCRIPT"
  fi
  if [[ -n "$RW_DMG_PATH" && -f "$RW_DMG_PATH" ]]; then
    rm -f "$RW_DMG_PATH"
  fi
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

create_dmg_background() {
  local output_path="$1"
  DMG_LAYOUT_SCRIPT="$(mktemp "${TMPDIR:-/tmp}/gridos-dmg-background.XXXXXX.swift")"

  cat > "$DMG_LAYOUT_SCRIPT" <<'SWIFT'
import AppKit
import Darwin
import Foundation

guard CommandLine.arguments.count == 2 else {
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 660, height: 420)
let canvas = NSRect(origin: .zero, size: size)
let image = NSImage(size: size)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func drawText(
    _ text: String,
    in rect: NSRect,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    alignment: NSTextAlignment = .center
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]

    (text as NSString).draw(in: rect, withAttributes: attributes)
}

image.lockFocus()

NSGradient(colors: [
    color(0.022, 0.028, 0.034, 1.0),
    color(0.006, 0.008, 0.012, 1.0)
])?.draw(in: canvas, angle: -32)

color(0.0, 0.86, 0.95, 0.10).setFill()
NSBezierPath(ovalIn: NSRect(x: 470, y: 260, width: 260, height: 220)).fill()

color(1.0, 1.0, 1.0, 0.045).setFill()
NSBezierPath(roundedRect: NSRect(x: 76, y: 126, width: 190, height: 170), xRadius: 24, yRadius: 24).fill()
NSBezierPath(roundedRect: NSRect(x: 394, y: 126, width: 190, height: 170), xRadius: 24, yRadius: 24).fill()

color(1.0, 1.0, 1.0, 0.10).setStroke()
let leftSlot = NSBezierPath(roundedRect: NSRect(x: 76, y: 126, width: 190, height: 170), xRadius: 24, yRadius: 24)
leftSlot.lineWidth = 1
leftSlot.stroke()
let rightSlot = NSBezierPath(roundedRect: NSRect(x: 394, y: 126, width: 190, height: 170), xRadius: 24, yRadius: 24)
rightSlot.lineWidth = 1
rightSlot.stroke()

drawText(
    "Drag gridOS into Applications",
    in: NSRect(x: 0, y: 342, width: 660, height: 34),
    size: 24,
    weight: .semibold,
    color: color(0.92, 0.98, 1.0, 0.95)
)
drawText(
    "Install once. Launch from Applications.",
    in: NSRect(x: 0, y: 316, width: 660, height: 24),
    size: 13,
    weight: .regular,
    color: color(0.78, 0.88, 0.92, 0.68)
)

let arrowY: CGFloat = 210
let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 278, y: arrowY))
arrow.line(to: NSPoint(x: 406, y: arrowY))
arrow.lineWidth = 7
arrow.lineCapStyle = .round
color(0.0, 0.92, 1.0, 0.80).setStroke()
arrow.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 430, y: arrowY))
arrowHead.line(to: NSPoint(x: 394, y: arrowY + 24))
arrowHead.line(to: NSPoint(x: 394, y: arrowY - 24))
arrowHead.close()
color(0.0, 0.92, 1.0, 0.86).setFill()
arrowHead.fill()

drawText(
    "signed and notarized",
    in: NSRect(x: 0, y: 34, width: 660, height: 20),
    size: 11,
    weight: .medium,
    color: color(0.54, 0.72, 0.76, 0.62)
)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    exit(65)
}

do {
    try png.write(to: outputURL, options: .atomic)
} catch {
    exit(66)
}
SWIFT

  swift "$DMG_LAYOUT_SCRIPT" "$output_path"
  rm -f "$DMG_LAYOUT_SCRIPT"
  DMG_LAYOUT_SCRIPT=""
}

create_dmg_artifact() {
  local app_path="$1"
  local dmg_path="$2"
  local rw_dmg_path="$3"
  local background_dir
  local background_path

  STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gridos-beta-dmg.XXXXXX")"
  background_dir="$STAGING_DIR/.background"
  background_path="$background_dir/gridOS-dmg-background.png"

  mkdir -p "$background_dir"
  ditto "$app_path" "$STAGING_DIR/gridOS.app"
  ln -s /Applications "$STAGING_DIR/Applications"
  create_dmg_background "$background_path"
  chflags hidden "$background_dir" >/dev/null 2>&1 || true
  if command -v SetFile >/dev/null 2>&1; then
    SetFile -a V "$background_dir" >/dev/null 2>&1 || true
  fi

  RW_DMG_PATH="$rw_dmg_path"
  rm -f "$RW_DMG_PATH"
  hdiutil create -volname gridOS -srcfolder "$STAGING_DIR" -ov -format UDRW "$RW_DMG_PATH" >/dev/null

  DMG_LAYOUT_MOUNT_POINT="$(mktemp -d "${TMPDIR:-/tmp}/gridos-dmg-layout.XXXXXX")"
  hdiutil attach "$RW_DMG_PATH" -nobrowse -mountpoint "$DMG_LAYOUT_MOUNT_POINT" -owners on >/dev/null

  osascript <<EOF
tell application "Finder"
  set dmgFolder to POSIX file "$DMG_LAYOUT_MOUNT_POINT/" as alias
  set backgroundFile to POSIX file "$DMG_LAYOUT_MOUNT_POINT/.background/gridOS-dmg-background.png" as alias
  open dmgFolder
  delay 0.5
  set dmgWindow to container window of dmgFolder
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set bounds of dmgWindow to {120, 120, 780, 540}
  set viewOptions to icon view options of dmgWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 96
  set background picture of viewOptions to backgroundFile
  try
    set position of item ".background" of dmgWindow to {1000, 1000}
  end try
  set position of item "gridOS.app" of dmgWindow to {180, 220}
  set position of item "Applications" of dmgWindow to {500, 220}
  update dmgFolder without registering applications
  delay 1
  close dmgWindow
end tell
EOF

  sync
  hdiutil detach "$DMG_LAYOUT_MOUNT_POINT" -quiet
  rmdir "$DMG_LAYOUT_MOUNT_POINT" >/dev/null 2>&1 || true
  DMG_LAYOUT_MOUNT_POINT=""

  hdiutil convert "$RW_DMG_PATH" -format UDZO -imagekey zlib-level=9 -o "$dmg_path" >/dev/null
  rm -f "$RW_DMG_PATH"
  RW_DMG_PATH=""
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
create_dmg_artifact "$APP_PATH" "$DMG_PATH" "$OUTPUT_DIR/${ARTIFACT_STEM}-rw.dmg"
codesign --force --sign "$GRIDOS_SIGNING_IDENTITY" --timestamp "$DMG_PATH"

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
- DMG code signature: present
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
