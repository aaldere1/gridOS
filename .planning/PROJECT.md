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

No production app source, Xcode project, CI, signing setup, or release pipeline existed at the start of implementation.

## Build approach

Use XcodeGen as the source of truth for the Xcode project. Commit `project.yml` and generated source files. The `.xcodeproj` can be regenerated deterministically.

Initial architecture:

- `GridOSApp`: macOS app target and app shell.
- `GridOSKit`: shared models and state.
- `TerminalCore`: PTY and terminal abstraction.
- `RenderCore`: Metal visual identity layer.
- `SystemMetrics`: system sampler abstraction.
- `CommandIntelligence`: LLM provider and command safety abstraction.

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
