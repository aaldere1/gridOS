# Phase 04: Real system metrics - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 replaces Phase 3's decorative system/activity placeholders with truthful, useful local instrumentation. The phase covers a `SystemMetrics` sampler service, CPU, memory, disk, network, battery, thermal, and top-process data, a sampling budget/backpressure policy, graceful unavailable states, and app-frame integration.

This phase does not add command intelligence, process management actions, alerting, remote telemetry, historical analytics, user-configurable dashboards, menu bar metrics, or production performance hardening. Those remain later phases unless explicitly added to the roadmap.

</domain>

<decisions>
## Implementation Decisions

### Metric Truth and Scope
- **D-01:** Build a truthful baseline set: CPU, memory, disk, network, battery, thermal, and top processes. If a metric cannot be sampled accurately on the current Mac, show an unavailable state rather than an estimate dressed up as fact.
- **D-02:** Favor native/local macOS sampling APIs over shelling out to `top`, `ps`, or Activity Monitor-style command parsing as the primary app path. Research may identify narrow fallback commands, but they must be explicit, local, and testable.
- **D-03:** Top process display is read-only in this phase. Show useful identifiers such as process name and resource usage, but do not add kill, nice, inspect, or command intelligence actions.
- **D-04:** Do not require root permissions for normal metrics. Any metric requiring elevated privileges is out of scope for Phase 4 unless it can degrade cleanly.

### Sampling Budget and Backpressure
- **D-05:** Use a human-scannable refresh cadence rather than maximum freshness. CPU, network, memory, and top-process data can refresh around once per second; slower-changing battery, thermal, and disk-capacity data should refresh less often unless research proves otherwise.
- **D-06:** Sampling must stay idle-friendly. If the app is backgrounded, panels are not visible, or the system appears constrained, the sampler should reduce cadence or skip nonessential work.
- **D-07:** Metric snapshots should be timestamped and modelled as potentially stale. The UI should distinguish "current", "stale", and "unavailable" without alarming the user.
- **D-08:** Backpressure belongs in `SystemMetrics`, not in SwiftUI views. Views consume snapshots; they should not own polling policy.

### App-Frame Display
- **D-09:** Preserve the Phase 3 terminal-first cockpit. The terminal remains visually dominant; metrics support shell work instead of turning the app into a dashboard.
- **D-10:** Replace `SystemStripView` with compact at-a-glance host health: CPU, memory, network, battery/charging if available, and thermal state. Keep labels concise and truthful.
- **D-11:** Use `ActivityContextPanel` for the top-process list and unavailable explanations. Do not add fake activity, AI affordances, or predictive command context in this phase.
- **D-12:** First-pass visual treatment should be calm and text-forward. Micro charts are acceptable only if they are cheap, readable, and do not obscure terminal work.

### Privacy, Reliability, and User Messaging
- **D-13:** Keep all metrics local. Do not send metric snapshots to a network service, LLM provider, telemetry sink, or persistent log in Phase 4.
- **D-14:** Treat process details as potentially sensitive. Show process names and resource usage before showing full paths, arguments, environment, or command lines.
- **D-15:** Unavailable states should read as normal platform facts, not errors. Examples: "Battery unavailable" on desktops, "Thermal unavailable" when the API does not expose a state, and "Network idle" for zero throughput.

### Testing and Verification
- **D-16:** Add deterministic model/protocol tests for snapshot construction, formatting, unavailable/stale state handling, and sampling cadence policy.
- **D-17:** Preserve existing terminal launch/input smoke checks while adding a Phase 4 smoke that verifies metrics integration does not break shell startup or renderer idle behavior.

### the agent's Discretion
- Exact macOS API choices are left to research, constrained by truthfulness, no-root operation, local-only behavior, and testability.
- Exact metric formatting, compact labels, and panel spacing are left to planning/implementation, constrained by the terminal-first app frame.
- Exact refresh intervals may be adjusted after measuring local overhead, as long as the sampler remains idle-friendly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and State
- `.planning/ROADMAP.md` — Current GSD phase status and Phase 4 goal.
- `.planning/STATE.md` — Current progress, Phase 3 decisions, and Phase 4 next target.
- `.planning/PROJECT.md` — Product promise, non-negotiables, module boundaries, and validated implementation state.
- `docs/production-roadmap.md` — Full production roadmap and Phase 4 deliverables/acceptance criteria.

### Prior Phase Contracts
- `.planning/phases/03-production-app-frame/03-CONTEXT.md` — Terminal-first cockpit, placeholder panel intent, keyboard/focus policy, and reduced-motion/accessibility decisions.
- `.planning/phases/03-production-app-frame/03-VERIFICATION.md` — Evidence that Phase 3 app frame, settings, window autosave, and smoke checks passed.
- `docs/architecture.md` — Module dependency direction, app composition rule, and Phase 3 app-frame architecture.
- `docs/release.md` — Existing build, terminal smoke, visual identity smoke, and Phase 3 app-frame smoke expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Sources/SystemMetrics/SystemMetricsStatus.swift`: Current scaffold and correct module boundary for the sampler/service work.
- `Sources/GridOSApp/RootView.swift`: Contains `SystemStripView` and `ActivityContextPanel`, the Phase 3 placeholder surfaces that Phase 4 should replace or expand.
- `Sources/GridOSApp/RootView.swift`: Already composes `SystemMetrics` through the app target dependency; app views should consume module-owned snapshots rather than sampling directly.
- `Sources/GridOSKit/FoundationModuleStatus.swift`: Existing simple shared-model style for testable value types.
- `project.yml`: Already declares `SystemMetrics` as a framework dependency of the app target; add `SystemMetricsTests` here when tests are introduced.

### Established Patterns
- Feature modules own focused APIs; `GridOSApp` composes them.
- Terminal correctness has priority over app chrome, metrics, and visual effects.
- `project.yml` is authoritative for target/test membership; regenerate `gridOS.xcodeproj` after adding source or tests.
- Pure model behavior is tested in module-specific XCTest bundles.
- Repeatable app smoke uses the `--cmd` startup command path.

### Integration Points
- `SystemMetrics` should expose a narrow snapshot/sampler API consumed by `GridOSApp`.
- `RootView` is the current integration point for wiring metrics snapshots into the system strip and activity panel.
- `ActivityContextPanel` should become the top-process/unavailable-context surface while preserving the Phase 3 no-fake-content rule.
- `SystemStripView` should become compact host-health status while preserving terminal dominance.

</code_context>

<specifics>
## Specific Ideas

- Metrics should feel like instrumentation for a serious terminal cockpit, not decorative sci-fi gauges.
- Activity Monitor is the practical truthfulness reference: close enough for normal use, not necessarily byte-for-byte identical in every sample.
- The first version should prefer trustworthy labels and stable data over complex charts.

</specifics>

<deferred>
## Deferred Ideas

- User-configurable dashboards, rearrangeable panels, alert thresholds, and historical metric timelines are out of scope for Phase 4.
- Process management actions such as kill/restart/nice are out of scope.
- Sending metrics to LLM context or remote telemetry is out of scope.
- Menu bar metrics belong to a later macOS integrations phase.

</deferred>

---

*Phase: 04-real-system-metrics*
*Context gathered: 2026-05-20*
