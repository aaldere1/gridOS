---
phase: 08
slug: macos-integrations
status: complete
created: 2026-05-20
---

# Phase 08 - macOS Integrations Research

## Research Goal

Answer: what does the planner need to know to implement Phase 8 well?

Phase 8 should make gridOS feel Mac-native through menu bar, notification, Keychain, and optional metadata indexing/preview integrations while preserving the Phase 1-7 terminal/privacy contracts.

## Primary Sources

- Apple SwiftUI `MenuBarExtra` documentation: https://developer.apple.com/documentation/swiftui/menubarextra
- Apple SwiftUI `MenuBarExtraStyle` documentation: https://developer.apple.com/documentation/swiftui/menubarextrastyle
- Apple User Notifications documentation: https://developer.apple.com/documentation/UserNotifications
- Apple `UNNotificationRequest` documentation: https://developer.apple.com/documentation/UserNotifications/UNNotificationRequest
- Apple `UNUserNotificationCenter.requestAuthorization` documentation: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization%28options%3Acompletionhandler%3A%29
- Apple Core Spotlight `CSSearchableItem` documentation: https://developer.apple.com/documentation/corespotlight/cssearchableitem
- Apple Core Spotlight `CSSearchableItemAttributeSet` documentation: https://developer.apple.com/documentation/corespotlight/cssearchableitemattributeset
- Apple Quick Look Thumbnailing documentation: https://developer.apple.com/documentation/quicklookthumbnailing

## Relevant Apple API Findings

### Menu Bar Extra

SwiftUI `MenuBarExtra` is the right starting point on macOS. Apple describes it as a persistent system menu-bar control for commonly used functionality when the app is not active. The docs show a normal app can combine `WindowGroup` with `MenuBarExtra`, and an `isInserted` binding can drive visibility from a persisted user preference.

Planning implications:

- Use `MenuBarExtra("gridOS", systemImage: ..., isInserted: $showMenuBarExtra) { ... }`.
- Keep a normal `WindowGroup`; do not convert gridOS into a menu-bar-only `LSUIElement` utility app.
- Start with `.menuBarExtraStyle(.menu)` unless the planner needs richer status layout. `.window` is available for a popover-like extra, but it is more UI surface and should be justified by real content.
- The menu bar extra content should be mostly commands and compact status, not a dashboard.

### Notifications

`UNUserNotificationCenter` is the central notification object. Apple documents explicit authorization before scheduling local notifications, and `UNNotificationRequest` as the local request object containing notification content plus trigger conditions.

Planning implications:

- Add an injectable notification client instead of calling live `UNUserNotificationCenter` in unit tests.
- Request authorization only from explicit Settings/menu action.
- Model authorization states so UI can show not-determined, denied, authorized, provisional/ephemeral if surfaced by macOS, and delivery errors.
- Use local notifications only. Remote/APNs notifications are out of scope.
- Default notification content must be sanitized because command text/output can reveal secrets.

### Keychain

