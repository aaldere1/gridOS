# Phase 9 performance hardening

## Phase 9 final gate

Status: pending live measurements. The benchmark harness and report schema are present; app-side fixtures and measured scenarios are added in later Phase 9 plans.

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

Live measurements are pending until Plans 09-02 and 09-03.

## Misses and mitigations

| Metric | Status | Owner | Mitigation |
| --- | --- | --- | --- |
| Live measurements | pending | Phase 09 | Add app fixtures and measured scenarios in Plans 09-02 and 09-03. |

## Known limitations

- This initial report is a schema and quick-smoke placeholder.
- No private shell history, terminal transcripts, environment variables, API keys, screenshots, or raw Instruments traces are captured.
- Full xctrace/profile behavior is added after deterministic app-side benchmark markers exist.
