# Phase 09: Performance Hardening - Research

**Researched:** 2026-05-21
**Status:** Complete

## Research Goal

Answer: what do we need to know to plan Phase 9 well?

Phase 9 must prove gridOS performance with repeatable evidence: cold start, memory baseline, idle CPU, input latency, heavy output, and frame pacing. The core planning risk is not knowing how to implement the app; it is building a benchmark suite that is repeatable, privacy-safe, honest, and useful enough to drive targeted fixes.

## Current Performance-Relevant Architecture

### App launch and terminal readiness

`TerminalSessionConfiguration.fromProcessArguments()` already supports `--cmd`, and prior release smoke uses it to write marker files after the embedded shell accepts startup command text. This is the best existing readiness path for launch/cold-start measurement because it proves the app reached the user-visible terminal path, not just `execve`.

Relevant files:

- `Sources/TerminalCore/TerminalSessionConfiguration.swift`
- `Sources/TerminalCore/TerminalSurface.swift`
- `docs/release.md`

### Terminal activity and heavy output

`TerminalSurface` wraps SwiftTerm's `LocalProcessTerminalView`. It emits input/output activity and batches output activity callbacks at about 30 Hz before handing events back to `RootView`. This is directly relevant to heavy output stress because terminal output can trigger render pulses and SwiftUI state updates if not batched.

Relevant files:

- `Sources/TerminalCore/TerminalSurface.swift`
- `Sources/TerminalCore/TerminalActivityEvent.swift`
- `Sources/GridOSApp/RootView.swift`

### Render/frame pacing

`MetalBackgroundView` creates an `MTKView` with `isPaused = true`, `enableSetNeedsDisplay = true`, and a 30 Hz `Timer` only during activity pulses. It is intentionally not a constantly running game loop. Phase 9 should measure settled idle and active pulse behavior before changing this.

Relevant files:

- `Sources/RenderCore/MetalBackgroundView.swift`
- `Sources/RenderCore/VisualEffectConfiguration.swift`
- `Tests/RenderCoreTests/RenderCoreModelTests.swift`

### Metrics sampler overhead

`LiveSystemMetricsSampler` caches snapshots by cadence. `SystemMetricsSamplingPolicy.defaultValue` uses 1 second active cadence, 10 second slow cadence, and 5 second background cadence. The sampler already models stale snapshots; Phase 9 should measure real overhead and only optimize if measurements show it matters.

Relevant files:

- `Sources/SystemMetrics/SystemMetricsSampler.swift`
- `Sources/SystemMetrics/SystemMetricsSamplingPolicy.swift`
- `Sources/SystemMetrics/NativeSystemMetricsProvider.swift`

### Existing deterministic smoke patterns

Phase 7 and Phase 8 added deterministic smoke coordinators that write marker files and avoid screenshots/private terminal content. Phase 9 should reuse this style for input-latency and heavy-output markers.

Relevant files:

- `Sources/GridOSApp/Phase7MultiPaneSmokeCoordinator.swift`
- `Sources/GridOSApp/Phase8MacIntegrationsSmokeCoordinator.swift`

## Local Tooling Findings

### xctrace

Local `xcrun xctrace` is available. The CLI supports:

- `xcrun xctrace record --template 'Time Profiler' --time-limit 5s --launch -- <command>`
- `xcrun xctrace record --template 'Animation Hitches' --time-limit 5s --launch -- <command>`
- `xcrun xctrace record --template 'Metal System Trace' --time-limit 5s --launch -- <command>`
- `xcrun xctrace export --input <file.trace> --toc`
- `xcrun xctrace export --input <file.trace> --xpath <expression>`

Installed templates include `Activity Monitor`, `Allocations`, `Animation Hitches`, `App Launch`, `CPU Profiler`, `Metal System Trace`, `Power Profiler`, `SwiftUI`, `System Trace`, and `Time Profiler`.

Planning implication: the harness can attempt `xctrace` for profile/TOC evidence, but raw `.trace` bundles may be large and may contain environment/process details. Commit summary exports and exact rerun commands by default; only commit trace bundles if they are intentionally scrubbed and size-acceptable.

### Process sampling

For lightweight local evidence, shell-level process sampling is sufficient:

- `ps -o rss= -o %cpu= -p <pid>` gives resident size and instantaneous CPU.
- Multiple samples over a short window are better than one instantaneous CPU sample.
- RSS from `ps` is in KiB on macOS; reports should convert to MB.

Planning implication: use a small sampling window after a warm-up/settle period for idle CPU and memory baseline.

### Timing

macOS `/bin/date` does not reliably provide nanosecond precision. Use `/usr/bin/perl -MTime::HiRes=time` or a small Swift helper if sub-second timing precision matters. This keeps the benchmark harness available on a stock Mac.

Planning implication: do not build cold-start/input-latency measurements on `date +%s%N`.

## Recommended Plan Shape

1. **Benchmark harness foundation**
   - Add a checked-in runner script.
   - Resolve build configuration, app path, marker paths, time source, sample helpers, and report schema.
   - Produce JSON plus Markdown.

2. **Deterministic app benchmark fixtures**
   - Add a DEBUG/benchmark coordinator for app-ready, input-latency, heavy-output, and frame-pulse markers.
   - Drive public `TerminalWorkspaceController` APIs where terminal interaction is needed.
   - Keep marker content synthetic.

3. **Measurement scenarios**
   - Implement cold-start-to-ready, RSS, settled idle CPU, input latency, heavy output, and frame/instruments scenarios.
   - Include thresholds, observed values, pass/fail, and environment metadata.

4. **Final evidence and release docs**
   - Run the benchmark suite locally.
   - Record results and misses honestly.
   - Update release docs and planning state.

## Validation Architecture

### Automated gates

- `xcodegen generate --use-cache`
- `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- `git diff --check`
- Source gates for Phase 9 benchmark fixture arguments and marker strings.
- `bash -n .planning/phases/09-performance-hardening/run-performance-benchmarks.sh`
- Runner smoke with a small scenario set that writes `phase9-results.json` and `README.md` under evidence.

### Benchmark evidence gates

The final evidence report should include:

- Hardware/OS/build configuration.
- Cold start measured value and target.
- RSS measured value and target.
- Idle CPU measured value and target.
- Input latency measured value and target.
- Heavy output result and threshold/marker.
- Frame pacing or xctrace result and target/observation.
- Misses table with owner and mitigation.

### Privacy gates

Negative source/evidence checks should reject:

- `shellHistory`
- `terminalTranscript`
- `environmentVariables`
- real `apiKey` persistence patterns
- committed screenshots or raw terminal captures for Phase 9 evidence

## Research Risks

- Real cold-start numbers can be noisy because app launch, SwiftUI, first shell startup, and macOS scheduling all interact. Use repeated runs or at least record sample count.
- xctrace may prompt or fail depending on permissions. Treat this as profile evidence availability, not as a reason to block basic benchmark reporting.
- Input latency through a GUI terminal is hard to measure perfectly without private accessibility automation. A deterministic controller-to-PTY marker is acceptable for Phase 9 if documented as the current app-path latency proxy.
- Frame pacing is not the same as FPS in this app because rendering is burst-driven. Report active-pulse pacing and idle non-rendering separately.

## Conclusion

Phase 9 should not become a broad rewrite. The correct plan is to add a measured, privacy-safe benchmark harness, use deterministic app fixtures, run the suite, and then make narrow fixes only where evidence shows the native app misses its targets.