The existing `KeychainCommandCredentialStore` already has the useful pattern: injectable SecItem client, query values represented as equatable data, and `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

Planning implications:

- Avoid duplicating raw SecItem wrapper code.
- If shared across integrations, move generic Keychain primitives down to `GridOSKit` so both `CommandIntelligence` and future integration code can depend on them without feature-module cycles.
- Keep provider-specific stores in `CommandIntelligence` or add integration-specific stores only on top of generic primitives.
- Do not use Keychain work as permission to scan/import SSH secrets.

### Core Spotlight

Core Spotlight indexing is item/metadata based. `CSSearchableItem` uses a unique identifier, optional domain identifier, and `CSSearchableItemAttributeSet` metadata. Apple recommends title/display/content type style metadata and keeping indexes updated as app content changes.

Planning implications:

- Spotlight work is viable only for metadata the app owns.
- Phase 7 has session snapshots and recent directories, but no user-named session library or command-snippet data model. That means full indexing may be premature.
- If implemented, create a model such as `WorkspaceSearchMetadata` with sanitized title/display name/directory basename only.
- Indexing must be opt-in and easy to disable/delete.
- Do not index terminal transcript, command history, generated commands, prompts, output, secrets, environment variables, process args, or full paths by default.

### Quick Look / Thumbnailing

Quick Look Thumbnailing supports custom thumbnail generation with `QLThumbnailGenerator`/`QLThumbnailProvider` for custom file previews. gridOS does not yet have a document/file type representing saved workspace sessions.

Planning implications:

- Full Quick Look extension work is likely premature.
- A sanitized in-app preview model for saved workspace metadata can be a foundation, but a Finder/Quick Look extension should be deferred unless planning creates a real file/document type.

## Existing Code Constraints

### App Composition

`GridOSApp.swift` currently has:

- `WindowGroup { RootView() }`
- hidden titlebar window style
- native command menus
- Settings scene

It can host `MenuBarExtra` without disturbing the main window. App-level action closures should activate the app and return focus to the active pane through existing RootView/TerminalWorkspaceController wiring.

### Settings

`SettingsView` is a compact grouped `Form` with `@AppStorage` for persisted preferences. Phase 8 should add a `macOS Integrations` section there, not a new onboarding screen.

Recommended preference keys:

- `integrations.showMenuBarExtra`
- `integrations.notificationsEnabled`
- `integrations.indexWorkspaceMetadata`
- `integrations.includeFullPathsInLocalIntegrations` should **not** ship by default; avoid this unless a future privacy review approves it.

### Metrics

Menu bar status can reuse `SystemMetricsSnapshot`/`SystemMetricsSampler`. Avoid running an independent menu-bar sampler until planning proves it is needed. The safest initial approach is to keep menu bar metrics coarse and stale-aware, driven by app-level snapshots or a shared sampler policy.

### Workspace/Recent Directories

Phase 7 persistence gives:

- active workspace snapshot
- recent directories
- no shell history/output/env/process IDs

Menu bar recent entries should use these existing low-risk fields. "Recent sessions" should be honest if named sessions do not exist yet: current workspace and recent directories, not a full session library.

### Command Completion Notifications

The current terminal stack sees process lifecycle and output/input events, but it does not reliably know arbitrary shell command boundaries. Sending a newline to the terminal is not the same as knowing a shell command started/ended, especially with TUI programs, shell prompts, multiline commands, SSH, or tmux.

Recommended Phase 8 stance:

- Implement notification infrastructure and deterministic local smoke.
- Support app-initiated/known command flows if boundaries are reliable, such as commands run through gridOS-controlled `TerminalInteractionController.run` paths, but do not claim universal shell command completion unless research adds explicit, transparent shell integration.
- If planning investigates shell integration, it must be opt-in, documented, reversible, and tested against privacy/focus/process cleanup gates.

## Recommended Architecture

### Target Split

Add an `Integrations` target if Phase 8 introduces more than a tiny menu bar view:

```text
gridOS -> Integrations
Integrations -> GridOSKit
Integrations -> SystemMetrics? (only if metric models stay in SystemMetrics and app passes values)
CommandIntelligence -> GridOSKit
```

Avoid a feature-module cycle. Shared Keychain primitives should live in `GridOSKit` if `CommandIntelligence` needs to reuse them.

### Candidate Types

Suggested testable types:

- `MacIntegrationPreferences`
- `MenuBarStatusSnapshot`
- `MenuBarRecentDirectory`
- `MenuBarAction`
- `NotificationAuthorizationState`
- `NotificationDeliveryRequest`
- `NotificationDeliveryResult`
- `LocalNotificationClient`
- `WorkspaceSearchMetadata`
- `WorkspaceMetadataIndexer`
- `KeychainCredentialDescriptor`
- `KeychainCredentialStore`

### UI Surfaces

Menu bar extra:

- `Open gridOS`
- `Active workspace`
- `Host Status`: CPU, MEM, NET, BAT/THERM if available
- `Recent Directories`
- `Settings`
- `Quit gridOS`

Settings:

- `Show Menu Bar Extra`
- `Notify when long-running work finishes`
- `Enable Notifications`
- `Index saved workspace metadata`
- privacy copy from UI-SPEC
- `Manage Stored Secrets`

## Validation Architecture

### Automated Gates

Required final gate should extend current phase gates:

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

### Unit Test Targets

Likely test additions:

- `IntegrationsTests` if a new target is created.
- `GridOSKitTests` for shared preference/keychain descriptor models.
- Existing `CommandIntelligenceTests` if Keychain primitives move from `CommandIntelligence`.

### Smoke Evidence

Recommended evidence:

- Source-visible DEBUG notification fixture that writes a marker or uses a fake notification client rather than sending private content.
- Source-visible menu bar presence gate (`MenuBarExtra` plus copy strings).
- Optional manual smoke: launch Debug app, confirm menu bar item appears, use `Open gridOS`, enable notifications from Settings, send sanitized test notification, quit cleanly.
- No screenshots containing terminal content unless sanitized.

## Risks And Mitigations

| Risk | Mitigation |
|------|------------|
| Menu bar extra becomes a second dashboard | Keep menu style compact; use `.window` only if justified by content. |
| Notification permission prompt feels spammy | Ask only from Settings or explicit notification workflow. |
| Command completion detection becomes invasive | Limit to reliable app-initiated flows; defer hidden shell hooks. |
| Keychain wrapper duplication | Move generic primitives to `GridOSKit` before broad reuse. |
| Spotlight leaks private terminal data | Metadata-only opt-in; no transcripts/history/output/prompts/secrets. |
| Feature-module dependency cycle | Put shared types in `GridOSKit`; keep `Integrations` app-facing or model-only. |

## Planning Recommendation

Use four waves:

1. Integration models/preferences and reusable Keychain primitive cleanup.
2. Menu bar extra and Settings integration.
3. Local notification service, Settings status, and deterministic smoke.
4. Optional metadata indexing/preview foundation plus final evidence, or explicit deferral if research/planning finds data readiness insufficient.

The planner should keep Spotlight/preview optional. The must-have Phase 8 value is Mac-native ergonomics plus safe local integration foundations, not maximal OS surface area.
