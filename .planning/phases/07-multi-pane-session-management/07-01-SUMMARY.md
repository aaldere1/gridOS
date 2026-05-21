---
phase: 07-multi-pane-session-management
plan: 01
subsystem: terminal-core
tags: [swift, xctest, terminalcore, workspace-model, session-restore]

requires:
  - phase: 06-llm-command-palette
    provides: Active terminal interaction boundaries and command intelligence routing assumptions
provides:
  - Pure Codable pane identity, layout, descriptor, snapshot, and workspace state model
  - Deterministic split, close, duplicate, focus, working-directory, snapshot, and recent-directory behavior
  - XCTest coverage for the model foundation used by later multi-pane UI and persistence work
affects: [07-multi-pane-session-management, terminal-routing, session-persistence, workspace-ui]

tech-stack:
  added: []
  patterns: [Pure TerminalCore model, Codable snapshot boundary, no process resurrection state]

key-files:
  created:
    - Sources/TerminalCore/TerminalWorkspaceModel.swift
    - Tests/TerminalCoreTests/TerminalWorkspaceModelTests.swift
  modified:
    - Sources/TerminalCore/TerminalSessionConfiguration.swift
    - gridOS.xcodeproj/project.pbxproj

key-decisions:
  - "Represent pane identity as a string-backed TerminalPaneID so UI, routing, and persistence share one stable key."
  - "Persist layout and pane descriptors only; running process identifiers are deliberately excluded from snapshots."
  - "Make TerminalSessionConfiguration Codable so pane descriptors can persist full startup configuration."

patterns-established:
  - "TerminalPaneLayout is a pure recursive split tree with visual-order traversal and local replacement/removal helpers."
  - "Recent directories are normalized, deduped newest-first, and capped at ten entries at the model boundary."
  - "Restored panes validate last known directories before reuse and fall back to the default configuration when missing."

requirements-completed: [PHASE-07]

duration: 4min
completed: 2026-05-21T00:07:09Z
---

# Phase 07 Plan 01: TerminalCore Pane And Session Model Foundation Summary

**Codable TerminalCore workspace state with split layout, pane descriptors, active-pane focus, safe restore semantics, and recent-directory normalization**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-21T00:03:06Z
- **Completed:** 2026-05-21T00:07:09Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Added `TerminalWorkspaceModel.swift` with `TerminalPaneID`, `TerminalSplitAxis`, `TerminalPaneLayout`, `TerminalPaneDescriptor`, `TerminalWorkspaceSnapshot`, and `TerminalWorkspaceState`.
- Covered split right/down, close, duplicate, focus next/previous, clamped split fractions, snapshot round-trip, restore fallback, and recent-directory behavior in XCTest.
- Generated the Xcode project so the new source and test files are part of the build.

## Task Commits

1. **Task 1: Add pure TerminalCore workspace model and tests** - `4fda95b` (feat)

**Plan metadata:** pending docs commit

## Files Created/Modified

- `Sources/TerminalCore/TerminalWorkspaceModel.swift` - Pure pane/session workspace model and snapshot restore logic.
- `Tests/TerminalCoreTests/TerminalWorkspaceModelTests.swift` - Regression coverage for layout, focus, restore, and recent-directory behavior.
- `Sources/TerminalCore/TerminalSessionConfiguration.swift` - Adds `Codable` conformance required by persisted pane descriptors.
- `gridOS.xcodeproj/project.pbxproj` - Generated project entries for the new model and test files.

## Decisions Made

- Keep the Phase 7 model completely independent of SwiftUI and SwiftTerm so routing, persistence, and tests can build on a stable core.
- Store only serializable pane/session metadata in snapshots; process IDs and live PTY state remain non-restorable by design.
- Activate newly split or duplicated panes immediately, matching common terminal split behavior and simplifying active-pane routing for Wave 2.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added Codable to TerminalSessionConfiguration**
- **Found during:** Task 07-01-01 (Add pure TerminalCore workspace model and tests)
- **Issue:** `TerminalPaneDescriptor` must be `Codable`, but it carries `TerminalSessionConfiguration`, which was not Codable yet.
- **Fix:** Added `Codable` conformance to `TerminalSessionConfiguration`.
- **Files modified:** `Sources/TerminalCore/TerminalSessionConfiguration.swift`
- **Verification:** Focused `TerminalWorkspaceModelTests` and full `xcodebuild ... build test` both passed.
- **Committed in:** `4fda95b`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Required for the planned snapshot model. No scope creep.

## Issues Encountered

- Swift rejected the snapshot initializer while it mixed fallback `self.init(...)` calls with direct stored-property assignment. Reworked fallback branches to assign through `self = Self(defaultConfiguration:)`; focused and full test gates passed afterward.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can now attach per-pane runtime controllers to stable `TerminalPaneID` values and route menu/Command Intelligence behavior to `TerminalWorkspaceState.activePaneID`.

---
*Phase: 07-multi-pane-session-management*
*Completed: 2026-05-21*
