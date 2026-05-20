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

The app frame remains terminal-first: `TerminalWorkspaceView` is the dominant working region, while `SystemStripView` and `ActivityContextPanel` are truthful placeholders until later phases add real metrics and command context.

## Architecture rule

Every major feature should enter through a small module-owned API first. The app shell composes features; it should not become the place where terminal, rendering, metrics, and LLM details mix.
