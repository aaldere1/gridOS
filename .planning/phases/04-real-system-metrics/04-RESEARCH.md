# Phase 04 Research - Real system metrics

## RESEARCH COMPLETE

## Goal

Answer what planning needs to know before implementing Phase 4: a truthful, no-root, local-only `SystemMetrics` service plus app-frame panels that replace Phase 3 placeholders without harming terminal usability or idle behavior.

## Current Codebase Findings

### App frame

- `Sources/GridOSApp/RootView.swift` already has the exact display seams Phase 4 needs: `SystemStripView` for compact host health and `ActivityContextPanel` for activity/process context.
- The terminal is wrapped by `TerminalWorkspaceView`, and Phase 3 verification confirms it remains the dominant region.
- `RootView` currently owns placeholder panel copy; Phase 4 should replace that placeholder data with `SystemMetrics` snapshots rather than sampling inside SwiftUI views.

### Metrics module

- `Sources/SystemMetrics/SystemMetricsStatus.swift` is currently only a scaffold.
- `project.yml` already declares `SystemMetrics` as a framework dependency of `gridOS`, but there is no `SystemMetricsTests` bundle yet.
- The established pattern is module-owned pure models plus tests: Phase 3 added `GridOSAppPreferences` in `GridOSKit`, `VisualEffectConfiguration` in `RenderCore`, and module-specific XCTest coverage.

### Release/smoke patterns

- `docs/release.md` documents repeatable app launch smoke via `--cmd`.
- Phase 4 should keep that smoke path and add metrics-specific evidence without requiring manual interaction.

## Primary Source Research

### CPU

Recommended baseline: use Mach processor load snapshots through `host_processor_info(..., PROCESSOR_CPU_LOAD_INFO, ...)`, then calculate CPU utilization from deltas between ticks. The local macOS 26.5 SDK exposes `host_processor_info` in `usr/include/mach/mach_host.h` and `PROCESSOR_CPU_LOAD_INFO` in `usr/include/mach/processor_info.h`.

Planning implication:

- Model CPU as a delta-based value, not a one-shot absolute value.
- Keep prior CPU ticks in the sampler state.
- Make unavailable/failure explicit when Mach calls fail.

Sources:

- Apple Developer Documentation: `host_processor_info` — https://developer.apple.com/documentation/kernel/1502854-host_processor_info
- Local SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/mach/mach_host.h`
- Local SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/mach/processor_info.h`

### Memory

Recommended baseline: use `host_statistics64(..., HOST_VM_INFO64, ...)` with `vm_statistics64_data_t`, plus host page size, to calculate used/free/active/inactive/wired/compressed-style memory values where available. The local SDK exposes `HOST_VM_INFO64` and `HOST_VM_INFO64_COUNT` in `usr/include/mach/host_info.h`.

Planning implication:

- Keep the public model higher-level than raw VM counters: total bytes, used bytes, available bytes, pressure/status if available, and timestamp.
- Do not over-promise Activity Monitor exactness, because Activity Monitor's visible categories may combine counters differently.

Sources:

