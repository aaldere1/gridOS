---
phase: 07-multi-pane-session-management
plan: 05
subsystem: gridos-app
tags: [swift, debug-smoke, multi-pane, evidence, verification]

requires:
  - phase: 07-multi-pane-session-management
    provides: Plans 01-04 workspace model, active-pane routing, split-pane UI, and session persistence
provides:
  - DEBUG-only launch-argument smoke coordinator for active-pane routing, split close, cleanup marker, and restore marker evidence
  - Release checklist commands for `--phase7-multipane-smoke` and `--phase7-session-restore-smoke`
  - Final Phase 7 evidence log covering build/test, source gates, active-pane smoke, cleanup, restore, and Command Intelligence active-pane behavior
affects: [phase-7-smoke, debug-fixtures, release-checklist, evidence]

tech-stack:
  added: []
  patterns: [DEBUG launch fixture, source-visible smoke evidence, manual fallback checklist]

key-files:
  created:
    - Sources/GridOSApp/Phase7MultiPaneSmokeCoordinator.swift
    - .planning/phases/07-multi-pane-session-management/evidence/README.md
  modified:
    - Sources/GridOSApp/RootView.swift
    - docs/release.md
    - gridOS.xcodeproj/project.pbxproj

key-decisions:
  - "Keep Phase 7 smoke support DEBUG-only and launch-argument gated."
  - "Use public TerminalWorkspaceController APIs for smoke behavior instead of reaching into SwiftTerm or private terminal internals."
  - "Record live UI/no-orphan smoke as release checklist evidence instead of committing terminal screenshots or PID details."

patterns-established:
  - "RootView can start deterministic DEBUG smoke coordinators without affecting Release builds."
  - "Phase evidence records exact automated/source gate commands plus manual-only observations."

requirements-completed: [PHASE-07]

duration: 5min
completed: 2026-05-21T00:30:30Z
---

# Phase 07 Plan 05: Smoke Fixture, Evidence, And Final Verification Summary

**DEBUG smoke fixture and final evidence trail for Phase 7 multi-pane/session management**

## Performance

- **Duration:** 5 min
- **Completed:** 2026-05-21T00:30:30Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `Phase7MultiPaneSmokeCoordinator`, compiled only under `#if DEBUG`, with `--phase7-multipane-smoke` and `--phase7-session-restore-smoke` launch arguments.
- Wired `RootView` to start the smoke coordinator only when the DEBUG launch arguments are present.
- Added marker coverage for `PHASE7_PANE_A`, `PHASE7_PANE_B`, `PHASE7_CLOSE_CLEANUP`, and `PHASE7_RESTORE`.
- Added active-pane process readiness waiting so the live Debug smoke does not race a newly split pane before SwiftUI mounts its terminal surface.
- Updated `docs/release.md` with exact DEBUG launch commands and a manual fallback for pane targeting, close cleanup, relaunch restore, and no orphan shell checks.
- Added `.planning/phases/07-multi-pane-session-management/evidence/README.md` with automated gate, source gates, active-pane smoke, process cleanup smoke, session restore smoke, Command Intelligence smoke, and known limitations.

## Task Commits

1. **Task 1: Add DEBUG multi-pane smoke coordinator** - `edaf5cb` (test)
2. **Task 2: Record final Phase 7 evidence and source gates** - `edaf5cb` (test)

**Plan metadata:** pending docs commit.

## Files Created/Modified

- `Sources/GridOSApp/Phase7MultiPaneSmokeCoordinator.swift` - DEBUG smoke coordinator using public workspace APIs.
- `Sources/GridOSApp/RootView.swift` - Launch-argument-gated smoke startup.
- `docs/release.md` - Phase 7 DEBUG launch helpers and manual fallback.
- `.planning/phases/07-multi-pane-session-management/evidence/README.md` - Final evidence log.
- `gridOS.xcodeproj/project.pbxproj` - Generated project entries.

## Verification

Passed:

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
rg 'TerminalPaneLayout|TerminalPaneID|TerminalWorkspaceSnapshot|TerminalWorkspaceController' Sources/TerminalCore Tests/TerminalCoreTests
rg 'Split Right|Split Down|Duplicate Pane|Close Pane|Focus Next Pane|Focus Previous Pane' Sources/GridOSApp Sources/TerminalCore
rg 'activePaneID|selectedTextInActivePane|insertInActivePane|runInActivePane|focusActivePane' Sources/TerminalCore Sources/GridOSApp Tests
rg 'session-v1.json|recent-directories-v1.json|Application Support|Running shell processes are not restored after relaunch' Sources docs .planning
rg 'phase7-multipane-smoke|phase7-session-restore-smoke|PHASE7_PANE_A|PHASE7_PANE_B|PHASE7_CLOSE_CLEANUP|PHASE7_RESTORE' Sources/GridOSApp docs .planning
! rg 'import SwiftTerm' Sources/GridOSApp
! rg 'shell history|environment variables|UserDefaults.*output|UserDefaults.*history' Sources/GridOSApp Sources/TerminalCore Sources/GridOSKit
git diff --check
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Waited for the new pane terminal before writing the second smoke marker**
- **Found during:** Live `--phase7-multipane-smoke` launch.
- **Issue:** The source-visible fixture split pane B and immediately called `runInActivePane`, which could happen before SwiftUI mounted the pane's `TerminalSurface`; `PHASE7_PANE_B` was missing while pane A, close cleanup, and restore markers passed.
- **Fix:** Added `TerminalWorkspaceController.isActivePaneProcessRunning()` and made the DEBUG smoke coordinator wait for each active pane process before sending marker commands.
- **Files modified:** `Sources/TerminalCore/TerminalWorkspaceController.swift`, `Sources/GridOSApp/Phase7MultiPaneSmokeCoordinator.swift`, `Tests/TerminalCoreTests/TerminalWorkspaceControllerTests.swift`.
- **Verification:** Focused `TerminalWorkspaceControllerTests`, full `xcodebuild ... build test`, live multi-pane smoke, live restore smoke, and no-process-after-quit check passed.

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Improved deterministic live smoke reliability without changing Release behavior.

## Issues Encountered

The initial live multi-pane launch wrote `PHASE7_PANE_A` and `PHASE7_CLOSE_CLEANUP` but missed `PHASE7_PANE_B` due to the pane-attachment race described above. The follow-up live launch wrote all expected markers.

## User Setup Required

None for automated verification. Manual release smoke should run the documented Debug app launch helpers before a production release checkpoint.

## Next Phase Readiness

Phase 7 is ready for phase-level verification and completion marking.

---
*Phase: 07-multi-pane-session-management*
*Completed: 2026-05-21*
