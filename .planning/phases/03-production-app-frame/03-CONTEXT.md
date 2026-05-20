# Phase 3: Production app frame - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 turns the current terminal-plus-Metal prototype into a coherent Mac app shell. The phase covers polished window chrome, command menu and keyboard behavior, settings, profile persistence, a production-shaped layout frame, accessibility, reduced motion, and crash-safe state restoration.

This phase does not add real system metrics, multiple visual identities, LLM command help, public plugins, multi-pane sessions, production signing, notarization, or update infrastructure. Those remain in later roadmap phases.

</domain>

<decisions>
## Implementation Decisions

### Overall App Frame
- **D-01:** Use a terminal-first cockpit. The terminal remains the dominant working surface; secondary system/context panels may exist, but they must not compete with shell readability or keyboard focus.
- **D-02:** Treat the three-panel roadmap deliverable as a production frame around the terminal, not as a dashboard takeover. The system strip and activity/context panel should be restrained placeholders or lightweight shells until Phase 4 and later phases provide real content.

### Window Chrome
- **D-03:** Use a custom hidden-titlebar Mac window. Preserve native traffic lights and fullscreen behavior while giving gridOS an app-owned header/frame.
- **D-04:** Protect terminal focus during window chrome work. Header controls, panels, and overlays must not steal focus from the terminal after launch or after common commands unless the user explicitly interacts with them.

### Settings and Profile Persistence
- **D-05:** Replace placeholder settings with a real persisted terminal profile in Phase 3.
- **D-06:** Persist at least shell path, terminal font size, reduced motion, and visual intensity locally.
- **D-07:** Do not introduce a full named-profile management system yet. A single default profile and a profile model foundation are enough for this phase.

### Keyboard and Focus Policy
- **D-08:** The terminal owns shell-like shortcuts by default. App-level shortcuts must avoid fighting terminal input, tmux, vim, ssh, shells, and common command-line workflows.
- **D-09:** Keep app commands on explicit menu shortcuts such as command-key combinations. Avoid single-key global shortcuts and mode-heavy behavior in this phase.
- **D-10:** Preserve and harden existing terminal commands: copy, paste, clear, and reset.

### Recovery, Reduced Motion, and Accessibility
- **D-11:** Implement a practical production baseline: restore window size/position and persisted settings after relaunch.
- **D-12:** Make reduced motion meaningful by reducing or disabling Metal pulse animation intensity, not merely hiding a setting.
- **D-13:** Run an accessibility pass for labels, focus order, contrast, and basic keyboard navigation across the app frame and settings.
- **D-14:** Do not restore running shell processes after force quit. Restore app/window/profile state only; running process restoration is a future session-management problem.

### the agent's Discretion
- Exact visual spacing, panel proportions, and header composition are left to the implementation agent, constrained by the terminal-first cockpit decision.
- Exact persistence mechanism is left to planning/research, but should be simple and local for Phase 3.
- Exact accessibility implementation details are left to the implementation agent, as long as the baseline checks are verifiable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and State
- `.planning/ROADMAP.md` — Current GSD phase status and Phase 3 scope.
- `.planning/STATE.md` — Current progress, prior decisions, and Phase 3 next target.
- `.planning/PROJECT.md` — Product promise, non-negotiables, module boundaries, and validated implementation state.
- `docs/production-roadmap.md` — Full production roadmap and Phase 3 deliverables/acceptance criteria.

### Architecture and Release
- `docs/architecture.md` — Module dependency direction, app composition rule, TerminalCore and RenderCore boundaries.
- `docs/release.md` — Existing build, terminal smoke, and visual identity smoke expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Sources/GridOSApp/GridOSApp.swift`: Defines the SwiftUI app lifecycle, hidden titlebar window style, Settings scene, and current Terminal command menu.
- `Sources/GridOSApp/RootView.swift`: Current app frame with Metal background, terminal-first VStack, header labels, and terminal activity-to-render bridge.
- `Sources/GridOSApp/SettingsView.swift`: Placeholder settings UI for shell path and font size; Phase 3 should convert this into real persisted settings.
- `Sources/TerminalCore/TerminalSessionConfiguration.swift`: Existing shell/font/startup-command configuration model; useful starting point for persisted terminal profile state.
- `Sources/TerminalCore/TerminalCommandCenter.swift`: Current menu command notification bridge for terminal copy, paste, clear, and reset.
- `Sources/TerminalCore/TerminalSurface.swift`: Current SwiftTerm-backed terminal surface, focus handling, terminal command observers, and activity emission.
- `Sources/RenderCore/MetalBackgroundView.swift`: Burst-driven Metal background; reduced-motion handling can reduce or disable event animation here or at the app composition layer.

### Established Patterns
- `project.yml` is authoritative for Xcode project structure; regenerate `gridOS.xcodeproj` after target/test changes.
- Feature modules own focused APIs; `GridOSApp` composes them and should not absorb terminal/rendering internals.
- Terminal correctness has priority over visual effects and app chrome.
- Startup command support via `--cmd` is the current repeatable smoke-test hook.

### Integration Points
- App frame work connects primarily through `GridOSApplication`, `RootView`, and `SettingsView`.
- Persisted terminal settings should flow into `TerminalSessionConfiguration` rather than bypassing `TerminalCore`.
- Reduced motion and visual intensity should flow into `RenderCore` through a narrow app-owned configuration path.
- Keyboard command changes should be verified through the menu command surface and live terminal smoke checks.

</code_context>

<specifics>
## Specific Ideas

- The app should feel like a serious Mac terminal product first, with the sci-fi identity supporting the work instead of becoming a dashboard distraction.
- Phase 3 should make the app feel native in windowed mode, fullscreen, and multi-display use.
- Recovery should be honest: restore window/profile state, not pretend a killed shell process can be safely resurrected.

</specifics>

<deferred>
## Deferred Ideas

- Real CPU/memory/disk/network/battery/thermal metrics belong to Phase 4.
- Multiple polished aesthetic modes belong to Phase 5.
- LLM command palette and command safety flows belong to Phase 6.
- Split panes, session restoration of workflows, and richer session management belong to Phase 7.
- Production signing, notarization, packaging, and update flow belong to later release phases.

</deferred>

---

*Phase: 03-production-app-frame*
*Context gathered: 2026-05-20*