- Apple Developer Documentation: `host_statistics64` — https://developer.apple.com/documentation/kernel/1502863-host_statistics64
- Apple Developer Documentation: `vm_statistics64_t` — https://developer.apple.com/documentation/kernel/vm_statistics64_t
- Local SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/mach/host_info.h`

### Disk

Recommended baseline: use Foundation `FileManager` and `URLResourceValues` volume capacity keys for mounted volumes. `volumeAvailableCapacityForImportantUsage` is specifically exposed as bytes for important resource storage; `volumeTotalCapacity` and `volumeAvailableCapacity` are also available.

Planning implication:

- Phase 4 should start with the root/home volume unless research during execution identifies a cheap mounted-volume summary.
- Disk capacity refresh can be slower than CPU/network because it is not a high-frequency signal.
- Capacity values can be unavailable and should degrade gracefully.

Sources:

- Apple Developer Documentation: `FileManager` — https://developer.apple.com/documentation/foundation/filemanager
- Apple Developer Documentation: `volumeAvailableCapacityForImportantUsage` — https://developer.apple.com/documentation/foundation/urlresourcevalues/volumeavailablecapacityforimportantusage

### Network

Recommended baseline: use `getifaddrs()` and AF_LINK `if_data` counters for interface byte deltas. The local `getifaddrs(3)` man page documents that AF_LINK entries expose address-family-specific data through `ifa_data`, and that this data should be released with `freeifaddrs()`.

Planning implication:

- Model network throughput as delta bytes per second across active non-loopback interfaces.
- Keep prior byte counters in sampler state.
- Treat zero throughput as `idle`, not unavailable.

Sources:

- Local man page: `getifaddrs(3)`
- Local SDK headers: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/ifaddrs.h`
- Local SDK headers: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/net/if.h`

### Battery and power

Recommended baseline: use IOKit power source APIs: `IOPSCopyPowerSourcesInfo`, `IOPSCopyPowerSourcesList`, and `IOPSGetPowerSourceDescription`. Apple notes that not every power source dictionary contains every key; some values such as time remaining can be unknown or unlimited.

Planning implication:

- Battery must be optional. Desktop Macs and unsupported power sources should show `Battery unavailable`.
- Expose charge percent, charging state, and power source when present.
- Avoid serial numbers, adapter details, or low-level power diagnostics in Phase 4.

Sources:

- Apple Developer Documentation: `IOPSGetPowerSourceDescription` — https://developer.apple.com/documentation/iokit/1523867-iopsgetpowersourcedescription
- Apple Developer Documentation: IOPowerSources defines — https://developer.apple.com/documentation/iokit/iopowersources_h/defines
- Local SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/System/Library/Frameworks/IOKit.framework/Headers/ps/IOPowerSources.h`
- Local SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/System/Library/Frameworks/IOKit.framework/Headers/ps/IOPSKeys.h`

### Thermal

Recommended baseline: use `ProcessInfo.processInfo.thermalState` and the associated thermal-state change notification. Apple documents thermal state as the current system thermal state and recommends reducing system usage at higher states.

Planning implication:

- Thermal state is a coarse app-facing signal, not a detailed sensor readout.
- UI labels should use normal terms such as `Nominal`, `Fair`, `Serious`, `Critical`, or `Thermal unavailable`.
- Thermal should refresh slowly or event-driven; do not poll hardware sensors.

Sources:

- Apple Developer Documentation: `ProcessInfo` — https://developer.apple.com/documentation/foundation/processinfo
- Apple Developer Documentation: `thermalState` — https://developer.apple.com/documentation/foundation/processinfo/1417480-thermalstate

### Top processes

Recommended baseline: use libproc APIs for a read-only top-process panel. The local SDK exposes `proc_listpids`, `proc_pidinfo`, `proc_name`, and `PROC_PIDTASKINFO`; `proc_taskinfo` contains resident size and total user/system CPU time counters.

Planning implication:

- Top-process CPU should be delta-based across samples, like total CPU.
- The first display should include process name, PID, CPU percent, and memory bytes.
- Do not show full command arguments by default. That would violate the Phase 4 privacy decision.
- Some PIDs may disappear or deny information between list and detail calls; this is normal and should not surface as an error.

Sources:

- Apple Developer Documentation: EndpointSecurity process check note for `proc_pidinfo` correspondence — https://developer.apple.com/documentation/endpointsecurity/es_proc_check_type_pidinfo
- Local SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/libproc.h`
- Local SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/proc_info.h`

## Recommended Implementation Shape

### SystemMetrics module

Create pure, testable models first:

- `MetricAvailability<Value>` or equivalent enum for `.available(Value)`, `.unavailable(reason:)`, and possibly `.stale(Value, age:)`.
- `SystemMetricsSnapshot` containing `timestamp`, `cpu`, `memory`, `disk`, `network`, `battery`, `thermal`, `topProcesses`, and `samplingState`.
- Domain models such as `CPUMetrics`, `MemoryMetrics`, `DiskMetrics`, `NetworkMetrics`, `BatteryMetrics`, `ThermalMetrics`, and `ProcessMetrics`.
- `SamplingPolicy` with fast cadence, slow cadence, stale threshold, and reduced cadence.

Then add a sampler boundary:

- `SystemMetricsSampler` protocol exposing a snapshot method or async stream.
- `LiveSystemMetricsSampler` for native API calls.
- `MockSystemMetricsSampler` or static fixtures for tests and previews.

The app target should consume snapshots from `SystemMetrics`; it should not call Mach, IOKit, libproc, or network interface APIs directly.

### UI integration

Use the Phase 3 app frame:

- Replace `SystemStripView` with a snapshot-driven view that displays CPU, memory, network, battery/power, and thermal.
- Replace/extend `ActivityContextPanel` with top processes and concise unavailable explanations.
- Preserve `TerminalWorkspaceView` dominance.
- Keep display text dense and scan-friendly; avoid huge charts, fake labels, or tutorial text.

### Sampling behavior

Start with a conservative policy:

- Fast cadence: 1 second for CPU, memory, network, and top processes.
- Slow cadence: 10 seconds for battery, thermal, and disk capacity.
- Stale threshold: 3 seconds for fast metrics and 30 seconds for slow metrics.
- Reduced cadence/background: at least 5 seconds for fast metrics when app/window is not active or panels are not visible.

Research risk: these values may need adjustment after measurement, but planning should encode them as the first measurable target.

## Validation Architecture

### Automated checks

- `xcodegen generate --use-cache`
- `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- `git diff --check`
- `rg "SystemMetricsSnapshot|SystemMetricsSampler|SamplingPolicy|TopProcess|Battery unavailable|Thermal unavailable" Sources Tests`

### Unit coverage

Add `SystemMetricsTests` and cover:

- snapshot construction and availability states
- percentage clamping/formatting
- stale threshold behavior
- sampling cadence policy selection
- CPU/network/top-process delta calculations from synthetic samples
- battery/thermal unavailable wording

### Source verification

- `project.yml` contains `SystemMetricsTests`
- `Sources/GridOSApp/RootView.swift` imports `SystemMetrics`
- `Sources/GridOSApp/RootView.swift` contains snapshot-driven `SystemStripView` and `ActivityContextPanel`
- `Sources/SystemMetrics` contains no networking, telemetry, LLM, or persistence API usage

### Smoke checks

- Existing app launch smoke with `--cmd` still writes a file and exits cleanly.
- Phase 4 smoke should launch the Debug app, verify `GRIDOS_PHASE4_SMOKE`, and sample CPU after the initial render/metrics startup period.
- A source or log check should prove the UI has graceful labels for unavailable battery/thermal metrics.

## Research Risks

- Exact Activity Monitor parity is not guaranteed because Activity Monitor may use private or differently grouped counters. The acceptance bar should remain "closely enough for normal use."
- Some libproc calls can fail for short-lived or protected processes. Treat this as normal churn.
- Battery and thermal data may be unavailable depending on hardware. The plan must test graceful degradation.
- High-frequency process enumeration can become the main idle CPU cost. Keep top-process sampling conservative and measurable.
