---
phase: 08
slug: macos-integrations
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-21
---

# Phase 08 - Validation Strategy

Per-phase validation contract for macOS integrations. The phase is allowed to use source-visible smoke fixtures where live OS UI automation is unreliable, but private terminal data must never be used as evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | XCTest through Xcode |
| Config file | `project.yml` |
| Quick run command | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:IntegrationsTests -only-testing:GridOSKitTests -only-testing:CommandIntelligenceTests/CommandCredentialStoreTests` |
| Full suite command | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` |
| Estimated runtime | 90-180 seconds |

## Sampling Rate

- After every task commit: run the narrowest XCTest target or exact source gate named in the plan.
- After every plan wave: run the full suite command.
- Before `$gsd-verify-work`: run the full suite command and all Phase 8 source gates.
- Max feedback latency: one task.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | Menu/status/preference model foundation | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:IntegrationsTests -only-testing:GridOSKitTests/GridOSAppPreferencesTests` | W0 creates | pending |
| 08-01-02 | 01 | 1 | Reusable Keychain-backed secrets | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:GridOSKitTests/KeychainCredentialStoreTests -only-testing:CommandIntelligenceTests/CommandCredentialStoreTests` | W0 creates | pending |
| 08-02-01 | 02 | 2 | Menu bar extra | source/build | `rg 'MenuBarExtra|showMenuBarExtra|Open gridOS|Host Status|Recent Directories' Sources/GridOSApp Sources/Integrations` | W0 creates | pending |
| 08-02-02 | 02 | 2 | Settings controls | source/build | `rg 'macOS Integrations|Show Menu Bar Extra|Manage Stored Secrets|Index saved workspace metadata' Sources/GridOSApp Sources/GridOSKit` | W0 creates | pending |
| 08-03-01 | 03 | 3 | Local notification client | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:IntegrationsTests/LocalNotificationClientTests` | W0 creates | pending |
| 08-03-02 | 03 | 3 | Notification settings and smoke | source/build/smoke | `rg 'Enable Notifications|gridOS work finished|phase8-notification-smoke|PHASE8_NOTIFICATION_SMOKE' Sources/GridOSApp Sources/Integrations docs .planning` | W0 creates | pending |
| 08-04-01 | 04 | 4 | Metadata-only indexing foundation | unit/source | `rg 'CSSearchableItem|WorkspaceSearchMetadata|Index saved workspace metadata|Terminal output and command history are never indexed' Sources Tests docs .planning` | W0 creates | pending |
| 08-04-02 | 04 | 4 | Final evidence and privacy gates | full gate | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` | W0 creates | pending |

## Wave 0 Requirements

- `Sources/Integrations/Info.plist` - new framework target metadata.
- `Sources/Integrations/MacIntegrationModels.swift` - pure model and preference-facing types.
- `Tests/IntegrationsTests/MacIntegrationModelsTests.swift` - new test target proof that the model layer exists before UI wiring.
- `Tests/GridOSKitTests/KeychainCredentialStoreTests.swift` - reusable Keychain query construction coverage.

## Required Source Gates

Run these before final verification:

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
rg 'MenuBarExtra|showMenuBarExtra|Open gridOS|Host Status|Recent Directories' Sources Tests docs .planning
rg 'UNUserNotificationCenter|UNNotificationRequest|NotificationAuthorizationState|Enable Notifications|gridOS work finished' Sources Tests docs .planning
rg 'Keychain|kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly|Manage Stored Secrets' Sources Tests docs .planning
rg 'CSSearchableItem|WorkspaceSearchMetadata|Index saved workspace metadata|Terminal output and command history are never indexed' Sources Tests docs .planning
! rg 'shellHistory|commandOutput|terminalTranscript|environmentVariables|apiKey.*AppStorage|UserDefaults.*api|import SwiftTerm' Sources/GridOSApp Sources/GridOSKit Sources/CommandIntelligence Sources/TerminalCore Sources/SystemMetrics Sources/Integrations
```

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Menu bar extra is visible and compact | Menu bar extra | macOS menu-bar UI is not reliably exposed to XCTest | Launch Debug app, confirm the `gridOS` menu bar extra appears when `integrations.showMenuBarExtra` is true, open it, and verify `Open gridOS`, `Host Status`, `Recent Directories`, `Settings`, and `Quit gridOS` are present. |
| `Open gridOS` restores the app without shell text | Menu bar extra | Requires live AppKit activation behavior | Put terminal focus in gridOS, choose `Open gridOS` from menu bar, and confirm no text is inserted or executed. |
| Notification permission prompt is explicit | Notifications | macOS system permission dialog is user-controlled | Open Settings, use `Enable Notifications`, and confirm no notification prompt appears before this explicit action. |
| Default notification content is sanitized | Notifications | Live notification rendering is OS-controlled | Trigger `--phase8-notification-smoke` and verify title/body are `gridOS work finished` and `A long-running task completed in your workspace.` with no command text/output/full paths. |
| Spotlight indexing is opt-in and metadata-only | Optional indexing | Spotlight database behavior is OS-controlled | Leave `Index saved workspace metadata` off by default, then enable it and verify indexed records contain only saved workspace labels and directory basenames. |

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Wave 0 covers all missing test/source files.
- [x] No watch-mode flags.
- [x] Feedback latency is one task or less.
- [x] `nyquist_compliant: true` set in frontmatter.

Approval: approved 2026-05-21 for Phase 08 planning.
