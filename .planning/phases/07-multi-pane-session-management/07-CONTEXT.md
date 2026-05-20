# Phase 07: Multi-pane and session management - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 makes gridOS useful for real developer workflows beyond a single shell by adding multiple terminal panes, keyboard-accessible pane focus/resize/close/duplicate controls, recent directories, session profiles or saved session metadata, and reliable shell-process cleanup.

This phase should improve day-to-day terminal work inside one native gridOS window. It does not need to become a full tmux replacement, add remote SSH workspace management, sync sessions across devices, restore killed processes, add public plugin APIs, ship production signing, or solve later performance/security hardening work.

Note: `gsd-tools init phase-op 7` did not parse this repo's simple roadmap format even though `.planning/ROADMAP.md` contains Phase 7. The phase directory was created from the roadmap source of truth.

</domain>

<decisions>
## Implementation Decisions

### Pane Model and Layout
- **D-01:** Start with multi-pane support inside the existing primary gridOS window, not a separate tab/window overhaul. The current app frame stays terminal-first.
- **D-02:** Support practical split panes with horizontal and vertical splits. A simple pane tree or grid model is acceptable as long as it can represent nested splits, active pane identity, and readable proportions.
- **D-03:** Each pane owns its own terminal session, SwiftTerm surface, PTY process, interaction controller, activity stream, working directory, and lifecycle state. Do not share live process state between panes.
- **D-04:** The active pane must be visually indicated without obscuring terminal text. Focus changes should be obvious but restrained within the current aesthetic modes.
- **D-05:** Pane layout must remain readable on laptop and external display sizes. Avoid dense chrome that competes with the shell; resize handles and focus rings should support work, not become decoration.
- **D-06:** Dragging panes within a window is in roadmap scope, but planning may stage it after keyboard and menu operations if the underlying model needs to land first.

### Pane Commands and Focus
- **D-07:** Add native menu commands and keyboard-accessible actions for split right, split down, close pane, duplicate pane, focus next/previous pane, and resize active split.
- **D-08:** Preserve the Phase 3 keyboard policy: app-level shortcuts should use explicit command-key combinations and avoid fighting terminal, tmux, vim, ssh, and shell workflows.
- **D-09:** Existing Terminal menu actions (`Copy`, `Paste`, `Clear`, `Reset`) must target the active pane only.
- **D-10:** `Command-K` Command Intelligence must target the active pane only. Selected text, insert, run, focus restoration, and working-directory context should all come from the active pane.
- **D-11:** Closing overlays, palettes, settings routing, and app commands should return focus to the active pane rather than an arbitrary terminal view.

### Session Restoration and Recent Directories
- **D-12:** Session restoration means restoring layout, pane metadata, shell path, font/profile settings, working directories where known, and selected/active pane identity. Do not attempt to resurrect running shell processes after relaunch.
- **D-13:** On relaunch, restored panes should start fresh shells in their last known working directories when those directories still exist and are accessible. If not, fall back to the default working directory with clear, non-alarming copy.
- **D-14:** Recent directories are local-only app state, derived from explicit terminal working-directory updates and new-pane choices. Store directory paths conservatively; no shell history, command output, environment variables, or hidden file scans should be persisted for this phase.
- **D-15:** Session profiles should be a lightweight saved-session foundation, not a full workspace product. A default session and a small profile model are enough if planning needs to stage named profiles.
- **D-16:** Recent commands are listed in `docs/production-roadmap.md` deliverables, but privacy and terminal correctness dominate. If implemented, keep them opt-in, local, minimal, and never sourced from invasive shell instrumentation. It is acceptable to defer recent commands if reliable capture would require shell hooks beyond this phase.

### Process Cleanup and Safety
- **D-17:** Closing a pane must terminate that pane's child shell process cleanly and detach its terminal interaction surface. Window/app close must clean up every live pane process.
- **D-18:** If a pane appears to have active foreground work, the app should avoid silent destructive closure. Planning should include a practical close-confirmation or process-state affordance if SwiftTerm exposes enough information; otherwise use conservative confirmation for close-pane/app-quit with multiple live panes.
- **D-19:** Process cleanup evidence is mandatory: verification must prove shell processes are not leaked after pane close, layout close, and app quit.
- **D-20:** Session restore must be honest in Settings/Recovery copy: running shell processes are not restored after relaunch.

