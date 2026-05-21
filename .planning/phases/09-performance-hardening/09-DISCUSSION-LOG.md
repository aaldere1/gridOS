# Phase 09: Performance hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-21
**Phase:** 09-performance-hardening
**Mode:** Auto-selected because workspace config has YOLO/skip-discuss enabled.
**Areas discussed:** Benchmark strategy, measurement harness, cold start and memory, idle CPU and frame pacing, terminal latency and heavy output, preservation rules

---

## Benchmark Strategy

| Option | Description | Selected |
| --- | --- | --- |
| Measurement-first | Build repeatable benchmarks and evidence before optimizing. | ✓ |
| Optimize obvious spots first | Patch likely hot spots before measuring. | |
| Manual feel check | Use subjective app responsiveness as proof. | |

**Auto choice:** Measurement-first.
**Notes:** This matches Phase 9's roadmap requirement that every target has a measured report, not an estimate.

---

## Measurement Harness

| Option | Description | Selected |
| --- | --- | --- |
| Repo-local harness | Checked-in scripts/helpers produce repeatable reports and sanitized evidence. | ✓ |
| Ad hoc shell commands | Fast, but hard for downstream phases to reproduce. | |
| External profiling only | Useful for deep dives, but not enough for committed gates. | |

**Auto choice:** Repo-local harness.
**Notes:** Evidence should include commands, values, targets, config, and pass/fail status.

---

## Cold Start And Memory

| Option | Description | Selected |
| --- | --- | --- |
| Real app readiness | Measure launch to first usable terminal/readiness marker and settled RSS. | ✓ |
| Process spawn only | Easier but undercounts user-visible startup. | |
| Component microbench only | Useful later, but insufficient for release readiness. | |

**Auto choice:** Real app readiness.
**Notes:** Existing `--cmd` terminal marker smoke is a strong candidate for launch/readiness measurement.

---

## Idle CPU And Frame Pacing

| Option | Description | Selected |
| --- | --- | --- |
| Measure settled idle and render pulses | Prove quiet terminal/effects throttling plus frame behavior using app-local instrumentation where needed. | ✓ |
| Measure only active animation | Misses the critical idle CPU target. | |
| Assume Phase 2 burst logic is enough | Prior evidence is a guardrail, not Phase 9 proof. | |

**Auto choice:** Measure settled idle and render pulses.
**Notes:** `MetalBackgroundView` and `SystemMetricsSampler` are the key areas to measure.

---

## Terminal Latency And Heavy Output

| Option | Description | Selected |
| --- | --- | --- |
| Synthetic terminal markers | Use generated marker text and controlled output to measure latency/stress without private content. | ✓ |
| Capture real shell sessions | More realistic but violates privacy defaults. | |
| Skip latency until alpha | Would fail Phase 9 acceptance criteria. | |

**Auto choice:** Synthetic terminal markers.
**Notes:** Heavy output should also preserve active-pane routing and process cleanup.

---

## Preservation Rules

| Option | Description | Selected |
| --- | --- | --- |
| Targeted module-owned fixes | Optimize where measurements point while preserving Phase 1-8 guarantees. | ✓ |
| Broad rewrite | Too risky for a hardening phase. | |
| Add telemetry | Out of scope and conflicts with privacy posture. | |

**Auto choice:** Targeted module-owned fixes.
**Notes:** Any miss should be documented honestly with owner/mitigation rather than hidden.

---

## the agent's Discretion

- Exact benchmark tooling.
- Exact sampling windows and warm-up durations.
- Exact report shape and evidence folder layout.
- Whether to add small DEBUG/benchmark-only instrumentation in app code.

## Deferred Ideas

- Custom GPU terminal text renderer.
- Competitor benchmarking that depends on third-party apps being installed.
- Long-duration soak testing beyond focused Phase 9 evidence.
- Cloud or telemetry-based benchmarking.
