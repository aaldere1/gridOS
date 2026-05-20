# gridOS architecture

This document tracks the intended production architecture as implementation begins.

## Project generation

`project.yml` is the source of truth for the Xcode project. Regenerate with:

```sh
xcodegen generate
```

The generated project should not be manually edited for structural changes. Update `project.yml` instead.

## Targets

- `gridOS`: macOS SwiftUI app target.
- `GridOSKit`: shared product models and cross-module types.
- `TerminalCore`: PTY, shell lifecycle, SwiftTerm adapter, and terminal session model.
- `RenderCore`: Metal renderer, shader pipelines, visual modes, and procedural identity.
- `SystemMetrics`: CPU, memory, disk, network, power, thermal, and process sampling.
- `CommandIntelligence`: LLM provider abstraction, context packing, redaction, and command safety.
- `GridOSKitTests`: shared model unit tests.
- `TerminalCoreTests`: terminal configuration and session model unit tests.
- `RenderCoreTests`: visual identity, render event, and shader compile unit tests.
- `SystemMetricsTests`: metrics model, cadence policy, and delta calculation unit tests.

## Dependency direction

The app target can depend on all feature modules. Feature modules can depend on `GridOSKit`. Feature modules should not depend on each other unless a later phase explicitly introduces a narrow protocol boundary.

Current direction:

```text
gridOS -> GridOSKit
gridOS -> TerminalCore
gridOS -> RenderCore
gridOS -> SystemMetrics
gridOS -> CommandIntelligence

TerminalCore -> GridOSKit
RenderCore -> GridOSKit
SystemMetrics -> GridOSKit
CommandIntelligence -> GridOSKit
```

## Phase 1 architecture target

Phase 1 introduces a real terminal through `TerminalCore` without letting SwiftTerm leak directly into the app shell.

Target abstractions:

- `TerminalSessionConfiguration`
- `TerminalSessionState`
- `TerminalSurface`
- `TerminalCommandCenter`

`TerminalSurface` is currently backed by SwiftTerm's `LocalProcessTerminalView`. The app shell should continue to consume `TerminalCore` APIs only.

For repeatable launch smoke tests, `TerminalSessionConfiguration.fromProcessArguments()` recognizes `--cmd <command>` and sends that command to the shell shortly after launch.

## Phase 2 architecture target

Phase 2 introduces `RenderCore` through a single Metal surface that can be hosted by the app without coupling terminal correctness to shader work.

Current abstractions:

- `VisualIdentity`
- `VisualMode`
- `ProceduralSeed`
- `RenderEvent`
- `MetalBackgroundView`

`MetalBackgroundView` hosts an `MTKView` and compiles the first embedded `Signal Field` shader at runtime. Rendering is burst-driven: the background draws an initial frame, animates briefly after terminal activity, and invalidates its timer after the pulse decays.

`TerminalCore` emits coarse `TerminalActivityEvent` values for input, output, resize, and process lifecycle events. `GridOSApp` translates those events into `RenderEvent` values. This preserves the dependency rule: `TerminalCore` does not import or depend on `RenderCore`.

## Phase 3 architecture target

Phase 3 turns the prototype into a production-shaped app frame while preserving the Phase 1 terminal boundary and Phase 2 render boundary.

Current abstractions:

- `GridOSAppPreferences`
- `VisualEffectConfiguration`
- `WindowFrameController`
- `AppFrameHeader`
- `SystemStripView`
- `ActivityContextPanel`
- `TerminalWorkspaceView`

`GridOSAppPreferences` lives in `GridOSKit` so shell path, terminal font size, reduced motion, and visual intensity defaults can be tested outside the SwiftUI app. `RootView` and `SettingsView` share the same `@AppStorage` keys, and `RootView` maps persisted values into a fresh `TerminalSessionConfiguration` without bypassing `TerminalCore`.

`WindowFrameController` is an invisible AppKit bridge attached to the root view. It configures hidden-titlebar chrome, minimum size, and `setFrameAutosaveName("gridOS.main")` without making itself first responder.

`VisualEffectConfiguration` lives in `RenderCore` and controls pulse magnitude from visual intensity and reduced motion. `RootView` combines the app preference with `accessibilityReduceMotion` before passing the effective setting into `MetalBackgroundView`.

The app frame remains terminal-first: `TerminalWorkspaceView` is the dominant working region, while `SystemStripView` and `ActivityContextPanel` provide compact support surfaces around it.

