# gridOS project context

## Product

gridOS is a native macOS app for Apple Silicon that reimagines eDEX-UI as a serious Mac-first terminal and system cockpit.

The product promise is:

- real terminal usability first
- distinctive Metal-powered visual identity
- truthful system metrics
- opt-in LLM help that is explainable and gated
- direct Mac distribution with professional signing, notarization, update, and support flows

## Current state

The repository began as planning-only documentation:

- `README.md`
- `docs/vision.md`
- `docs/production-roadmap.md`

Phase 3 is now complete. The app has a generated Xcode project, a SwiftUI macOS shell, a SwiftTerm-backed local terminal, a first Metal-backed visual identity layer that reacts to coarse terminal activity while idling after short render bursts, and a terminal-first production frame with persisted settings, window autosave, reduced-motion-aware rendering, menu-visible terminal commands, and accessibility coverage.

No production signing setup, release pipeline, updater, metrics panels, or LLM command help exists yet.

## Build approach

Use XcodeGen as the source of truth for the Xcode project. Commit `project.yml` and generated source files. The `.xcodeproj` can be regenerated deterministically.

Initial architecture:

- `GridOSApp`: macOS app target and app shell.
- `GridOSKit`: shared models and state.
- `TerminalCore`: PTY and terminal abstraction.
- `RenderCore`: Metal visual identity layer.
- `SystemMetrics`: system sampler abstraction.
- `CommandIntelligence`: LLM provider and command safety abstraction.

Validated implementation so far:

- Phase 0: project scaffold, module boundaries, CI skeleton, and docs.
- Phase 1: native local shell MVP behind `TerminalCore`.
- Phase 2: Metal identity MVP behind `RenderCore`.
- Phase 3: production app frame with persisted preferences, window autosave, terminal-safe commands, reduced motion, and accessibility coverage.

## Non-negotiables

- Do not copy eDEX-UI code, assets, or exact theme files.
- Terminal correctness beats visual effects.
- Privacy defaults must be conservative.
- App must remain useful without an LLM provider configured.
- Release readiness requires signed, hardened, notarized, Gatekeeper-tested artifacts.

## Reference docs

- `docs/vision.md`
- `docs/production-roadmap.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