### App-Frame Integration
- **D-21:** Keep `TerminalCore` as the owner of pane/session/process abstractions. `GridOSApp` composes the multi-pane workspace but must not import SwiftTerm or directly manage PTY internals.
- **D-22:** Preserve `RenderCore`, `SystemMetrics`, and `CommandIntelligence` dependency boundaries. Multi-pane terminal activity can aggregate into the existing render event stream without coupling terminal sessions to rendering.
- **D-23:** Metrics remain host-level and read-only in Phase 7. Do not turn the activity panel into pane process control unless a narrow display-only active-pane label helps orientation.
- **D-24:** Settings can expose lightweight session/profile/recovery controls if needed, but the main screen should remain the usable terminal experience, not a setup wizard.

### Verification Direction
- **D-25:** Add deterministic model tests for pane tree/layout operations, active-pane routing, recent-directory normalization, session persistence, and process cleanup state transitions.
- **D-26:** Add integration or smoke verification that creates at least two panes, targets commands to the active pane, switches focus, closes panes, relaunches into restored layout/directories, and confirms no orphaned shell processes remain.
- **D-27:** Preserve existing Phase 1-6 gates: startup command smoke, terminal focus, visual-mode readability, metrics loop stability, and Command Intelligence active-pane behavior.

### the agent's Discretion
- Exact pane model type names, persistence format, menu labels, shortcut assignments, and resize interaction details are left to research/planning, constrained by keyboard accessibility and terminal workflow compatibility.
- Exact visual treatment for active-pane focus is left to implementation, constrained by terminal readability and current visual mode tokens.
- Exact staging of drag panes, duplicate pane, session profiles, and recent commands may be split across multiple Phase 7 plans if needed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap, Product, and State
- `.planning/ROADMAP.md` — Phase 7 goal and exit criteria.
- `docs/production-roadmap.md` — Phase 7 deliverables and acceptance criteria, including split panes, focus/resize/close/duplicate, drag, session profiles, recent directories/commands, optional launcher, process cleanup, and layout readability.
- `.planning/PROJECT.md` — Product promise, non-negotiables, module boundaries, and validated Phase 6 state.
- `.planning/STATE.md` — Current phase status, carried-forward decisions, and Phase 7 next target.
- `docs/vision.md` — Product vision for a serious Mac-first terminal cockpit.

### Prior Phase Contracts
- `.planning/phases/01-native-shell-mvp/01-01-SUMMARY.md` — Native shell MVP behavior, SwiftTerm dependency, startup command smoke, and process cleanup evidence.
- `.planning/phases/03-production-app-frame/03-CONTEXT.md` — Terminal-first cockpit, keyboard/focus policy, settings persistence, recovery honesty, and accessibility baseline.
- `.planning/phases/03-production-app-frame/03-VERIFICATION.md` — Evidence for app-frame focus, settings, window autosave, keyboard, and launch smoke behavior.
- `.planning/phases/04-real-system-metrics/04-CONTEXT.md` — Local-only metrics, read-only top-process posture, and terminal dominance.
- `.planning/phases/04-real-system-metrics/04-VERIFICATION.md` — Evidence that metrics remain local, read-only, and non-blocking.
- `.planning/phases/05-aesthetic-modes/05-CONTEXT.md` — Terminal protection, visual mode focus policy, mode-aware styling, and readability constraints.
- `.planning/phases/05-aesthetic-modes/05-VERIFICATION.md` — Evidence that visual-mode changes preserve terminal focus and readability.
- `.planning/phases/06-llm-command-palette/06-CONTEXT.md` — Command Intelligence active terminal interaction boundary, insert/run safety, focus return, and privacy policy.
- `.planning/phases/06-llm-command-palette/06-VERIFICATION.md` — Evidence that Command-K, active terminal insertion, and smoke fixture behavior work before multi-pane changes.

