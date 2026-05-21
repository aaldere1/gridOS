# Phase 08: macOS Integrations - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 8 makes gridOS feel like a first-class Mac app by adding native integration surfaces around the terminal workspace: a menu bar extra, local Notification Center alerts, reusable Keychain-backed secret storage, and optional Spotlight/preview foundations only if they can be implemented without exposing private terminal data. This phase should deepen Mac-native ergonomics, not become release signing, updater, public plugin architecture, telemetry, or full workflow automation.

The app remains a terminal-first cockpit. Integrations should help users return to work faster, notice useful events, and manage local secrets safely without turning gridOS into a background agent that watches everything.

</domain>

<decisions>
## Implementation Decisions

### Menu Bar Extra
- **D-01:** Add a native macOS menu bar extra as a lightweight companion to the main window, not a replacement UI. It should expose quick open/show gridOS, compact host health, current shell/workspace status, and recent workspace/directory actions where the existing data model supports them.
- **D-02:** The menu bar extra should be discoverable and useful by default, but user-controllable through Settings. A persisted `Show Menu Bar Extra` toggle is in scope; exact default may be decided during planning, with a bias toward enabled for early alpha unless implementation reveals launch/menu clutter issues.
- **D-03:** Menu bar actions must preserve the Phase 3/7 focus policy: when they bring gridOS forward, focus should return to the active pane. They should not create surprise panes, run shell text, or steal focus from an active terminal session unless the user chose that action.
- **D-04:** Recent sessions should start from Phase 7's real persistence model. If named sessions are not yet available, use honest labels such as current workspace, restored layout, and recent directories. Do not invent a full workspace library in Phase 8.

### Notifications
- **D-05:** Add Notification Center support as an opt-in/local-only integration. The app should not request notification permission at first launch; request it from Settings or the first explicit notification workflow.
- **D-06:** Target useful terminal-adjacent notifications: completed long-running app-initiated commands where command boundaries are reliable, session/process lifecycle events where they are explicit, and future manual reminders. Notification content should be privacy-preserving by default: no full command text, shell output, environment, secrets, or full paths unless the user explicitly enables richer local copy.
- **D-07:** Do not add invasive shell hooks just to detect every arbitrary command completion. Research may investigate safe, transparent shell integration, but if reliable command-boundary detection requires hidden shell instrumentation, Phase 8 should ship the notification permission/service foundation and a narrower deterministic smoke path instead.
- **D-08:** Notifications must never affect terminal availability. Failures to authorize or deliver notifications should degrade to calm in-app status copy and tests, not shell errors.

### Keychain-Backed Secrets
- **D-09:** Reuse and generalize the existing `KeychainCommandCredentialStore` pattern into a small, testable credential boundary. The implementation may stay in `CommandIntelligence` for API keys or move shared pieces to `GridOSKit`/a new integrations module if planning needs broader reuse.
- **D-10:** Phase 8 can improve provider key management and prepare optional SSH-related secret storage, but it must not silently import, scan, or manage SSH keys. SSH/keychain work should be explicit, user-triggered, and conservative.
- **D-11:** Secrets stay out of `AppStorage`, `UserDefaults`, logs, snapshots, notifications, Spotlight, and menu bar display. Tests should prove secret values do not appear in source-controlled evidence or persisted app preference paths.

### Spotlight And Preview Foundations
- **D-12:** Treat Spotlight indexing and Quick Look/session previews as optional Phase 8 work, not mandatory exit blockers. Only implement them if the data model is ready and privacy boundaries are clear.
- **D-13:** If indexing ships, index only low-sensitivity metadata such as user-named saved sessions, sanitized labels, and optionally directory basenames. Do not index command output, shell history, prompts, generated commands, secrets, environment variables, full terminal transcript, or process arguments.
- **D-14:** If previews ship, they should be sanitized summaries of saved workspace layout/profile metadata, not rendered terminal contents. No screenshot/terminal-output previews should be generated unless a future privacy review explicitly approves it.

