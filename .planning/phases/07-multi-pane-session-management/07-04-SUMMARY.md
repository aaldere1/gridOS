---
phase: 07-multi-pane-session-management
plan: 04
subsystem: terminal-core
tags: [swift, persistence, app-support, session-restore, recovery-copy]

requires:
  - phase: 07-multi-pane-session-management
    provides: Plans 01-03 workspace model, active-pane router, split-pane UI, and focused commands
provides:
  - Application Support JSON persistence for workspace snapshots and recent directories
  - RootView restore and debounced save wiring for pane layout, active pane, and directories
  - Settings recovery copy and reset saved session action
  - Architecture and release smoke documentation for Phase 7
affects: [session-restore, recent-directories, settings-recovery, phase-7-smoke, process-cleanup]

tech-stack:
  added: []
  patterns: [Atomic JSON store, corrupt snapshot quarantine, debounced workspace save, honest fresh-shell restore]

key-files:
  created:
    - Sources/TerminalCore/TerminalWorkspacePersistence.swift
    - Tests/TerminalCoreTests/TerminalWorkspacePersistenceTests.swift
  modified:
    - Sources/GridOSApp/RootView.swift
    - Sources/GridOSApp/SettingsView.swift
    - Sources/GridOSApp/TerminalWorkspaceView.swift
    - docs/architecture.md
    - docs/release.md
    - gridOS.xcodeproj/project.pbxproj

key-decisions:
  - "Persist workspace snapshots and recent directories under Application Support/gridOS using session-v1.json and recent-directories-v1.json."
  - "Treat corrupt session JSON as recoverable by moving it to session-v1.corrupt.json and starting from a default workspace."
  - "Reset Saved Session deletes persisted JSON files but does not disturb currently running panes."

patterns-established:
  - "RootView initializes TerminalWorkspaceController from TerminalWorkspaceSnapshotStore when possible."
  - "Workspace saves are debounced by 0.5 seconds after layout, focus, resize, and working-directory changes."
  - "Settings copy distinguishes restored layout/directories from non-restored running shell processes."

requirements-completed: [PHASE-07]

duration: 7min
completed: 2026-05-21T00:25:41Z
---

# Phase 07 Plan 04: Session Restore, Recent Directories, And Recovery Copy Summary

**Local Application Support workspace restore with atomic JSON snapshots, recent directories, recovery copy, and no live-process resurrection**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-21T00:19:14Z
- **Completed:** 2026-05-21T00:25:41Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `TerminalWorkspaceSnapshotStore` with `session-v1.json`, `recent-directories-v1.json`, atomic writes, missing-file fallbacks, corrupt-file quarantine, and delete support.
- Added persistence tests for snapshot round trip, missing snapshot, recent directories, delete, corrupt JSON, and forbidden persisted private keys.
- Wired `RootView` to load persisted snapshots on startup, save snapshots/recent directories after workspace changes, and preserve fresh-shell restore semantics.
- Updated Settings recovery copy with the exact restore/process/directory messages and added `Reset Saved Session`.
- Documented the Phase 7 architecture target and multi-pane/session smoke path.

## Task Commits

1. **Task 1: Add local workspace snapshot persistence** - `f477fbc` (feat)
2. **Task 2: Wire restore, recent directories, Settings copy, and docs** - `f477fbc` (feat)

**Plan metadata:** pending docs commit.

## Files Created/Modified

- `Sources/TerminalCore/TerminalWorkspacePersistence.swift` - App-support JSON snapshot and recent-directory store.
- `Tests/TerminalCoreTests/TerminalWorkspacePersistenceTests.swift` - Persistence and privacy regression tests.
- `Sources/GridOSApp/RootView.swift` - Load/save/restore wiring and debounced persistence scheduling.
- `Sources/GridOSApp/SettingsView.swift` - Recovery copy and reset saved session action.
- `Sources/GridOSApp/TerminalWorkspaceView.swift` - Save callback hooks after workspace mutations.
- `docs/architecture.md` - Phase 7 architecture target.
- `docs/release.md` - Phase 7 multi-pane/session smoke checklist.
- `gridOS.xcodeproj/project.pbxproj` - Generated project entries.

## Decisions Made

- Store only serializable workspace data: pane layout, descriptors, active pane, shell/profile metadata, and recent directories.
- Restore shells fresh from saved descriptors and directory validity checks; do not reuse live process state.
- Save recent directories as stored newest-first order instead of re-normalizing them as chronological input on read.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved recent-directory order on load**
- **Found during:** Task 07-04-01 (Add local workspace snapshot persistence)
- **Issue:** The first persistence implementation reused the model normalization helper on saved recent directories, reversing an already newest-first list during load.
- **Fix:** Added store-local normalization that trims, dedupes, caps at ten, and preserves stored order.
- **Files modified:** `Sources/TerminalCore/TerminalWorkspacePersistence.swift`
- **Verification:** `TerminalWorkspacePersistenceTests` and full `xcodebuild ... build test` passed.
- **Committed in:** `f477fbc`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Corrected restore behavior for recent-directory UX. No privacy or scope expansion.

## Issues Encountered

None beyond the recent-directory ordering bug captured above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 5 can now use the real split UI and persistence layer for smoke evidence: split panes, active-pane targeting, close cleanup, relaunch restore, and no orphan shell processes.

---
*Phase: 07-multi-pane-session-management*
*Completed: 2026-05-21*
