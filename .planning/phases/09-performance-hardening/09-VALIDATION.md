---
phase: 09
slug: performance-hardening
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-21
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest plus shell benchmark runner |
| **Config file** | `project.yml` |
| **Quick run command** | `bash -n .planning/phases/09-performance-hardening/run-performance-benchmarks.sh && git diff --check` |
| **Full suite command** | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| **Estimated runtime** | ~45 seconds before live benchmark runs |

---

## Sampling Rate

- **After every task commit:** Run `bash -n .planning/phases/09-performance-hardening/run-performance-benchmarks.sh && git diff --check` once the script exists.
- **After every plan wave:** Run `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`.
- **Before `$gsd-verify-work`:** Full suite, benchmark smoke, final benchmark report, and privacy gates must be green.
- **Max feedback latency:** 240 seconds for build/test feedback; live benchmark suite may take longer and must report elapsed time.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | Benchmark harness and report schema | shell/static | `bash -n .planning/phases/09-performance-hardening/run-performance-benchmarks.sh && rg 'PHASE9_PERFORMANCE_REPORT|cold_start_ms|idle_cpu_percent|rss_mb' .planning/phases/09-performance-hardening/run-performance-benchmarks.sh` | ❌ W0 | ⬜ pending |
| 09-01-02 | 01 | 1 | Release docs for benchmark invocation | docs/source | `rg 'Phase 9 performance hardening|run-performance-benchmarks.sh|phase9-results.json' docs/release.md .planning/phases/09-performance-hardening` | ❌ W0 | ⬜ pending |
| 09-02-01 | 02 | 2 | App benchmark coordinator and launch args | source/build | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && rg 'phase9-ready-smoke|phase9-input-latency-smoke|phase9-heavy-output-smoke|PHASE9_READY|PHASE9_INPUT_LATENCY|PHASE9_HEAVY_OUTPUT' Sources/GridOSApp` | ❌ W0 | ⬜ pending |
| 09-02-02 | 02 | 2 | Synthetic terminal marker behavior | source/privacy | `rg 'runInActivePane|isActivePaneProcessRunning|PHASE9_HEAVY_OUTPUT_DONE' Sources/GridOSApp/Phase9PerformanceSmokeCoordinator.swift && ! rg 'shellHistory|terminalTranscript|environmentVariables|apiKey' Sources/GridOSApp/Phase9PerformanceSmokeCoordinator.swift` | ❌ W0 | ⬜ pending |
| 09-03-01 | 03 | 3 | Cold start, RSS, idle CPU scenarios | benchmark | `.planning/phases/09-performance-hardening/run-performance-benchmarks.sh --quick && rg 'cold_start_ms|rss_mb|idle_cpu_percent|PASS|MISS' .planning/phases/09-performance-hardening/evidence/phase9-results.json .planning/phases/09-performance-hardening/evidence/README.md` | ❌ W0 | ⬜ pending |
| 09-03-02 | 03 | 3 | Input latency and heavy output scenarios | benchmark | `.planning/phases/09-performance-hardening/run-performance-benchmarks.sh --quick && rg 'input_latency_ms|heavy_output|PHASE9_HEAVY_OUTPUT_DONE' .planning/phases/09-performance-hardening/evidence/phase9-results.json .planning/phases/09-performance-hardening/evidence/README.md` | ❌ W0 | ⬜ pending |
| 09-03-03 | 03 | 3 | Frame pacing/Instruments scenario | benchmark/docs | `.planning/phases/09-performance-hardening/run-performance-benchmarks.sh --quick && rg 'frame_pacing|xctrace|Animation Hitches|Metal System Trace' .planning/phases/09-performance-hardening/evidence/phase9-results.json .planning/phases/09-performance-hardening/evidence/README.md` | ❌ W0 | ⬜ pending |
| 09-04-01 | 04 | 4 | Final Phase 9 evidence and docs | docs/source | `rg 'Phase 9 final gate|Cold start|Resident memory|Idle CPU|Input latency|Heavy output|Frame pacing|Misses and mitigations' .planning/phases/09-performance-hardening/evidence/README.md docs/release.md` | ❌ W0 | ⬜ pending |
| 09-04-02 | 04 | 4 | Planning state and verification report | docs/source | `rg 'Phase 09 verification passed|Phase 10 - Security and privacy hardening|09-VERIFICATION.md' .planning/STATE.md .planning/ROADMAP.md .planning/phases/09-performance-hardening/09-VERIFICATION.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/09-performance-hardening/run-performance-benchmarks.sh` — benchmark runner stub.
- [ ] `Sources/GridOSApp/Phase9PerformanceSmokeCoordinator.swift` — benchmark smoke fixture source.
- [ ] `.planning/phases/09-performance-hardening/evidence/` — evidence output directory.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| xctrace profile usefulness | Instruments profiles checked into release evidence or summarized | xctrace can prompt or fail depending on local permissions and trace bundles can be large/private | Run the Phase 9 benchmark script without `--quick`; verify it records either an xctrace export summary or an explicit unavailable reason. |
| Subjective smoothness sanity check | Sustained smooth animation where hardware supports it | Frame-pacing numbers do not fully replace human-visible animation review | Launch the app in Tron mode, trigger terminal activity, and confirm animation does not visibly hitch while terminal remains usable. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-21
