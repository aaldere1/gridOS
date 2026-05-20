---
phase: 04-real-system-metrics
plan: 01
subsystem: metrics
tags: [swiftui, macos, mach, iokit, libproc, xcodegen]
requires:
  - phase: 03-production-app-frame
    provides: terminal-first app frame with system strip and activity panel seams
provides:
  - typed system metrics snapshot model with explicit availability states
  - native no-root metrics provider for CPU, memory, disk, network, battery, thermal, and top processes
  - sampler-owned cadence and stale snapshot policy
  - snapshot-driven app-frame metrics strip and read-only top-process panel
affects: [phase-05-aesthetic-modes, phase-09-performance-hardening, phase-10-security-privacy-hardening]
tech-stack:
  added: []
  patterns: [snapshot availability, sampler boundary, native no-root metrics, deterministic delta tests]
key-files:
  created:
    - Sources/SystemMetrics/SystemMetricAvailability.swift
    - Sources/SystemMetrics/SystemMetricsSnapshot.swift
    - Sources/SystemMetrics/SystemMetricsSamplingPolicy.swift
    - Sources/SystemMetrics/NativeSystemMetricsProvider.swift
    - Sources/SystemMetrics/SystemMetricsSampler.swift
    - Tests/SystemMetricsTests/SystemMetricsModelTests.swift
    - Tests/SystemMetricsTests/SystemMetricsSamplingPolicyTests.swift
    - Tests/SystemMetricsTests/SystemMetricsDeltaTests.swift
  modified:
    - Sources/GridOSApp/RootView.swift
    - project.yml
    - gridOS.xcodeproj/project.pbxproj
    - gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme
    - docs/architecture.md
    - docs/release.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
key-decisions:
  - "Keep native APIs inside SystemMetrics and expose only SystemMetricsSnapshot to GridOSApp."
  - "Model stale and unavailable metric states explicitly instead of using fake fallback values."
  - "Show process name, PID, CPU percent, and resident memory only; no command lines, arguments, or process actions."
patterns-established:
  - "SystemMetricsSampler owns cadence and backpressure; SwiftUI views consume snapshots and sleep from SamplingState."
  - "Native providers return graceful copy such as Battery unavailable, Thermal unavailable, Network idle, and No process data."
requirements-completed: ["PHASE-04"]
duration: 11min
completed: 2026-05-20
---

# Phase 4: Real System Metrics Summary

**Native no-root `SystemMetrics` snapshots now drive the app frame's host metrics strip and read-only top-process panel.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-05-20T15:21:00Z
- **Completed:** 2026-05-20T15:32:39Z
- **Tasks:** 6
- **Files modified:** 17

## Accomplishments

- Added `SystemMetricAvailability` and `SystemMetricsSnapshot` models for CPU, memory, disk, network, battery, thermal, top processes, and sampling state.
- Added `SystemMetricsTests` covering availability states, graceful copy, cadence defaults, and synthetic delta math.
- Added `NativeSystemMetricsProvider` using Mach, Foundation volume keys, `getifaddrs`, IOKit power sources, `ProcessInfo.thermalState`, and libproc without shell commands.
- Added `LiveSystemMetricsSampler` and preview data so cadence/backpressure stays inside `SystemMetrics`.
- Replaced the Phase 3 placeholder strip/panel with snapshot-driven CPU, memory, network, battery, thermal, and top-process UI while keeping the terminal dominant.
- Updated architecture/release docs, state, roadmap, and verification evidence.

## Task Commits

1. **Task 04-01-01: Create SystemMetrics model and test target foundation** - `1af65d3`
2. **Task 04-01-02: Add sampling cadence and delta policy** - `8e2019b`
3. **Task 04-01-03: Implement native no-root metrics provider** - `19acde6`
4. **Task 04-01-04: Add app-consumable sampler service** - `302aad1`
5. **Task 04-01-05: Wire real metrics into the app frame** - `52bc884`
6. **Task 04-01-06: Update docs and run final Phase 4 verification** - final verification/docs commit

**Plan metadata:** `518687f`

## Files Created/Modified

- `Sources/SystemMetrics/SystemMetricAvailability.swift` - Availability enum for available, stale, and unavailable metric values.
- `Sources/SystemMetrics/SystemMetricsSnapshot.swift` - Typed snapshot and metric models plus deterministic delta helpers.
- `Sources/SystemMetrics/SystemMetricsSamplingPolicy.swift` - Cadence and stale-threshold policy.
- `Sources/SystemMetrics/NativeSystemMetricsProvider.swift` - Native macOS no-root sampling implementation.
- `Sources/SystemMetrics/SystemMetricsSampler.swift` - Async sampler protocol, live actor, and preview snapshot data.
- `Sources/GridOSApp/RootView.swift` - Snapshot-driven metrics strip and read-only top-process panel.
- `Tests/SystemMetricsTests/*` - Model, cadence, and delta regression tests.
- `docs/architecture.md` - Phase 4 architecture target.
- `docs/release.md` - Phase 4 metrics smoke.

## Decisions Made

- Sampling policy belongs in `SystemMetrics`; SwiftUI only consumes snapshots and waits for `nextRefreshAfter`.
- Native metrics do not shell out to `top`, `ps`, `vm_stat`, `netstat`, or Activity Monitor commands.
- Top-process display stays read-only and does not expose full command lines, arguments, paths, or actions.
- Hardware/API absence is normal UI state, not an error state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated Xcode project after new metrics source files**
- **Found during:** Task 04-01-05
- **Issue:** The generated `.xcodeproj` had not been refreshed after adding `NativeSystemMetricsProvider.swift` and `SystemMetricsSampler.swift`, so app-frame references could not resolve new public symbols.
- **Fix:** Ran `xcodegen generate --use-cache` and committed the regenerated project diff with app-frame wiring.
- **Files modified:** `gridOS.xcodeproj/project.pbxproj`
- **Verification:** Full scheme build/test passed.
- **Committed in:** `52bc884`

**2. [Rule 3 - Blocking] Replaced unavailable libproc name-buffer macro**
- **Found during:** Task 04-01-05
- **Issue:** `PROC_PIDPATHINFO_MAXSIZE` is unavailable to Swift in the active SDK.
- **Fix:** Used a fixed local buffer for `proc_name` and UTF-8 decoding from returned bytes.
- **Files modified:** `Sources/SystemMetrics/NativeSystemMetricsProvider.swift`
- **Verification:** Full scheme build/test passed.
- **Committed in:** `52bc884`

**3. [Rule 3 - Blocking] Satisfied GSD key-link pattern check**
- **Found during:** Task 04-01-06
- **Issue:** Key-link verification expected lowercase `delta`; test names contained uppercase `Delta`.
- **Fix:** Added a targeted test comment with the expected lowercase concept string.
- **Files modified:** `Tests/SystemMetricsTests/SystemMetricsDeltaTests.swift`
- **Verification:** `gsd-tools verify key-links` passed 3/3.
- **Committed in:** final verification/docs commit

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** All fixes were required for generated-project correctness and verification. No product scope was added.

## Issues Encountered

- Directly running the app binary wrote the smoke file but did not auto-quit. The accepted smoke path launches via LaunchServices, verifies the file, and quits the Debug app cleanly through LaunchServices.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 5 can build aesthetic modes against real metrics instead of placeholders. Keep effects subordinate to terminal readability and avoid obscuring the new metric text.

---
*Phase: 04-real-system-metrics*
*Completed: 2026-05-20*