### Module And App Integration
- **D-15:** Prefer a new `Integrations` module if Phase 8 introduces reusable notification/menu-bar/indexing clients. `GridOSApp` should compose native surfaces; it should not become the owner of Notification Center, Spotlight, or secret-storage internals.
- **D-16:** Preserve established module boundaries: `TerminalCore` owns terminal/process/pane behavior, `SystemMetrics` owns host metrics, `CommandIntelligence` owns provider flows, `RenderCore` owns visual identity, and the app shell coordinates them through small APIs.
- **D-17:** Settings can gain a compact `macOS Integrations` section for menu bar, notification permission/status, and privacy copy. Keep it utilitarian; do not add an onboarding wizard or marketing page.

### Verification Direction
- **D-18:** Add unit tests around integration state models, menu bar action models, notification authorization/result mapping, and Keychain query construction. Use injectable clients for Notification Center/Spotlight/Keychain rather than calling live OS services directly in unit tests.
- **D-19:** Add DEBUG smoke support for Phase 8 that can verify menu bar/source presence, notification service behavior without private content, and no terminal/process regressions. If UI automation cannot inspect the real menu bar extra reliably, record source-visible fixture evidence and manual release smoke steps.
- **D-20:** Preserve all Phase 1-7 gates: terminal launch/input, active-pane routing, workspace restore, process cleanup, Command Intelligence safety, metrics locality, visual readability, no `SwiftTerm` import in `GridOSApp`, and privacy negative checks.

### the agent's Discretion
- Exact menu bar icon treatment, menu item order, compact metric labels, and Settings layout are left to planning/implementation, constrained by native macOS expectations and the current visual modes.
- Exact notification threshold for "long-running" is left to research/planning, constrained by non-invasive detection and user control.
- Exact target location for shared Keychain wrappers is left to research/planning, constrained by testability and minimal coupling.
- Whether Spotlight/preview foundations are implemented or explicitly deferred is left to planning after research validates data readiness and privacy cost.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap And Product Scope
- `.planning/ROADMAP.md` — Phase 8 goal and exit criteria.
- `docs/production-roadmap.md` — macOS integrations section, production-ready definition, privacy constraints, and architecture target naming an `Integrations` module.
- `.planning/PROJECT.md` — Product promise, non-negotiables, current module list, and release readiness constraints.
- `.planning/STATE.md` — Latest completed Phase 7 state and carried-forward decisions.
- `docs/vision.md` — Product vision for a serious Mac-first terminal cockpit.

### Prior Phase Contracts
- `.planning/phases/03-production-app-frame/03-CONTEXT.md` — Terminal-first frame, native window behavior, keyboard/focus policy, Settings, recovery honesty, and accessibility baseline.
- `.planning/phases/04-real-system-metrics/04-CONTEXT.md` — Local-only truthful metrics, no-root sampling, privacy posture, and read-only top-process display.
- `.planning/phases/05-aesthetic-modes/05-CONTEXT.md` — Visual mode boundaries, terminal readability, reduced motion, and screenshot evidence expectations.
- `.planning/phases/06-llm-command-palette/06-CONTEXT.md` — Opt-in LLM provider setup, Keychain API keys, redaction, failure copy, and no auto-execute policy.
- `.planning/phases/07-multi-pane-session-management/07-CONTEXT.md` — Active-pane routing, workspace restore, recent directories, process cleanup, and no shell history/output persistence.
- `.planning/phases/07-multi-pane-session-management/07-VERIFICATION.md` — Verified active-pane, restore, and no-process-after-quit evidence that Phase 8 must preserve.

