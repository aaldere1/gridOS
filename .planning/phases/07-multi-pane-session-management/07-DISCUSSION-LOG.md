# Phase 07: Multi-pane and session management - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-20T20:15:20Z
**Phase:** 07-multi-pane-session-management
**Areas discussed:** Pane model and layout, Pane commands and focus, Session restoration and recent directories, Process cleanup and safety, App-frame integration, Verification direction

---

## Workflow Note

The project is configured for GSD YOLO mode: `workflow.skip_discuss=true` and `workflow.auto_advance=true`. Following that preference, no interactive questions were asked. Recommended defaults were selected from the roadmap, production roadmap, prior phase contracts, and current codebase shape. The user can edit `07-CONTEXT.md` before planning if any default should change.

`gsd-tools init phase-op 7` reported `phase_found: false`, but `.planning/ROADMAP.md` contains `Phase 7 - Multi-pane and session management`. This log and the context file use the roadmap as source of truth, matching the Phase 6 parser workaround.

## Discuss Scope

| Option | Description | Selected |
| --- | --- | --- |
| All core areas | Covers pane layout, active-pane routing, session restore, recent directories, process cleanup, and verification. | yes |
| Layout only | Focuses on splits/drag/resize while using roadmap defaults for cleanup and restore. | no |
| Safety and restore first | Focuses on process cleanup and persistence while leaving pane UX mostly to implementation. | no |

**Selected default:** All core areas.
**Notes:** Phase 7 crosses terminal lifecycle, app commands, persistence, Command Intelligence, and process cleanup; planning needs all major decisions up front.

## Pane Model and Layout

| Option | Description | Selected |
| --- | --- | --- |
| In-window split panes | Add split panes inside the existing gridOS window and keep the app frame terminal-first. | yes |
| Full tabs/windows overhaul | Build a larger session/window manager around multiple windows and tabs. | no |
| External multiplexer model | Lean on tmux-style semantics and make gridOS mainly a wrapper. | no |

**Captured decision:** Start with in-window split panes backed by a pane tree or grid model. Each pane owns its own terminal session and lifecycle.
**Notes:** This delivers the roadmap's practical developer workflow without over-expanding the phase into a product rewrite.

## Pane Commands and Focus

| Option | Description | Selected |
| --- | --- | --- |
| Native commands target active pane | Add menu/keyboard actions for split, focus, resize, close, duplicate, and route existing terminal commands to the active pane. | yes |
| Global terminal commands broadcast | Keep current notification behavior and let all panes respond or let the last attached terminal win. | no |
| Mouse-first pane controls | Prioritize visible pane controls and leave keyboard routing light. | no |

**Captured decision:** All terminal/app commands and Command Intelligence actions target the active pane only.
**Notes:** The current `TerminalCommandCenter` notification bridge and single `TerminalInteractionController` must be revised so multi-pane behavior is deterministic.

## Session Restoration and Recent Directories

| Option | Description | Selected |
| --- | --- | --- |
| Restore layout and fresh shells | Restore layout, active pane, shell/profile settings, and last known directories; launch fresh shell processes. | yes |
| Restore live running processes | Attempt to resurrect process state across relaunch. | no |
| No session restore | Only support split panes during the current app run. | no |

**Captured decision:** Restore session metadata and fresh shells only. Running shell processes are not restored.
**Notes:** This carries forward Phase 3 recovery honesty while satisfying the Phase 7 session model acceptance criterion.

## Process Cleanup and Safety

| Option | Description | Selected |
| --- | --- | --- |
| Explicit cleanup with close safeguards | Pane close/app quit terminates child shells cleanly; active work gets a conservative prompt where feasible. | yes |
| Silent pane termination | Close panes immediately without warning or process-state consideration. | no |
| Leave cleanup to OS/app exit | Rely on app teardown and avoid explicit lifecycle evidence. | no |

**Captured decision:** Process cleanup is a first-class Phase 7 deliverable. Verification must prove no orphaned shell processes after pane close and app quit.
**Notes:** The current `TerminalSurface.dismantleNSView` and `Coordinator.shutdown()` termination path is the starting point, but multi-pane needs stronger evidence.

## App-Frame Integration

| Option | Description | Selected |
| --- | --- | --- |
| TerminalCore owns session primitives | Build pane/session/process abstractions in `TerminalCore`; `GridOSApp` composes UI and theme. | yes |
| App owns session state directly | Keep all pane/session logic in `RootView` and SwiftUI state. | no |
| New cross-feature session module now | Introduce a separate workspace module before `TerminalCore` proves the model. | no |

**Captured decision:** `TerminalCore` should own the terminal session primitives. `GridOSApp` should stay a composer and must not import SwiftTerm.
**Notes:** This preserves the dependency direction documented in `docs/architecture.md`.

## Verification Direction

| Option | Description | Selected |
| --- | --- | --- |
| Model tests plus live smoke | Add deterministic pane/session tests and a live smoke covering multiple panes, active-pane routing, restore, and cleanup. | yes |
| Unit tests only | Test layout/persistence models but skip live terminal lifecycle proof. | no |
| Manual verification only | Rely on screenshots/manual behavior checks for pane UX. | no |

**Captured decision:** Use model tests and live smoke. Process cleanup and active-pane targeting must be proven, not just visually inspected.
**Notes:** Existing release-smoke style in `docs/release.md` should be extended for Phase 7 once implementation details are known.

## the agent's Discretion

- Exact pane model type names and persistence encoding.
- Exact shortcut assignments, as long as they avoid terminal workflow conflicts.
- Exact visual active-pane indicator and resize handle styling.
- Exact staging of drag panes, duplicate pane, session profiles, optional launcher, and recent commands.

## Deferred Ideas

- Full tab/window overhaul.
- Live process resurrection.
- tmux-compatible deep session restore.
- Cross-device session sync.
- Remote SSH workspace management.
- Public workspace/plugin APIs.
- Process management actions from metrics/activity panels.
