---
phase: 08-macos-integrations
plan: 03
subsystem: notifications
tags: [usernotifications, swiftui, smoke, permissions]
requires:
  - phase: 08-macos-integrations
    provides: "Plan 01 Integrations models and Plan 02 Settings surface"
provides:
  - "Injectable LocalNotificationClient"
  - "Explicit Settings authorization flow"
  - "DEBUG Phase 8 notification smoke marker"
affects: [Integrations, GridOSApp, Settings, docs-release, Phase 08]
tech-stack:
  added: [UserNotifications]
  patterns: [fakeable OS client, explicit permission action, sanitized smoke marker]
key-files:
  created:
    - Sources/Integrations/LocalNotificationClient.swift
    - Tests/IntegrationsTests/LocalNotificationClientTests.swift
    - Sources/GridOSApp/Phase8MacIntegrationsSmokeCoordinator.swift
  modified:
    - Sources/GridOSApp/MacIntegrationsSettingsView.swift
    - Sources/GridOSApp/RootView.swift
    - docs/release.md
    - gridOS.xcodeproj/project.pbxproj
key-decisions:
  - "Notification status checks are allowed on Settings render, but the macOS authorization request only occurs from the Enable Notifications button."
  - "Default notification smoke content is fixed to `gridOS work finished` and `A long-running task completed in your workspace.`"
  - "macOS does not expose `UNAuthorizationStatus.ephemeral`, so the app model keeps the state but the macOS mapper does not reference the unavailable OS enum case."
patterns-established:
  - "UserNotifications access is wrapped behind `UserNotificationCenterClient` so unit tests never call the live notification center."
  - "DEBUG smoke fixtures write sanitized marker files instead of requiring screenshots or private terminal content."
requirements-completed: ["PHASE-08"]
duration: 5 min
completed: 2026-05-21
---

# Phase 08 Plan 03: Local Notifications and Deterministic Smoke Summary

**Injectable local notifications, explicit permission Settings flow, and sanitized DEBUG notification smoke**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-21T01:44:00Z
- **Completed:** 2026-05-21T01:49:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `LocalNotificationClient` with fakeable authorization and delivery methods.
- Added unit tests for authorization mapping, exact `[.alert, .sound]` request options, delivery success, delivery failure, and sanitized default content.
- Wired `Enable Notifications` in Settings to request authorization only when clicked.
- Added `--phase8-notification-smoke` DEBUG launch support that writes `/tmp/gridos_phase8_notification_smoke.txt`.
- Extended release docs with Phase 8 automated and manual notification smoke steps.

## Task Commits

1. **Task 08-03-01: Add injectable local notification client** - `9787b14` (feat)
2. **Task 08-03-02: Wire explicit notification settings and DEBUG smoke fixture** - `56d5731` (feat)

## Files Created/Modified

- `Sources/Integrations/LocalNotificationClient.swift` - UserNotifications adapter and local client.
- `Tests/IntegrationsTests/LocalNotificationClientTests.swift` - Fake-center unit tests.
- `Sources/GridOSApp/MacIntegrationsSettingsView.swift` - Explicit notification authorization UI.
- `Sources/GridOSApp/Phase8MacIntegrationsSmokeCoordinator.swift` - DEBUG smoke marker fixture.
- `Sources/GridOSApp/RootView.swift` - Starts the Phase 8 smoke coordinator only for the launch argument.
- `docs/release.md` - Adds Phase 8 smoke instructions.

## Decisions Made

- Checking authorization status on Settings load is acceptable because it does not prompt the user.
- Permission prompting is button-triggered only through `LocalNotificationClient.requestAuthorization()`.
- Notification delivery failures map to product copy: `Integration unavailable. Check macOS permissions and try again.`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Avoided unavailable macOS notification enum case**
- **Found during:** Task 08-03-01
- **Issue:** `UNAuthorizationStatus.ephemeral` is unavailable on macOS even though the app-level `NotificationAuthorizationState` includes `.ephemeral`.
- **Fix:** Kept the app model case for cross-platform completeness but removed direct macOS enum references from the live mapper/tests.
- **Files modified:** `Sources/Integrations/LocalNotificationClient.swift`, `Tests/IntegrationsTests/LocalNotificationClientTests.swift`
- **Verification:** `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:IntegrationsTests/LocalNotificationClientTests` passed.
- **Committed in:** `9787b14`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The app-level model still has the required state, and the macOS implementation no longer references an unavailable OS case.

## Issues Encountered

- Swift 6 concurrency required `@preconcurrency import UserNotifications` and an explicit `CheckedContinuation<Void, any Error>` for the notification add wrapper.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 04 can add metadata-only indexing and final evidence with menu bar, notification, and Keychain source gates already passing.

---
*Phase: 08-macos-integrations*
*Completed: 2026-05-21*
