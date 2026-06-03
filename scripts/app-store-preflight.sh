#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENTITLEMENTS="Sources/GridOSApp/GridOSApp.entitlements"
PRIVACY_MANIFEST="Sources/GridOSApp/PrivacyInfo.xcprivacy"

if [[ ! -f "$ENTITLEMENTS" ]]; then
  echo "APP_STORE_PREFLIGHT FAIL missing_entitlements"
  exit 1
fi

if [[ ! -f "$PRIVACY_MANIFEST" ]]; then
  echo "APP_STORE_PREFLIGHT FAIL missing_privacy_manifest"
  exit 1
fi

plutil -lint "$ENTITLEMENTS" >/dev/null
plutil -lint "$PRIVACY_MANIFEST" >/dev/null

if rg -q "CODE_SIGN_ENTITLEMENTS: Sources/GridOSApp/GridOSApp.entitlements" project.yml; then
  echo "APP_STORE_PREFLIGHT FAIL direct_target_sandboxed"
  exit 1
fi

rg -q "com.apple.security.app-sandbox" "$ENTITLEMENTS"
rg -q "com.apple.security.network.client" "$ENTITLEMENTS"
rg -q "NSPrivacyTracking" "$PRIVACY_MANIFEST"
rg -q "NSPrivacyAccessedAPICategoryUserDefaults" "$PRIVACY_MANIFEST"
rg -q "NSPrivacyAccessedAPICategoryDiskSpace" "$PRIVACY_MANIFEST"

if rg -n "com.apple.security.temporary-exception|com.apple.security.network.server|com.apple.security.files.downloads" "$ENTITLEMENTS"; then
  echo "APP_STORE_PREFLIGHT FAIL high_scrutiny_entitlement_present"
  exit 1
fi

if rg -n "Beta Privacy|Review Beta Privacy|Feedback template: \\.planning" Sources; then
  echo "APP_STORE_PREFLIGHT FAIL beta_or_repo_internal_copy_in_sources"
  exit 1
fi

echo "APP_STORE_PREFLIGHT PREPARED"