### Architecture and Code
- `docs/architecture.md` — Module dependency direction, `TerminalCore` boundary, SwiftTerm isolation, current `TerminalInteractionController`, and Phase 6 command-intelligence integration.
- `docs/release.md` — Existing build/test/smoke patterns and process-cleanup expectations.
- `project.yml` — Target membership, test targets, SwiftTerm dependency, and XcodeGen source of truth.
- `Sources/TerminalCore/TerminalSurface.swift` — Current SwiftTerm-backed terminal surface, process start/terminate path, focus restoration, activity emission, and command observers.
- `Sources/TerminalCore/TerminalSessionConfiguration.swift` — Current shell/font/startup-command working-directory configuration.
- `Sources/TerminalCore/TerminalSessionState.swift` — Current single-session lifecycle state.
- `Sources/TerminalCore/TerminalInteractionController.swift` — Current selected-text, insert, run, and focus boundary that should become active-pane aware.
- `Sources/TerminalCore/TerminalCommandCenter.swift` — Current app command notification bridge that must route to active pane only.
- `Sources/GridOSApp/RootView.swift` — Current single `TerminalWorkspaceView`, current working-directory state, render activity bridge, metrics panel, and Command Intelligence composition point.
- `Sources/GridOSApp/GridOSApp.swift` — Current Terminal, Command Intelligence, and Appearance command menus and shortcut registration.
- `Sources/GridOSApp/SettingsView.swift` — Existing Settings/Recovery copy and local persistence style.
- `Sources/GridOSKit/GridOSAppPreferences.swift` — Existing preference helper style for local persisted settings.
- `Tests/TerminalCoreTests/TerminalSessionConfigurationTests.swift` — Existing terminal configuration and lifecycle unit-test baseline.
- `Tests/TerminalCoreTests/TerminalInteractionControllerTests.swift` — Existing terminal interaction routing unit-test baseline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TerminalSessionConfiguration` already carries shell path, working directory, font name/size, and startup command; Phase 7 can build pane/session launch metadata on top of it.
- `TerminalSurface` already owns SwiftTerm setup, process launch, process termination, focus restoration, activity emission, and command observers. It is the critical process cleanup and resize/focus integration point.
- `TerminalInteractionController` is the existing app-facing selected-text/insert/run/focus API. It should become active-pane aware or be owned per pane behind a session workspace controller.
- `RootView` already tracks `currentWorkingDirectory` from terminal activity and uses it for Command Intelligence context. Phase 7 needs this state per pane.
- `GridOSAppPreferences` and `SettingsView` provide the local preference style for non-secret session settings.

### Established Patterns
- `GridOSApp` composes feature modules; feature internals stay behind module-owned APIs.
- `TerminalCore` can depend on `GridOSKit`; `GridOSApp` should not import SwiftTerm or manage terminal view internals directly.
- App-level commands use native command menus and explicit keyboard shortcuts.
- Terminal correctness and focus are higher priority than visual chrome, metrics, and LLM assistance.
- Recovery copy is honest: gridOS restores app/session state, not running shell processes.
- Verification uses repeatable unit gates plus app-launch smoke through Debug builds.

### Integration Points
- Add pane/session model types in `TerminalCore` first, likely around a pane identity, layout tree, session descriptor, active-pane routing, recent-directory store, and process cleanup state.
- Update `TerminalSurface` or add a host/controller wrapper so each pane has independent lifecycle and interaction routing.
- Replace single `TerminalWorkspaceView` composition in `RootView` with a multi-pane workspace that consumes `VisualTheme`, emits active-pane activity, and keeps layout stable.
- Extend `TerminalCommandCenter` and `TerminalInteractionController` so menu commands and Command Intelligence closures affect only the active pane.
- Persist session layout and recent directories through local app storage or app support data using testable pure models. Avoid storing secrets, output, environment data, or raw shell history.
- Add Phase 7 release evidence to `docs/release.md` once process cleanup and session restore smoke commands are known.

</code_context>

<specifics>
## Specific Ideas

- The product should feel like a native terminal workspace growing from one shell into a few reliable panes, not like a dashboard with terminals embedded as widgets.
- The first real workflow target is simple: split a shell, focus another pane, run different commands, close one pane, relaunch, and see the useful workspace shape return without leaked processes.
- Session restoration should feel trustworthy because it is honest about what can and cannot be restored.
- Recent directories should make new panes faster without feeling like surveillance of the user's shell.

</specifics>

<deferred>
## Deferred Ideas

- Full tabbed/window management can be a later enhancement if split panes solve the Phase 7 workflow.
- Restoring live running processes after relaunch is deferred; only layout, metadata, and fresh shells are restored.
- Deep tmux-style session resurrection, remote SSH workspace management, cross-device session sync, and public workspace/plugin APIs are deferred.
- Optional project/workspace launcher may be deferred if split panes, session restore, recent directories, and cleanup need the whole phase budget.
- Recent command capture should be deferred unless it can be implemented locally, opt-in, and without invasive shell hooks.
- Process management actions such as kill/restart/nice from the activity panel remain out of scope.

</deferred>

---

*Phase: 07-multi-pane-session-management*
*Context gathered: 2026-05-20*
