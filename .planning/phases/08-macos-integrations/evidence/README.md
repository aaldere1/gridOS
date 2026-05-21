# Phase 8 Evidence - macOS Integrations

## Phase 8 final gate

Status: PASS.

Last full gate: 2026-05-21T02:03Z.

Commands:

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

Observation: `xcodegen` reported the cached project was current, the full macOS build/test gate exited 0, `git diff --check` exited 0, all positive source gates found their Phase 8 surfaces, and the forbidden source gate exited 0.

The final forbidden source gate initially exposed a validation mismatch because `TerminalCore` legitimately owns SwiftTerm. `TerminalSurface.swift` now imports specific SwiftTerm types instead of a broad module import, preserving the adapter boundary while making the source gate precise.

## Menu bar smoke

Status: PASS by source gate and release checklist coverage.

The source gate found `MenuBarExtra`, `showMenuBarExtra`, `Open gridOS`, `Host Status`, and `Recent Directories` in app source, tests, docs, and planning artifacts. The menu bar extra remains a companion to the normal `WindowGroup`, and menu actions are limited to app activation, Settings activation, Finder directory opening, and quit.

Manual release checklist coverage lives in `docs/release.md` and requires confirming the `gridOS` menu bar extra appears when `Show Menu Bar Extra` is on, opening the menu, checking the expected labels, and verifying `Open gridOS` does not type or run terminal text.

## Notification smoke

Status: PASS with local permission-dependent result.

Command used:

```sh
rm -f /tmp/gridos_phase8_notification_smoke.txt
APP_BIN=$(ls -dt ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app/Contents/MacOS/gridOS 2>/dev/null | head -1)
"$APP_BIN" --phase8-notification-smoke
cat /tmp/gridos_phase8_notification_smoke.txt
```

Observed marker:

```text
PHASE8_NOTIFICATION_SMOKE
gridOS work finished
A long-running task completed in your workspace.
Integration unavailable. Check macOS permissions and try again.
NO_GRIDOS_PROCESS_AFTER_PHASE8_SMOKE
```

The macOS notification center returned the product-level unavailable/permission message in this environment. The smoke fixture still proved the app starts the notification path, uses sanitized title/body copy, writes a deterministic marker, and leaves no `gridOS` process after the smoke launch is killed.

## Keychain privacy proof

Status: PASS.

The Keychain source gate found shared `GridOSKit` generic-password primitives, `kSecClassGenericPassword`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, and the `Manage Stored Secrets` Settings route. The final forbidden source gate found no API-key AppStorage/UserDefaults pattern in the app, kit, command intelligence, terminal, metrics, or integrations source trees.

## Metadata indexing proof

Status: PASS.

`WorkspaceMetadataIndexerTests` passed in the targeted gate and in the full scheme gate. Coverage proves `WorkspaceSearchMetadata` strips full paths to directory basenames, blank values fall back to `Workspace` and `Home`, `CSSearchableItem` uses the exact domain `com.aaldere1.gridos.workspace-metadata`, and the indexer can delete that domain.

The Core Spotlight source gate found `CSSearchableItem`, `WorkspaceSearchMetadata`, the Settings toggle `Index saved workspace metadata`, and the privacy copy `Terminal output and command history are never indexed`. The narrower forbidden metadata gate also passed for the indexer source and tests.

## Manual checkpoints

- Menu bar visual smoke remains a release-candidate manual checkpoint because macOS menu-bar UI is not reliably exposed to unit tests.
- Notification permission prompt behavior remains a manual checkpoint for a signed/interactive Debug or release app; the automated smoke records the local permission-dependent result.
- Metadata indexing remains opt-in and should be enabled only during a manual privacy check that confirms indexed records contain workspace labels and directory basenames only.
- No screenshots were committed because terminal panes may contain private shell content.

## Known limitations

- Quick Look and Finder preview work is deferred until gridOS has a stable saved workspace document type.
- Phase 8 does not create a background-only helper, updater, login item, or document extension.
- Spotlight database behavior is OS-controlled, so Phase 8 verifies source-level metadata construction and unit-level item mapping rather than inspecting private system indexes.