## Phase 4 architecture target

Phase 4 replaces the placeholder support surfaces with local, truthful metrics while keeping native sampling isolated inside `SystemMetrics`.

Current abstractions:

- `SystemMetricsSnapshot`
- `SystemMetricAvailability`
- `SystemMetricsSamplingPolicy`
- `NativeSystemMetricsProvider`
- `SystemMetricsSampler`
- `LiveSystemMetricsSampler`
- `SystemMetricsPreviewData`

`SystemMetricsSnapshot` is the app-facing value model. It carries timestamped availability for CPU, memory, disk, network, battery, thermal, and top processes, plus `SamplingState` so the UI can distinguish current, stale, and unavailable data. `SystemMetricAvailability` makes unavailable states explicit instead of letting the app infer missing values from optionals.

`SystemMetricsSamplingPolicy` owns cadence and backpressure: fast metrics default to a one-second cadence, slower-changing metrics have slower stale thresholds, and background sampling can reduce refresh pressure. `RootView` only asks the sampler for snapshots and sleeps for `samplingState.nextRefreshAfter`; SwiftUI views do not own sampling policy.

`NativeSystemMetricsProvider` is the native no-root sampling boundary. It uses Mach CPU and VM statistics, Foundation volume capacity keys, `getifaddrs` interface counters, IOKit power-source data, `ProcessInfo.thermalState`, and libproc process counters. It does not shell out to `top`, `ps`, `vm_stat`, or network tools.

`LiveSystemMetricsSampler` stores the prior CPU, network, and process counter samples needed for delta calculations, then emits one `SystemMetricsSnapshot` for the app frame. It keeps the work local-only: no network APIs, no telemetry sink, no LLM context handoff, and no persistent metric logs. When hardware or APIs do not expose a metric, the snapshot carries normal platform copy such as `Battery unavailable`, `Thermal unavailable`, `Network idle`, or `No process data`.

`RootView` consumes the sampler through the `SystemMetricsSampler` protocol. `SystemStripView(snapshot:)` displays compact CPU, memory, network, battery, and thermal readouts; `ActivityContextPanel(snapshot:)` displays a read-only top-process list with process name, PID, CPU percent, and resident memory only.

## Phase 5 architecture target

Phase 5 turns the single visual identity into three local aesthetic systems while keeping terminal and metrics correctness ahead of effects.

Current abstractions:

- `VisualMode`
- `VisualTheme`
- `VisualMotionProfile`
- `VisualIdentity`
- `GridOSAppPreferences.visualModeStorageKey`
- `GridOSAppPreferences.installSeedStorageKey`

`VisualMode` exposes exactly `tron`, `severance`, and `appleNative`; `VisualTheme` owns each mode's palette, panel, terminal chrome, motion, and shader tokens. `VisualMotionProfile` composes with `VisualEffectConfiguration` so app and system reduced-motion settings still suppress motion across every mode.

`RootView` reads the local `appearance.visualMode` and `appearance.installSeed` preferences with `@AppStorage`, normalizes them through `GridOSAppPreferences`, and composes a `VisualIdentity`. The selected mode is changed through Settings or the native Appearance command menu. The required shortcut is `Command-Shift-M`, implemented as `.keyboardShortcut("m", modifiers: [.command, .shift])`, and it only changes the local mode preference.

The app-frame UI consumes `VisualTheme` tokens at the boundary: header indicator, metrics strip, activity panel, panel separators, and terminal chrome styling are mode-aware without changing the terminal layout. SwiftTerm text rendering stays owned by `TerminalCore`.

`MetalBackgroundView` receives the full `VisualIdentity`. Its renderer maps `VisualIdentity.seed` through `identity.seed.normalizedVector` into the shader uniform `seed`, alongside the mode shader value and theme palette/profile inputs. The Metal shader keeps one pipeline but branches visually for Tron, Severance, and Apple-native so the same install seed can prove mode distinction and different install seeds can prove subtle same-mode variation.

Cyberpunk, Matrix, sound themes, plugin/user themes, full light mode, GPU terminal text rendering, marketplace/import themes, and eDEX theme compatibility are deferred and out of scope for the Phase 5 architecture target.

## Architecture rule

Every major feature should enter through a small module-owned API first. The app shell composes features; it should not become the place where terminal, rendering, metrics, and LLM details mix.
