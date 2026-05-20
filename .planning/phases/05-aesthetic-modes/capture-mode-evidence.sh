#!/usr/bin/env bash
set -euo pipefail

APP_BUNDLE_IDENTIFIER="com.aaldere1.gridos"
APP_PATH=".build/phase5-derived-data/Build/Products/Debug/gridOS.app"
EVIDENCE_DIR=".planning/phases/05-aesthetic-modes/evidence"
SHARED_MODE_SEED="phase5-evidence-shared-seed"
CAPTURE_X="${GRIDOS_CAPTURE_X:-160}"
CAPTURE_Y="${GRIDOS_CAPTURE_Y:-120}"
CAPTURE_WIDTH="${GRIDOS_CAPTURE_WIDTH:-1440}"
CAPTURE_HEIGHT="${GRIDOS_CAPTURE_HEIGHT:-900}"

validate_integer() {
    local name="$1"
    local value="$2"

    case "$value" in
        ""|*[!0-9]*)
            printf 'Invalid %s: %s\n' "$name" "$value" >&2
            exit 1
            ;;
    esac
}

validate_integer GRIDOS_CAPTURE_X "$CAPTURE_X"
validate_integer GRIDOS_CAPTURE_Y "$CAPTURE_Y"
validate_integer GRIDOS_CAPTURE_WIDTH "$CAPTURE_WIDTH"
validate_integer GRIDOS_CAPTURE_HEIGHT "$CAPTURE_HEIGHT"

xcodebuild -quiet \
    -project gridOS.xcodeproj \
    -scheme gridOS \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath .build/phase5-derived-data \
    CODE_SIGNING_ALLOWED=NO \
    build

mkdir -p "$EVIDENCE_DIR"

quit_gridos() {
    /usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "System Events"
    if exists application process "gridOS" then
        tell application "gridOS" to quit
    end if
end tell
APPLESCRIPT
    sleep 1
}

prepare_frontmost_window() {
    /usr/bin/osascript <<APPLESCRIPT
set targetX to $CAPTURE_X
set targetY to $CAPTURE_Y
set targetWidth to $CAPTURE_WIDTH
set targetHeight to $CAPTURE_HEIGHT
set tolerance to 12
set deadline to (current date) + 15

tell application "gridOS" to activate

repeat
    tell application "System Events"
        if exists application process "gridOS" then
            tell application process "gridOS"
                set frontmost to true
                if (count of windows) > 0 then
                    set targetWindow to window 1
                    set position of targetWindow to {targetX, targetY}
                    set size of targetWindow to {targetWidth, targetHeight}

                    set observedPosition to position of targetWindow
                    set observedSize to size of targetWindow
                    set observedX to item 1 of observedPosition as integer
                    set observedY to item 2 of observedPosition as integer
                    set observedWidth to item 1 of observedSize as integer
                    set observedHeight to item 2 of observedSize as integer
                    set minimizedValue to false
                    try
                        set minimizedValue to value of attribute "AXMinimized" of targetWindow
                    end try

                    if frontmost is true and minimizedValue is false and observedX is greater than or equal to (targetX - tolerance) and observedX is less than or equal to (targetX + tolerance) and observedY is greater than or equal to (targetY - tolerance) and observedY is less than or equal to (targetY + tolerance) and observedWidth is greater than or equal to (targetWidth - tolerance) and observedWidth is less than or equal to (targetWidth + tolerance) and observedHeight is greater than or equal to (targetHeight - tolerance) and observedHeight is less than or equal to (targetHeight + tolerance) then
                        return "gridOS frontmost at " & observedX & "," & observedY & "," & observedWidth & "," & observedHeight
                    end if
                end if
            end tell
        end if
    end tell

    if (current date) > deadline then
        error "gridOS window did not become frontmost and sized for isolated capture"
    end if

    delay 0.25
end repeat
APPLESCRIPT
}

gridos_window_id() {
    /usr/bin/swift -e 'import Foundation; import CoreGraphics
let windows = (CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
for window in windows {
    let owner = window[kCGWindowOwnerName as String] as? String
    let layer = (window[kCGWindowLayer as String] as? NSNumber)?.intValue ?? -1
    guard owner == "gridOS", layer == 0 else { continue }
    guard let number = (window[kCGWindowNumber as String] as? NSNumber)?.uint32Value else { continue }

    let bounds = window[kCGWindowBounds as String] as? [String: Any]
    let width = (bounds?["Width"] as? NSNumber)?.doubleValue ?? 0
    let height = (bounds?["Height"] as? NSNumber)?.doubleValue ?? 0
    if width >= 800 && height >= 500 {
        print(number)
        exit(0)
    }
}
exit(1)'
}

capture() {
    local mode="$1"
    local seed="$2"
    local filename="$3"
    local label="$4"
    local window_id

    /usr/bin/defaults write "$APP_BUNDLE_IDENTIFIER" appearance.visualMode -string "$mode"
    /usr/bin/defaults write "$APP_BUNDLE_IDENTIFIER" appearance.installSeed -string "$seed"

    quit_gridos
    /usr/bin/open -n "$APP_PATH" --args --cmd "printf 'GRIDOS_PHASE5_$label\n'; sleep 30"
    prepare_frontmost_window
    window_id="$(gridos_window_id)"
    sleep 1
    /usr/sbin/screencapture -x -l "$window_id" "$EVIDENCE_DIR/$filename"
    quit_gridos
}

mode_comparison_captures=(
    "tron:tron.png"
    "severance:severance.png"
    "appleNative:apple-native.png"
)

for capture_pair in "${mode_comparison_captures[@]}"; do
    IFS=":" read -r mode filename <<< "$capture_pair"
    capture "$mode" "$SHARED_MODE_SEED" "$filename" "${mode}_SHARED_SEED"
done

install_variation_captures=(
    "phase5-tron-install-a:tron-install-a.png"
    "phase5-tron-install-b:tron-install-b.png"
    "phase5-tron-install-c:tron-install-c.png"
)

for capture_pair in "${install_variation_captures[@]}"; do
    IFS=":" read -r seed filename <<< "$capture_pair"
    capture "tron" "$seed" "$filename" "${seed}"
done

/usr/bin/sips -g pixelWidth -g pixelHeight "$EVIDENCE_DIR"/*.png
