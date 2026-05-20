#!/usr/bin/env bash
set -euo pipefail

APP_BUNDLE_IDENTIFIER="com.aaldere1.gridos"
APP_PATH=".build/phase5-derived-data/Build/Products/Debug/gridOS.app"
EVIDENCE_DIR=".planning/phases/05-aesthetic-modes/evidence"
SHARED_MODE_SEED="phase5-evidence-shared-seed"

xcodebuild -quiet \
    -project gridOS.xcodeproj \
    -scheme gridOS \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath .build/phase5-derived-data \
    CODE_SIGNING_ALLOWED=NO \
    build

mkdir -p "$EVIDENCE_DIR"

capture() {
    local mode="$1"
    local seed="$2"
    local filename="$3"
    local label="$4"

    /usr/bin/defaults write "$APP_BUNDLE_IDENTIFIER" appearance.visualMode -string "$mode"
    /usr/bin/defaults write "$APP_BUNDLE_IDENTIFIER" appearance.installSeed -string "$seed"

    /usr/bin/open -n "$APP_PATH" --args --cmd "printf 'GRIDOS_PHASE5_$label\n'; sleep 30"
    sleep 3
    /usr/sbin/screencapture -x "$EVIDENCE_DIR/$filename"
    /usr/bin/osascript -e 'tell application "gridOS" to quit'
    sleep 1
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
