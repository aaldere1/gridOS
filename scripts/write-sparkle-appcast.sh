#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/write-sparkle-appcast.sh path/to/gridOS-version-build-commit.dmg

Generates appcast.xml for Sparkle automatic updates using Sparkle's
generate_appcast tool and the gridOS EdDSA signing key stored in Keychain.

Environment:
  GRIDOS_SPARKLE_ACCOUNT              Keychain account (default: com.aaldere1.gridos)
  GRIDOS_SPARKLE_OUTPUT              Appcast path (default: appcast.xml)
  GRIDOS_SPARKLE_DOWNLOAD_URL_PREFIX Override release download URL prefix
  GRIDOS_SPARKLE_RELEASE_LINK        Override release page link
  SPARKLE_BIN                        Override Sparkle bin directory
USAGE
}

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  [[ $# -eq 1 ]] && exit 0
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_PATH="$1"
ARTIFACT_BASENAME="$(basename "$ARTIFACT_PATH")"
ACCOUNT="${GRIDOS_SPARKLE_ACCOUNT:-com.aaldere1.gridos}"
OUTPUT_PATH_INPUT="${GRIDOS_SPARKLE_OUTPUT:-appcast.xml}"
TMP_DIR=""

cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

if [[ ! -f "$ARTIFACT_PATH" ]]; then
  echo "SPARKLE_APPCAST_BLOCKED: artifact missing: $ARTIFACT_PATH" >&2
  exit 1
fi

if [[ "$ARTIFACT_BASENAME" =~ ^gridOS-([0-9]+([.][0-9]+)*)-([0-9]+)-([0-9a-f]+)[.]dmg$ ]]; then
  VERSION="${BASH_REMATCH[1]}"
else
  echo "SPARKLE_APPCAST_BLOCKED: artifact name must look like gridOS-1.0.6-14-abcdef0.dmg" >&2
  exit 1
fi

if [[ "$OUTPUT_PATH_INPUT" = /* ]]; then
  OUTPUT_PATH="$OUTPUT_PATH_INPUT"
else
  OUTPUT_PATH="$ROOT_DIR/$OUTPUT_PATH_INPUT"
fi

if [[ -z "${SPARKLE_BIN:-}" ]]; then
  GENERATE_APPCAST="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path '*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast' -print -quit)"
  if [[ -n "$GENERATE_APPCAST" ]]; then
    SPARKLE_BIN="$(dirname "$GENERATE_APPCAST")"
  fi
fi

if [[ -z "$SPARKLE_BIN" || ! -x "$SPARKLE_BIN/generate_appcast" ]]; then
  echo "SPARKLE_APPCAST_BLOCKED: Sparkle generate_appcast tool not found" >&2
  exit 1
fi

RELEASE_TAG="v$VERSION"
DOWNLOAD_URL_PREFIX="${GRIDOS_SPARKLE_DOWNLOAD_URL_PREFIX:-https://github.com/aaldere1/gridOS/releases/download/$RELEASE_TAG/}"
RELEASE_LINK="${GRIDOS_SPARKLE_RELEASE_LINK:-https://github.com/aaldere1/gridOS/releases/tag/$RELEASE_TAG}"
RELEASE_NOTES="$ROOT_DIR/docs/release-notes/$RELEASE_TAG.md"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gridos-sparkle-appcast.XXXXXX")"
cp "$ARTIFACT_PATH" "$TMP_DIR/$ARTIFACT_BASENAME"

if [[ -f "$RELEASE_NOTES" ]]; then
  cp "$RELEASE_NOTES" "$TMP_DIR/${ARTIFACT_BASENAME%.dmg}.md"
fi

if [[ -f "$OUTPUT_PATH" ]]; then
  cp "$OUTPUT_PATH" "$TMP_DIR/appcast.xml"
fi

"$SPARKLE_BIN/generate_appcast" \
  --account "$ACCOUNT" \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  --link "$RELEASE_LINK" \
  --embed-release-notes \
  --maximum-versions 5 \
  -o "$TMP_DIR/appcast.xml" \
  "$TMP_DIR"

mkdir -p "$(dirname "$OUTPUT_PATH")"
cp "$TMP_DIR/appcast.xml" "$OUTPUT_PATH"

printf 'SPARKLE_APPCAST_WRITTEN %s\n' "$OUTPUT_PATH"
