# gridOS App Store Readiness

Status: paused
Last updated: 2026-06-03

This document tracks the Mac App Store path separately from the direct
Developer ID Beta path. The direct path can stay useful for power users, but
Mac App Store submission has stricter sandbox, metadata, privacy, and update
rules. As of the 2026-06-03 product-shipping pass, App Store assets are staged
but not active on the default direct Beta target. The direct Developer ID build
must remain unsandboxed until a dedicated App Store build configuration is
created and smoke-tested.

## Current App Store Posture

- App category: `public.app-category.developer-tools`
- Bundle ID: `com.aaldere1.gridos`
- App Sandbox entitlement file: staged in `Sources/GridOSApp/GridOSApp.entitlements`
- Default direct Beta target: unsandboxed
- Network client entitlement: staged for explicit Command Intelligence provider requests
- Temporary exception entitlements: none
- Privacy manifest: `Sources/GridOSApp/PrivacyInfo.xcprivacy`
- Tracking: false
- Collected data types: none declared for the app bundle
- Required reason APIs declared:
  - `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`
  - `NSPrivacyAccessedAPICategoryDiskSpace` with reason `E174.1`

## App Store Review Risks

| Risk | Status | Mitigation |
| --- | --- | --- |
| App Sandbox runtime behavior | open | Create a dedicated App Store build configuration, then build and smoke a sandbox-signed app proving shell launch, pane cleanup, Command Intelligence no-key state, and Settings stability. |
| Terminal value inside sandbox | open | Either add user-selected workspace access with matching entitlement usage, or position App Store gridOS as a sandboxed command workspace. |
| User-selected file access | not enabled | Do not declare file access entitlements until the app has a matching picker, security-scoped bookmark flow, and tests. |
| Metadata and review notes | open | App Store Connect record must include accurate privacy policy URL, support URL, screenshots, AI disclosure, and detailed review notes. |
| AI provider metadata | open | Avoid provider-brand keyword stuffing in App Store metadata. If distributing in China, remove restricted AI-provider terms or exclude China. |
| Updates | open | Mac App Store builds must update through the Mac App Store only. Direct Beta update docs do not apply to this channel. |

## Reviewer Notes Draft

gridOS is a native macOS developer tool that provides a local terminal workspace,
local system metrics, optional visual modes, and opt-in Command Intelligence.
Terminal sessions, workspace state, recent directories, metrics, and diagnostics
stay local by default. Command Intelligence sends only the approved preview
payload after the user explicitly requests a provider response. API keys are
stored in Keychain. Risky generated commands are inserted for review instead of
run automatically.

The app does not include telemetry, tracking, advertising, analytics SDKs,
automatic diagnostics upload, in-app purchases, account creation, or a custom
update mechanism for the App Store channel.

## Validation Commands

```sh
scripts/app-store-preflight.sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
```

## Remaining Release Work

1. Create the App Store Connect app record and pull metadata into a reviewable
   repo-local snapshot or checklist.
2. Add final support and privacy policy URLs.
3. Produce App Store screenshots from the production UI, not Beta docs.
4. Add a dedicated App Store build configuration that applies
   `Sources/GridOSApp/GridOSApp.entitlements` without changing the direct Beta
   target.
5. Build and smoke a signed sandboxed app archive.
6. Decide whether App Store gridOS supports only sandbox-local workspaces or
   adds user-selected project-folder access before submission.
