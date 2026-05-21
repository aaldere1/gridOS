# Phase 9 performance hardening

## Phase 9 final gate

Status: quick benchmark captured. Full xctrace capture is skipped in --quick mode.

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
- **Observed:** 94.273 ms
- **Status:** PASS
- **Command:** `gridOS --phase9-ready-smoke`
- **Notes:** App launch to Phase 9 ready marker.

## Resident memory

- **Target:** < 100 MB
- **Observed:** 110.53 MB
- **Status:** MISS
- **Command:** `ps -o rss= -p <gridOS pid>`
- **Notes:** RSS sampled after a short startup settle window.

## Idle CPU

- **Target:** < 0.5%
- **Observed:** 98.980%
- **Status:** MISS
- **Command:** `ps -o %cpu= -p <gridOS pid>`
- **Notes:** Average of five quiet-window samples.

## Input latency

- **Target:** < 5 ms
- **Observed:** null ms
- **Status:** MISS
- **Command:** `gridOS --phase9-input-latency-smoke`
- **Notes:** Controller-to-PTY marker proxy. Synthetic terminal markers only; no user shell output captured.

## Heavy output

- **Target:** synthetic marker completes and writes PHASE9_HEAVY_OUTPUT_DONE
- **Observed:** null ms, null synthetic lines
- **Status:** MISS
- **Command:** `gridOS --phase9-heavy-output-smoke`
- **Notes:** Synthetic terminal markers only; no user shell output captured.

## Frame pacing

- **Target:** active-pulse pacing evidence
- **Observed:** null ms, null render pulses
- **Status:** MISS
- **Command:** `gridOS --phase9-frame-pacing-smoke`
- **xctrace status:** UNAVAILABLE
- **xctrace detail:** Skipped in --quick mode.
- **Trace path:** null
- **TOC path:** null
- **Notes:** Full mode attempts `xcrun xctrace record --template 'Animation Hitches'` and `xcrun xctrace export`; raw trace bundles may be excluded from commits if too large or private.

## Misses and mitigations

| Metric | Status | Owner | Mitigation |
| --- | --- | --- | --- |
| Resident memory | MISS | Phase 09 | Profile resident memory and reduce baseline allocations or document release exception. |
| Idle CPU | MISS | Phase 09 | Profile idle run loop, metrics sampler, and render lifecycle. |
| Input latency | MISS | Phase 09 | Validate terminal-bound fixture availability and measure controller-to-PTY latency. |
| Heavy output | MISS | Phase 09 | Validate terminal-bound heavy-output fixture and inspect UI/output batching. |
| Frame pacing | MISS | Phase 09 | Validate render-pulse fixture and capture frame-pacing summary. |

## Known limitations

- This quick report captures local Debug benchmark evidence; full xctrace capture is skipped in --quick mode.
- No private shell history, terminal transcripts, environment variables, API keys, screenshots, or raw Instruments traces are captured.
- Full xctrace/profile behavior records summary availability; raw trace bundles may be excluded from commits if too large or private.
