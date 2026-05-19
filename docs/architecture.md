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
- `TerminalCore`: PTY, shell lifecycle, terminal backend adapter, and terminal session model.
- `RenderCore`: Metal renderer, shader pipelines, visual modes, and procedural identity.
- `SystemMetrics`: CPU, memory, disk, network, power, thermal, and process sampling.
- `CommandIntelligence`: LLM provider abstraction, context packing, redaction, and command safety.
- `GridOSKitTests`: first unit test bundle.

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

Phase 1 should introduce a real terminal through `TerminalCore` without letting SwiftTerm or any other backend leak directly into the app shell.

Target abstractions:

- `TerminalSession`
- `TerminalSessionController`
- `TerminalViewRepresentable`
- `TerminalProfile`
- `TerminalEvent`

## Phase 2 architecture target

Phase 2 should introduce `RenderCore` through a single Metal surface that can be hosted by the app without coupling terminal correctness to shader work.

Target abstractions:

- `VisualIdentity`
- `VisualMode`
- `ProceduralSeed`
- `RenderEvent`
- `MetalBackgroundView`

## Architecture rule

Every major feature should enter through a small module-owned API first. The app shell composes features; it should not become the place where terminal, rendering, metrics, and LLM details mix.
