# Phase 09: Performance hardening - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 9 proves the native rewrite with measured performance evidence. The phase delivers a repeatable benchmark suite plus evidence for cold start, resident memory, idle CPU, terminal input latency, heavy terminal output, and Metal/frame pacing on target Apple Silicon hardware.

This phase does not add new product features, visual modes, terminal capabilities, plugin architecture, production signing, updater behavior, telemetry, or deep renderer rewrites unless measurement shows a clear release-blocking regression inside the existing architecture. Performance work must keep terminal correctness, privacy, and existing Phase 1-8 behavior intact.

</domain>

<decisions>
## Implementation Decisions

### Benchmark Strategy
- **D-01:** Phase 9 is measurement-first. Start by building repeatable local benchmarks and evidence capture before optimizing. Do not claim performance readiness from estimates, subjective feel, or one-off manual observation.
- **D-02:** Use the roadmap targets as the benchmark scorecard: resident RAM under 100 MB for a basic terminal plus one visual mode, cold start under 500 ms, idle CPU under 0.5% with quiet terminal/effects throttled, smooth sustained animation where supported, and terminal input latency close to Ghostty/iTerm-class behavior.
- **D-03:** Any missed target must produce a documented exception with owner, severity, likely cause, and mitigation plan. Do not hide misses by loosening thresholds in the same phase.
- **D-04:** Prefer Release or optimized local builds for performance numbers. Debug builds remain useful for deterministic smoke fixtures, markers, and instrumentation, but final benchmark evidence should clearly state build configuration, hardware, OS, and app mode.

### Measurement Harness And Evidence
- **D-05:** Add a repo-local benchmark harness under the Phase 9 planning/evidence area or a small checked-in script/tool path. It should be runnable from a clean checkout and produce machine-readable output plus a concise Markdown report.
- **D-06:** Keep performance evidence synthetic and privacy-safe. Heavy-output and input-latency tests should generate known marker text, not capture user shell history, real command output, environment variables, full paths, or screenshots containing private terminal contents.
- **D-07:** Commit summary reports and small sanitized evidence. Avoid committing large raw Instruments traces or private system dumps unless planning proves they are small, stable, and scrubbed; otherwise record the exact command and a summarized export.
- **D-08:** Every benchmark should include pass/fail status, observed value, target value, build/configuration, and enough command detail to rerun it.

### Cold Start And Memory
- **D-09:** Cold start should measure app launch to first usable terminal/readiness marker, not merely process spawn. Existing `--cmd` startup-command smoke can provide the terminal-ready marker if research/planning confirms it is reliable enough.
- **D-10:** Memory baseline should measure resident memory for the basic app with one terminal pane and a single visual mode after startup settles. If visual mode, metrics sampler, or menu bar extras materially change memory, capture those deltas explicitly rather than mixing them into one vague number.
- **D-11:** Use current app architecture as the baseline: SwiftUI app shell, SwiftTerm terminal adapter, RenderCore Metal background, SystemMetrics sampler, Command Intelligence dormant/no-key state, and Phase 8 integrations present but not actively doing work unless a benchmark intentionally enables them.

### Idle CPU And Frame Pacing
- **D-12:** Idle CPU should be measured after startup/render bursts settle with a quiet terminal. The evidence should prove `MetalBackgroundView` and `SystemMetricsSampler` are not continuously spinning beyond their intended cadence.
- **D-13:** Frame pacing should measure the existing Metal background/event-pulse path rather than requiring a new visual feature. If additional instrumentation is needed, make it DEBUG/benchmark-only and keep production behavior unchanged.
- **D-14:** Reduced motion and quiet-terminal cases must remain cheap. The benchmark should include at least one path where visual pulse animation is suppressed or naturally idle.

### Terminal Input And Heavy Output
- **D-15:** Input latency measurement should focus on the user's observable terminal path: typed/sent input reaches the PTY and visible/marker output returns. Planning may choose an accessibility, PTY marker, or controlled startup-command method, but it must be repeatable and not depend on private user content.
- **D-16:** Heavy output stress should use synthetic output large enough to expose UI stalls, output batching issues, runaway render pulses, or memory growth. It should preserve shell usability, active-pane routing, and process cleanup.
- **D-17:** Heavy-output benchmarks must account for Phase 7 multi-pane behavior. At minimum, they should prove one active pane handles stress without breaking focus/process cleanup; broader multi-pane stress is useful if it stays inside phase budget.

