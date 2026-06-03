# Phase 13-01 Summary - App Store readiness foundation

**Status:** complete
**Completed:** 2026-06-02T21:32:48Z

## What changed

- Added `Sources/GridOSApp/GridOSApp.entitlements`.
- Staged App Sandbox and outbound network client entitlement declarations for a future App Store build.
- Added `Sources/GridOSApp/PrivacyInfo.xcprivacy`.
- Declared required-reason API usage for app preferences/UserDefaults and disk-space metrics.
- Added `docs/app-store-readiness.md`.
- Added `scripts/app-store-preflight.sh`.
- Removed Beta-specific and repo-internal copy from the visible Settings privacy section.

## 2026-06-03 amendment

The default direct Developer ID Beta target is intentionally unsandboxed again.
`Sources/GridOSApp/GridOSApp.entitlements` remains staged for a future dedicated
App Store build configuration, but `project.yml` no longer applies
`CODE_SIGN_ENTITLEMENTS` to the main `gridOS` target. This avoids shipping a
terminal app today with accidental sandbox restrictions.

## Verification

```sh
plutil -lint Sources/GridOSApp/GridOSApp.entitlements Sources/GridOSApp/PrivacyInfo.xcprivacy
scripts/app-store-preflight.sh
xcodegen generate --use-cache
rg -n "PrivacyInfo.xcprivacy" gridOS.xcodeproj/project.pbxproj
! rg -n "CODE_SIGN_ENTITLEMENTS: Sources/GridOSApp/GridOSApp.entitlements" project.yml
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
```

Initial gates passed on 2026-06-02. The 2026-06-03 amendment is verified in the
product-shipping pass.

## Remaining blockers

- Build and smoke a signed sandboxed app, not only an unsigned test build.
- Decide whether App Store gridOS supports only sandbox-local terminal workspaces or adds user-selected project-folder access with security-scoped bookmarks.
- Create App Store Connect metadata, support URL, privacy policy URL, screenshots, and review notes.
- Phase 12 clean-Mac Finder/Gatekeeper and update-flow proof remain open for the direct Beta channel.
