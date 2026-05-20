---
phase: 04
slug: real-system-metrics
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 04 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest via Xcode scheme |
| **Config file** | `project.yml` and `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` |
| **Quick run command** | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| **Full suite command** | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` |
| **Estimated runtime** | ~5-20 seconds locally |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- **After every plan wave:** Run `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check`
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 20 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 04-01 | 1 | Metrics snapshot models and availability state | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` | yes | pending |
| 04-01-02 | 04-01 | 1 | Sampling cadence/backpressure policy | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` | yes | pending |
| 04-01-03 | 04-01 | 1 | Native CPU/memory/disk/network/battery/thermal process providers | unit + source | `rg "host_processor_info|host_statistics64|IOPSCopyPowerSourcesInfo|getifaddrs|proc_pidinfo|thermalState" Sources/SystemMetrics` | yes | pending |
| 04-01-04 | 04-01 | 1 | Snapshot sampler/service boundary | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` | yes | pending |
| 04-01-05 | 04-01 | 1 | App-frame system strip and activity panel integration | build + source | `rg "SystemMetricsSnapshot|SystemStripView|ActivityContextPanel|Battery unavailable|Thermal unavailable" Sources/GridOSApp Sources/SystemMetrics` | yes | pending |
| 04-01-06 | 04-01 | 1 | Final docs and smoke verification | full | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` | yes | pending |

*Status: pending until execution.*

---

## Wave 0 Requirements

Existing infrastructure covers the base scheme. Phase 4 must add:

- `Tests/SystemMetricsTests` — unit tests for metrics models, cadence policy, and synthetic delta calculations.
- `project.yml` updates for `SystemMetricsTests`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Activity Monitor comparison | Metrics match Activity Monitor closely enough for normal use | Activity Monitor uses live system state and may group counters differently | Launch gridOS and Activity Monitor, compare CPU/memory/network trends for 1-2 minutes under light load. |
| Hardware-specific unavailable states | Panels degrade gracefully when APIs are unavailable | Requires different Mac hardware such as desktops without batteries or systems with limited thermal data | Run app on available Mac types and confirm `Battery unavailable` or `Thermal unavailable` reads as normal status, not an error. |
| Idle CPU budget | Metrics sampling does not materially increase idle CPU | Requires live process sampling after render/metrics startup | Launch app, wait for initial activity to settle, sample gridOS CPU, and compare to Phase 2/3 idle evidence. |

---

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target under 20 seconds locally.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-20
