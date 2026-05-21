---
phase: 07-multi-pane-session-management
plan: 02
subsystem: terminal-core
tags: [swift, xctest, terminalcore, active-pane-routing, process-lifecycle]

requires:
  - phase: 07-multi-pane-session-management
    provides: Plan 01 pane identity, layout, descriptor, snapshot, and workspace state model
provides:
  - Per-pane terminal interaction operations for copy, paste, clear, reset, terminate, running state, insert, run, focus, and selection
  - Pane-scoped TerminalSurface activity and lifecycle events
  - TerminalWorkspaceController active-pane router and cleanup coordination
affects: [workspace-ui, terminal-menu-commands, command-intelligence, process-cleanup, session-persistence]

tech-stack:
  added: []
  patterns: [Active-pane router, per-pane interaction controllers, pane-scoped activity callbacks]

key-files:
  created:
    - Sources/TerminalCore/TerminalWorkspaceController.swift
    - Tests/TerminalCoreTests/TerminalWorkspaceControllerTests.swift
  modified:
    - Sources/TerminalCore/TerminalInteractionController.swift
    - Sources/TerminalCore/TerminalSurface.swift
    - Sources/TerminalCore/TerminalCommandCenter.swift
    - Sources/GridOSApp/RootView.swift
    - Tests/TerminalCoreTests/TerminalInteractionControllerTests.swift
    - gridOS.xcodeproj/project.pbxproj

key-decisions:
  - "Use one TerminalInteractionController per TerminalPaneID and route app-facing terminal actions through TerminalWorkspaceController.activePaneID."
  - "Final pane close returns false and leaves the last pane alive instead of replacing it implicitly."
  - "Keep legacy TerminalCommandCenter notification names only as deprecated compatibility shims until Wave 3 installs focused command values."

patterns-established:
  - "TerminalSurface emits activity as (TerminalPaneID, TerminalActivityEvent) so downstream state updates know the source pane."
  - "TerminalWorkspaceController owns active-pane routing and calls terminate on the closing pane before removing it from state."
  - "TerminalSurface no longer registers NotificationCenter observers for terminal commands."

requirements-completed: [PHASE-07]

duration: 6min
completed: 2026-05-21T00:13:13Z
---

# Phase 07 Plan 02: Active-Pane Routing And Process Lifecycle Summary

**Per-pane TerminalCore interaction controllers with active-pane routing, pane-scoped activity, and deterministic pane cleanup**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-21T00:07:13Z
- **Completed:** 2026-05-21T00:13:13Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Extended `TerminalInteractionController` with copy, paste, clear, reset, terminate, and running-state methods behind the existing SwiftTerm-free test seam.
- Updated `TerminalSurface` to carry `TerminalPaneID`, emit pane-scoped activity, and remove global terminal command observers.
- Added `TerminalWorkspaceController` to route selection, insert, run, focus, copy, paste, clear, reset, terminate, split, duplicate, close, focus next/previous, activity, and snapshot behavior through the active pane.
- Added regression tests proving active-pane targeting, close-pane termination, terminate-all cleanup, working-directory activity routing, and focus behavior.

## Task Commits

1. **Task 1: Extend per-pane interaction controller and pane-scoped surface lifecycle** - `469c4b8` (feat)
2. **Task 2: Add active-pane TerminalWorkspaceController routing** - `469c4b8` (feat)

**Plan metadata:** pending docs commit.

## Files Created/Modified

- `Sources/TerminalCore/TerminalWorkspaceController.swift` - Active-pane router and process cleanup coordinator.
- `Tests/TerminalCoreTests/TerminalWorkspaceControllerTests.swift` - Routing, cleanup, working-directory, and focus regression tests.
- `Sources/TerminalCore/TerminalInteractionController.swift` - Per-pane operations beyond selection/insert/run/focus.
- `Sources/TerminalCore/TerminalSurface.swift` - Pane-scoped SwiftTerm surface lifecycle and activity callbacks.
- `Sources/TerminalCore/TerminalCommandCenter.swift` - Deprecated legacy notification command bridge ahead of focused command replacement.
- `Sources/GridOSApp/RootView.swift` - Compatibility update for the pane-scoped activity callback signature.
- `Tests/TerminalCoreTests/TerminalInteractionControllerTests.swift` - Coverage for new interaction methods.
- `gridOS.xcodeproj/project.pbxproj` - Generated project entries for the new router and tests.

## Decisions Made

- Final pane close returns `false` and keeps the last pane alive; this avoids silently replacing a live final shell.
- `terminateAllPanes()` terminates every registered controller; unregistered panes have no attached terminal process to terminate.
- Working-directory activity mutates only the source pane and recent-directory list; non-directory activity remains display/lifecycle metadata.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated RootView for pane-scoped activity callbacks**
- **Found during:** Task 07-02-01 (Extend per-pane interaction controller and pane-scoped surface lifecycle)
- **Issue:** Changing `TerminalSurface.ActivityHandler` from one argument to `(TerminalPaneID, TerminalActivityEvent)` required the current single-pane `RootView` callback to match the new signature or the app target would not compile.
- **Fix:** Updated `RootView.handleTerminalActivity` to accept and ignore the pane ID until Wave 3 replaces the single workspace composition.
- **Files modified:** `Sources/GridOSApp/RootView.swift`
- **Verification:** Focused routing tests and full `xcodebuild ... build test` passed.
- **Committed in:** `469c4b8`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Necessary compatibility fix for the planned TerminalSurface signature. No behavioral scope added.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 3 can now compose a multi-pane SwiftUI workspace using `TerminalWorkspaceController.controller(for:)`, `activatePane(_:)`, pane-scoped `TerminalSurface`, and focused command routing.

---
*Phase: 07-multi-pane-session-management*
*Completed: 2026-05-21*