### Preservation Rules
- **D-18:** Do not regress Phase 1-8 guarantees: terminal launch/input, active-pane routing, process cleanup, workspace restore, local-only metrics, visual readability, Command Intelligence safety, Keychain privacy, and macOS integration privacy gates.
- **D-19:** Do not introduce background telemetry, persistent performance logs with private process details, shell hooks, or invasive command tracking to measure performance.
- **D-20:** Prefer targeted fixes over broad rewrites. If a target miss points to SwiftTerm, SwiftUI layout, Metal timing, or metrics sampling, isolate the change behind the owning module and add a regression test or benchmark gate.

### the agent's Discretion
- Exact benchmark tooling is left to research/planning. Acceptable directions include shell scripts, small Swift command-line helpers, `xcodebuild` actions, `xctrace`/Instruments CLI summaries, `ps`/`sample`/system APIs, or app-local DEBUG benchmark markers, constrained by repeatability and privacy.
- Exact warm-up duration, sample window, and statistical treatment are left to planning, but results should not depend on a single noisy instantaneous sample when a short sampling window is feasible.
- Exact evidence folder shape is left to planning, but Phase 9 must leave a durable report that later release phases can trust.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap And Targets
- `.planning/ROADMAP.md` — Phase 9 goal and exit criteria.
- `.planning/STATE.md` — Latest completed Phase 8 state, carried-forward decisions, and next target.
- `.planning/PROJECT.md` — Product promise, non-negotiables, validated implementation state, and module boundaries.
- `docs/production-roadmap.md` — Phase 9 deliverables, performance targets, and acceptance criteria.
- `docs/vision.md` — Product-level performance target table and native rewrite justification.
- `docs/release.md` — Existing Phase 1-8 smoke patterns and current notes that Phase 9 owns idle CPU/performance hardening.

### Prior Phase Contracts
- `.planning/phases/02-metal-identity-mvp/02-01-SUMMARY.md` — Initial Metal renderer, event bridge, and idle-conscious rendering baseline.
- `.planning/phases/03-production-app-frame/03-CONTEXT.md` — Terminal-first app frame, reduced-motion behavior, settings, and smoke expectations.
- `.planning/phases/04-real-system-metrics/04-CONTEXT.md` — Metrics sampling budget, local-only behavior, stale/unavailable states, and sampler ownership.
- `.planning/phases/05-aesthetic-modes/05-CONTEXT.md` — Visual mode motion profiles, terminal readability, reduced motion, and screenshot evidence direction.
- `.planning/phases/07-multi-pane-session-management/07-CONTEXT.md` — Active-pane routing, workspace persistence, process cleanup, and no shell history/output persistence.
- `.planning/phases/07-multi-pane-session-management/07-VERIFICATION.md` — Verified multi-pane smoke and no-process-after-quit evidence that Phase 9 must preserve.
- `.planning/phases/08-macos-integrations/08-CONTEXT.md` — Menu bar, notification, Keychain, Spotlight privacy, and integration boundaries.
- `.planning/phases/08-macos-integrations/08-VERIFICATION.md` — Final Phase 8 gates and privacy evidence that Phase 9 must preserve.

