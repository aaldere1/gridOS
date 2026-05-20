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

Phase 6 is now verified complete. The app has a generated Xcode project, a SwiftUI macOS shell, a SwiftTerm-backed local terminal, a Metal-backed visual identity layer, a terminal-first production frame, truthful native system metrics, three coherent aesthetic modes, and an opt-in `Command-K` Command Intelligence palette. Command Intelligence supports suggested commands, explain output, failed-command help, preview-before-send redaction, Anthropic provider setup, Keychain-backed API keys, local command-risk gates, insert-first command handling, no-key usability, and deterministic Debug smoke fixtures.

No production signing setup, release pipeline, updater, multi-pane/session management, deeper macOS integrations, performance hardening, or release-grade security/privacy hardening exists yet.

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
- Phase 4: real native system metrics for CPU, memory, disk, network, battery, thermal state, and top processes.
- Phase 5: aesthetic modes with public `VisualMode` registry, shared visual tokens, app-frame theming, mode-aware Metal renderer behavior, stable per-install variation, and verified terminal readability/focus safety.
- Phase 6: opt-in Command Intelligence with provider-neutral contracts, redacted context preview, local risk classification, Anthropic adapter, Keychain credential storage, Command-K palette UI, insert/run safety policy, and final verification evidence.

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
