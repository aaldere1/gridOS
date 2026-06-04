#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "CI_BUILD_TEST_BLOCKED: xcodegen is required" >&2
  exit 1
fi

echo "CI_XCODEBUILD_VERSION"
xcodebuild -version

echo "CI_XCODEGEN_VERSION"
xcodegen --version

xcodegen generate --use-cache

if ! git diff --quiet -- gridOS.xcodeproj; then
  echo "CI_BUILD_TEST_BLOCKED: generated gridOS.xcodeproj differs from git" >&2
  echo "Run xcodegen generate --use-cache and commit the project changes." >&2
  git diff -- gridOS.xcodeproj
  exit 1
fi

destination="${CI_XCODE_DESTINATION:-platform=macOS,arch=$(uname -m)}"
echo "CI_XCODE_DESTINATION=${destination}"

xcodebuild \
  -project gridOS.xcodeproj \
  -scheme gridOS \
  -destination "${destination}" \
  CODE_SIGNING_ALLOWED=NO \
  build test

git diff --check
