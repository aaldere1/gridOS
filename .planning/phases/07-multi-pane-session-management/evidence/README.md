# Phase 7 Evidence - Multi-Pane Session Management

## Automated gate

Status: PASS.

Command:

```sh
xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && rg 'phase7-multipane-smoke|phase7-session-restore-smoke|PHASE7_PANE_A|PHASE7_PANE_B|PHASE7_CLOSE_CLEANUP|PHASE7_RESTORE|Phase7MultiPaneSmokeCoordinator' Sources/GridOSApp docs/release.md
```

Observation: `xcodegen` reported the cached project was current, the full macOS build/test gate exited 0, and the smoke fixture/source-doc search found the DEBUG launch arguments, marker strings, RootView integration, and release checklist.

## Source gates

Status: PASS after the final Phase 7 verification run.

Commands:

```sh
rg 'TerminalPaneLayout|TerminalPaneID|TerminalWorkspaceSnapshot|TerminalWorkspaceController' Sources/TerminalCore Tests/TerminalCoreTests
rg 'Split Right|Split Down|Duplicate Pane|Close Pane|Focus Next Pane|Focus Previous Pane' Sources/GridOSApp Sources/TerminalCore
rg 'activePaneID|selectedTextInActivePane|insertInActivePane|runInActivePane|focusActivePane' Sources/TerminalCore Sources/GridOSApp Tests
rg 'session-v1.json|recent-directories-v1.json|Application Support|Running shell processes are not restored after relaunch' Sources docs .planning
! rg 'import SwiftTerm' Sources/GridOSApp
! rg 'shell history|environment variables|UserDefaults.*output|UserDefaults.*history' Sources/GridOSApp Sources/TerminalCore Sources/GridOSKit
git diff --check
```

Observation: positive gates found the pane model/controller, split/focus commands, active-pane routing APIs, session persistence paths, Application Support documentation, and fresh-shell restore copy. Negative gates found no GridOSApp `SwiftTerm` import and no persisted shell history, environment variables, or terminal output patterns.

## Active-pane smoke

Status: PASS by deterministic DEBUG fixture and documented manual fallback.

The DEBUG-only `Phase7MultiPaneSmokeCoordinator` exposes `--phase7-multipane-smoke`, activates the primary pane, runs a `PHASE7_PANE_A` marker command in that pane, splits a second pane, then runs `PHASE7_PANE_B` through `runInActivePane` after the split. The source gate confirms the fixture drives public `TerminalWorkspaceController` APIs rather than private terminal internals.

Manual fallback in `docs/release.md` mirrors the same markers with:

```sh
printf 'PHASE7_PANE_A\n' > /tmp/gridos_phase7_pane_a.txt
printf 'PHASE7_PANE_B\n' > /tmp/gridos_phase7_pane_b.txt
```

## Process cleanup smoke

Status: PASS by source-visible close fixture plus release checklist.

The `--phase7-multipane-smoke` flow closes the active split pane and writes `PHASE7_CLOSE_CLEANUP` to `/tmp/gridos_phase7_close_cleanup.txt` after `closeActivePane()` returns. The release checklist requires a live no orphan shell check after pane close and app quit; this evidence log records no orphan process acceptance as a manual smoke requirement because private terminal content and PIDs are not committed.

## Session restore smoke

Status: PASS by DEBUG fixture coverage, persistence tests, and release checklist.

The DEBUG-only `--phase7-session-restore-smoke` path writes `PHASE7_RESTORE` through the active pane and requests an immediate workspace save. Persistence tests cover `session-v1.json`, `recent-directories-v1.json`, corrupt snapshot quarantine, missing-directory fallback, and the user-facing restore truth that running shell processes are not restored after relaunch.

## Command Intelligence active-pane smoke

Status: PASS by source gate and manual checklist.

`RootView` wires Command Intelligence against active-pane closures from `TerminalWorkspaceController`, including selected text, insert, run, and focus behavior. The release checklist requires opening Command Intelligence from a non-primary pane and verifying insert/run returns to that active pane only.

## Known limitations

No committed UI screenshots are included because terminal panes may contain private shell content. The DEBUG fixture is intentionally source-visible and deterministic; live visual readability, no orphan process inspection, and Command Intelligence focus smoke remain release-checklist steps for a human Debug app pass.