### Code And Architecture
- `docs/architecture.md` — Current module boundaries and Phase 1-7 architecture targets; Phase 8 should add integrations through module-owned APIs.
- `docs/release.md` — Existing smoke patterns and source gates that Phase 8 must extend without regressing.
- `project.yml` — XcodeGen source of truth for adding an `Integrations` target or new app capabilities.
- `Sources/GridOSApp/GridOSApp.swift` — Current SwiftUI `App`, scenes, settings scene, and native command menus.
- `Sources/GridOSApp/RootView.swift` — Main app composition, active-pane focus restoration, metrics loop, workspace persistence, and Command Intelligence service composition.
- `Sources/GridOSApp/SettingsView.swift` — Existing Settings sections and persisted preference style.
- `Sources/CommandIntelligence/KeychainCommandCredentialStore.swift` — Existing testable Keychain client/query pattern for provider API keys.
- `Sources/SystemMetrics/SystemMetricsSampler.swift` — Existing sampler abstraction that can feed compact menu bar metrics.
- `Sources/SystemMetrics/SystemMetricsSnapshot.swift` — Current host metric value model for menu bar status.
- `Sources/TerminalCore/TerminalWorkspaceController.swift` — Active-pane and process lifecycle boundary that menu bar/window actions must respect.
- `Sources/TerminalCore/TerminalWorkspacePersistence.swift` — App Support workspace/recent-directory store that can power recent workspace/menu bar entries.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GridOSApp.swift`: already owns app scenes, Settings scene, and native command menus; it is the natural place to compose a `MenuBarExtra` once integration models exist.
- `RootView`: already has the active workspace controller, system metrics snapshot, settings routing, and active-pane focus helpers that menu bar actions must preserve.
- `SettingsView`: already uses compact grouped Settings sections and `@AppStorage`; Phase 8 can add a small integrations section without changing the app's first screen.
- `KeychainCommandCredentialStore`: already provides injectable SecItem clients and testable query values; this is the strongest pattern for reusable credential storage.
- `SystemMetricsSnapshot` and `SystemMetricsSampler`: provide compact CPU/MEM/NET/BAT/THERM data for menu bar status without adding new sampling sources.
- `TerminalWorkspaceSnapshotStore`: stores layout and recent directories locally; this is the current source for recent workspace/directory menu items.

### Established Patterns
- XcodeGen is authoritative. Any new target, entitlement, capability, or source group must start in `project.yml` and regenerate `gridOS.xcodeproj`.
- Module boundaries are strict. App code composes; feature modules own their internals.
- Privacy defaults are conservative: no telemetry, no shell history persistence, no command output persistence, no secrets outside Keychain, no LLM context without explicit user action.
- Terminal focus is protected. App-level surfaces must return focus to the active pane after dismissal or window activation unless the user intentionally moves focus elsewhere.
- Smoke evidence matters. Prior phases added deterministic DEBUG launch helpers instead of relying only on manual claims.

### Integration Points
- Add an `Integrations` module if implementation introduces notification/menu bar/indexing service abstractions shared beyond `GridOSApp`.
- Extend `GridOSAppPreferences` with local toggles for menu bar extra visibility, notification preference/status, and optional indexing/preview flags if those ship.
- Wire menu bar actions to existing app/window activation and active-pane focus behavior rather than duplicating terminal control paths.
- Feed menu bar metrics from `SystemMetricsSnapshot`; do not create a second metrics sampler unless research proves the menu bar needs independent cadence/backpressure.
- Wrap Notification Center with an injectable client/protocol so tests can verify authorization/result mapping without live OS prompts.
- Keep Spotlight/preview work behind explicit models and privacy checks; do not index or preview live terminal content.

</code_context>

<specifics>
## Specific Ideas

- The menu bar extra should feel like a quiet Mac-native command post: open gridOS, glance at compact host health, resume the current workspace, and jump into recent directories.
- Notifications should be useful but restrained. "A command finished" is valuable; a notification containing the full command/output is too much for the default privacy posture.
- Phase 8 should make gridOS feel more like a real Mac citizen while staying boringly reliable underneath. No background shell watcher magic.
- Spotlight and previews are tempting, but they should wait unless the implementation can prove metadata-only indexing with clear user control.

</specifics>

<deferred>
## Deferred Ideas

- Public plugin architecture, signed plugin packages, manifests, permissions, and crash isolation remain deferred until the plugin phase/post-stability work.
- Direct distribution, Developer ID signing, notarization, updater, checksums, and Gatekeeper clean-Mac proof remain later release phases.
- Full command history/search, terminal transcript previews, and command-output indexing are deferred until a dedicated privacy review and data model exist.
- Deep SSH key management or automatic import from `~/.ssh` is deferred; Phase 8 may only prepare explicit, user-triggered secret storage foundations.
- Widgets, Quick Look terminal-content previews, Touch Bar, Continuity, Universal Control awareness, and Stage Manager-specific behavior are deferred unless research finds a tiny, safe win.

</deferred>

---

*Phase: 08-macos-integrations*
*Context gathered: 2026-05-20*