### Code And Architecture
- `docs/architecture.md` — Current module boundaries and architecture rule.
- `project.yml` — XcodeGen source of truth for any benchmark helper target or test target changes.
- `Sources/GridOSApp/RootView.swift` — App composition, metrics loop, render event bridge, workspace save loop, and Command Intelligence wiring.
- `Sources/RenderCore/MetalBackgroundView.swift` — MTKView setup, paused draw behavior, 30 Hz burst timer, pulse decay, and shader path.
- `Sources/RenderCore/VisualEffectConfiguration.swift` — Visual intensity and reduced-motion pulse suppression contract.
- `Sources/SystemMetrics/SystemMetricsSampler.swift` — Live sampler caching, cadence, stale snapshot behavior, and provider calls.
- `Sources/SystemMetrics/SystemMetricsSamplingPolicy.swift` — Fast, slow, and background cadence values.
- `Sources/TerminalCore/TerminalSurface.swift` — SwiftTerm adapter, PTY launch, terminal input/output activity emission, 30 Hz output activity batching, and process shutdown.
- `Sources/TerminalCore/TerminalWorkspaceController.swift` — Active-pane routing, close/terminate behavior, and process-running checks.
- `Sources/GridOSApp/Phase7MultiPaneSmokeCoordinator.swift` — Existing deterministic multi-pane/session smoke pattern.
- `Sources/GridOSApp/Phase8MacIntegrationsSmokeCoordinator.swift` — Existing deterministic sanitized app-start smoke marker pattern.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TerminalSessionConfiguration.fromProcessArguments()` and the `--cmd` startup path already provide deterministic terminal marker execution for launch and stress tests.
- `Phase7MultiPaneSmokeCoordinator` shows how to drive pane actions through public `TerminalWorkspaceController` APIs and write marker files without private terminal screenshots.
- `Phase8MacIntegrationsSmokeCoordinator` shows a command-line app-start smoke marker that can write sanitized evidence even when an OS callback is permission-dependent.
- `MetalBackgroundView` already uses `MTKView.isPaused = true`, `enableSetNeedsDisplay = true`, and a burst timer instead of continuous rendering; Phase 9 can measure and harden this path.
- `SystemMetricsSamplingPolicy` already expresses active/background cadence and stale thresholds; Phase 9 can add tests or benchmark evidence around actual overhead.
- `TerminalSurface` already batches output activity at roughly 30 Hz, which is relevant to heavy-output and render-pulse overhead.

### Established Patterns
- XcodeGen remains authoritative; add any helper target or benchmark test target through `project.yml`.
- Feature modules own behavior; performance fixes should land in `RenderCore`, `SystemMetrics`, `TerminalCore`, or `GridOSApp` according to ownership rather than in a monolithic app patch.
- Existing phase evidence favors deterministic marker files and source gates over screenshots or private data capture.
- Phase 4 and Phase 8 require local-only behavior and conservative privacy defaults; performance instrumentation must follow the same rule.
- Terminal correctness beats visual effects. Performance fixes cannot trade away shell input, PTY behavior, focus, or process cleanup.

### Integration Points
- A benchmark harness can launch the built app with controlled arguments, wait for marker files, sample process CPU/RSS, and write reports under `.planning/phases/09-performance-hardening/evidence/`.
- Render/frame instrumentation should connect to `RenderCore` without making `TerminalCore` depend on rendering.
- Input/heavy-output benchmarks should use `TerminalCore` and app launch smoke paths, not hidden shell hooks.
- Idle CPU and memory measurements should account for `RootView` metrics loop, `LiveSystemMetricsSampler`, and Metal burst animation lifecycle.
- Release docs should gain Phase 9 benchmark commands once the harness shape is known.

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 9 like a lab report: commands, hardware/configuration, measured values, pass/fail, and mitigation for misses.
- Benchmark the real product shape, not a stripped toy app, but keep optional features in known states so deltas are explainable.
- Use synthetic terminal content for stress. The evidence should be safe to commit and rerun.
- If the current targets are missed, that is useful information; record it honestly and either fix it or mark it as a release-blocking decision.

</specifics>

<deferred>
## Deferred Ideas

- Replacing SwiftTerm with a custom GPU terminal text renderer is deferred unless Phase 9 measurements prove it is the only viable path and the roadmap is updated.
- Broad UI rewrites, new visual modes, plugin performance work, updater/signing performance, telemetry, and cloud benchmarking are out of scope.
- Automated competitor benchmarking against Ghostty/iTerm is deferred unless those apps are already installed and the benchmark can stay deterministic; Phase 9 should not depend on third-party app availability.
- Long-duration soak testing beyond the focused benchmark suite can be added to Alpha/Beta release validation.

</deferred>

---

*Phase: 09-performance-hardening*
*Context gathered: 2026-05-21*
