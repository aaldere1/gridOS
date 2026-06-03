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
| Memory footprint | < 100 MB physical footprint for basic terminal plus one visual mode |
| Idle CPU | < 0.5% after startup/render bursts settle |
| Input latency | < 5 ms command-dispatch marker proxy |
| Frame pacing | active-pulse pacing evidence |

## Results

| Scenario | Status | Marker |
| --- | --- | --- |
| Cold start | PASS | PHASE9_READY |
| Memory footprint | PASS | sample physical footprint |
| Idle CPU | PASS | ps %cpu |
| Input latency smoke | PASS | PHASE9_INPUT_LATENCY |
| Heavy output smoke | PASS | PHASE9_HEAVY_OUTPUT_DONE |
| Frame pacing smoke | PASS | PHASE9_FRAME_PACING |

## Cold start

- **Target:** < 500 ms
- **Observed:** 85.084 ms
- **Status:** PASS
- **Command:** `gridOS --phase9-ready-smoke`
- **Notes:** App launch to Phase 9 ready marker.

## Memory footprint

- **Target:** < 100 MB physical footprint
- **Observed:** 80.40 MB
- **Status:** PASS
- **Command:** `sample <gridOS pid> 1 -file <report>`
- **RSS advisory:** 110.58 MB from `ps -o rss=`
- **Notes:** Physical footprint sampled after 8s startup settle window.

## Idle CPU

- **Target:** < 0.5%
- **Observed:** 0.000%
- **Status:** PASS
- **Command:** `ps -o %cpu= -p <gridOS pid>`
- **Notes:** Average of five quiet-window samples after 8s settle.

## Input latency

- **Target:** < 5 ms
- **Observed:** 0.039 ms
- **Status:** PASS
- **Command:** `gridOS --phase9-input-latency-smoke`
- **Notes:** Command-dispatch marker proxy. Heavy output smoke separately verifies shell acceptance. Synthetic terminal markers only; no user shell output captured.

## Heavy output

- **Target:** synthetic marker completes and writes PHASE9_HEAVY_OUTPUT_DONE
- **Observed:** 842.849 ms, 500 synthetic lines
- **Status:** PASS
- **Command:** `gridOS --phase9-heavy-output-smoke`
- **Notes:** Synthetic terminal markers only; no user shell output captured.

## Frame pacing

- **Target:** active-pulse pacing evidence
- **Observed:** 278.236 ms, 8 render pulses
- **Status:** PASS
- **Command:** `gridOS --phase9-frame-pacing-smoke`
- **xctrace status:** UNAVAILABLE
- **xctrace detail:** Skipped in --quick mode.
- **Trace path:** null
- **TOC path:** null
- **Notes:** Full mode attempts `xcrun xctrace record --template 'Animation Hitches'` and `xcrun xctrace export`; raw trace bundles may be excluded from commits if too large or private.

## Misses and mitigations

| Metric | Status | Owner | Mitigation |
| --- | --- | --- | --- |
| None | PASS | n/a | n/a |

## Privacy proof

- Evidence is limited to synthetic DEBUG markers, process samples, benchmark status, and sanitized summary metadata.
- The committed report labels the app binary as `gridOS.app/Contents/MacOS/gridOS` instead of recording the local DerivedData path.
- The benchmark does not capture private shell history, terminal transcripts, environment variables, API keys, screenshots, or raw Instruments traces.

## Known limitations

- This quick report captures local Debug benchmark evidence; full xctrace capture is skipped in --quick mode.
- No private shell history, terminal transcripts, environment variables, API keys, screenshots, or raw Instruments traces are captured.
- Full xctrace/profile behavior records summary availability; raw trace bundles may be excluded from commits if too large or private.
