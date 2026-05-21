# Phase 9 performance hardening

## Phase 9 final gate

Status: fixture smoke ready. Live threshold measurements are added in later Phase 9 plans.

## Benchmark invocation

```sh
.planning/phases/09-performance-hardening/run-performance-benchmarks.sh --quick
```

Outputs:

- `.planning/phases/09-performance-hardening/evidence/phase9-results.json`
- `.planning/phases/09-performance-hardening/evidence/README.md`

## Targets

| Metric | Target |
| --- | --- |
| Cold start | < 500 ms to terminal-ready marker |
| Resident memory | < 100 MB for basic terminal plus one visual mode |
| Idle CPU | < 0.5% after startup/render bursts settle |
| Input latency | < 5 ms controller-to-PTY marker proxy |
| Frame pacing | active-pulse pacing evidence |

## Results

| Scenario | Status | Marker |
| --- | --- | --- |
| Cold start | PASS | PHASE9_READY |
| Resident memory | MISS | ps rss |
| Idle CPU | MISS | ps %cpu |
| Input latency smoke | MISS | PHASE9_INPUT_LATENCY |
| Heavy output smoke | MISS | PHASE9_HEAVY_OUTPUT_DONE |
| Frame pacing smoke | MISS | PHASE9_FRAME_PACING |

## Cold start

- **Target:** < 500 ms
- **Observed:** 88.373 ms
- **Status:** PASS
- **Command:** `gridOS --phase9-ready-smoke`
- **Notes:** App launch to Phase 9 ready marker.

## Resident memory

- **Target:** < 100 MB
- **Observed:** 110.12 MB
- **Status:** MISS
- **Command:** `ps -o rss= -p <gridOS pid>`
- **Notes:** RSS sampled after a short startup settle window.

## Idle CPU

- **Target:** < 0.5%
- **Observed:** 99.000%
- **Status:** MISS
- **Command:** `ps -o %cpu= -p <gridOS pid>`
- **Notes:** Average of five quiet-window samples.

## Misses and mitigations

| Metric | Status | Owner | Mitigation |
| --- | --- | --- | --- |
| Resident memory | MISS | Phase 09 | Profile resident memory and reduce baseline allocations or document release exception. |
| Idle CPU | MISS | Phase 09 | Profile idle run loop, metrics sampler, and render lifecycle. |
| Input latency | MISS | Phase 09 | Validate terminal-bound fixture availability and measure controller-to-PTY latency. |
| Heavy output | MISS | Phase 09 | Validate terminal-bound heavy-output fixture and inspect UI/output batching. |
| Frame pacing | MISS | Phase 09 | Validate render-pulse fixture and capture frame-pacing summary. |

## Known limitations

- This report contains fixture smoke status only until Plan 09-03 adds measured scenarios.
- No private shell history, terminal transcripts, environment variables, API keys, screenshots, or raw Instruments traces are captured.
- Full xctrace/profile behavior is added after deterministic app-side benchmark markers exist.
