# gridOS production roadmap

This roadmap began when gridOS was a planning-only repository. It is retained as
historical planning context and now points at the current production-direct
state. The product intent in `docs/vision.md` remains intact: a native Apple
Silicon sci-fi terminal that is beautiful, fast, useful, and meaningfully
Mac-first.

Current state as of 2026-06-15:

- XcodeGen project, generated Xcode project, module boundaries, tests, docs, and CI exist.
- Native shell, Metal identity, local system metrics, multi-pane workspaces, macOS integration foundations, and AI Command Helper are implemented.
- Version 1.0.6 build 14 is signed, notarized, stapled, Gatekeeper-assessed, launch-smoked, visually checked, and ready for the public GitHub release.
- Sparkle automatic updates are enabled for the direct-download lane; the manual DMG flow remains the fallback.
- The repository is public as source-available proprietary code, not open source.

## Production-ready definition

gridOS is production-ready when all of these are true:

1. A user can download, install, launch, update, and uninstall it without developer tooling.
2. The terminal is reliable enough for real daily command-line work.
3. The visual system is distinctive, performant, and stable on supported Macs.
4. System stats are real, explainable, and do not require unsafe privileges for normal operation.
5. LLM features are useful, opt-in, privacy-preserving, and gated before risky execution.
6. The app is signed, hardened, notarized, packaged, and tested on a clean Gatekeeper-enabled Mac.
7. Crash, logging, support, versioning, and update flows are ready before public launch.
8. The project has a clear license, attribution posture, and dependency compliance story.

## Guiding constraints

- Mac-only. No Electron, no Tauri, no cross-platform compromise layer.
- Apple Silicon first. Intel support is optional and should not slow the core product.
- Native shell correctness beats visual spectacle. A beautiful terminal that mishandles input, PTY resize, ANSI output, tmux, vim, SSH, or copy/paste is not ready.
- Metal is the identity layer, but not every pixel needs to be custom-rendered in v1 if that creates unnecessary risk.
- Plugin architecture should start as internal extension seams. Public third-party plugins are a post-stability feature unless a safe, signed, sandboxed model is proven early.
- Privacy is a product feature. Machine-derived visual signatures, local command context, shell history, and LLM requests all need explicit boundaries.

## Key product decisions to make first

These decisions should be closed before app scaffolding becomes expensive.

| Decision | Recommended default | Why |
|---|---|---|
| License | Source-available proprietary | The eDEX-UI inspiration is GPL-3.0, so do not copy code, assets, themes, or exact implementation details unless willing to inherit obligations. Public visibility does not grant open-source rights. |
| Distribution | Direct download with Developer ID, hardened runtime, notarization, signed DMG | Best fit for a power-user terminal app. Mac App Store sandboxing may constrain shell/system integration. |
| Minimum OS | macOS 14 initially, revisit before beta | Matches current README and keeps APIs modern. |
| CPU support | Apple Silicon required for alpha and beta | Preserves performance focus. Revisit Intel only if distribution needs it. |
| Terminal backend | Start with SwiftTerm behind an adapter | Gets to real terminal behavior quickly while preserving the option for a custom renderer later. |
| Visual renderer | MTKView-driven shader layer plus native controls where appropriate | Delivers the signature without blocking on custom text rendering in phase 1. |
| LLM provider | Provider abstraction, Anthropic first only if desired | Avoids baking one provider into product architecture. |
| Telemetry | Off by default or none for 1.0 | Fits privacy posture; use local diagnostics export instead. |

## Architecture target

### App shell

- SwiftUI app lifecycle with AppKit interop for window control, menu commands, keyboard routing, responder chain behavior, and advanced terminal focus.
- One main app target plus test targets.
- Prefer Swift Package Manager for dependencies where possible.
- Explicit modules:
  - `GridOSApp`: app lifecycle, windows, commands, settings.
  - `TerminalCore`: PTY sessions, terminal adapter, input/output, scrollback, profiles.
  - `RenderCore`: Metal view, shader pipelines, visual modes, procedural seed.
  - `SystemMetrics`: CPU, memory, disk, network, thermal, power, process sampling.
  - `CommandIntelligence`: LLM provider abstraction, context packer, command safety policy.
  - `Integrations`: menu bar, widgets, Quick Look, Spotlight, notifications.
  - `GridOSKit`: shared models, logging, configuration, persistence.

### Terminal core

The terminal is the foundation. Phase 1 should favor proven behavior over custom rendering ambition.

Required terminal behavior:

- Shell launch using the user's default shell.
- PTY lifecycle management, process cleanup, and resize propagation.
- ANSI color, cursor movement, alternate screen, mouse reporting, OSC sequences, bracketed paste.
- Reliable keyboard handling for control, option, command, function keys, IME, dead keys, and paste.
- Copy, paste, selection, find, scrollback, clear, reset, zoom.
- Works with `vim`, `nano`, `less`, `top`, `tmux`, `ssh`, `git`, package managers, and long-running command output.
- Session restoration policy defined explicitly: restore windows and working directories, not running processes, unless a future feature proves safe.

### Rendering and visual identity

The visual system should be layered:

1. Native terminal surface.
2. Metal background and environmental effects.
3. Metal panel decoration and activity effects.
4. Optional post-processing.
5. Only after stability: custom GPU text rendering experiment.

Rendering principles:

- `MTKView` owns animation timing and draw loops.
- Idle renderer throttles aggressively.
- Terminal input/output events can feed visual effects without blocking PTY throughput.
- All visual modes share a design-token layer: palette, typography, intensity, effect stack, motion profile.
- Procedural seed produces stable variation without exposing raw hardware IDs.

### Procedural identity

Implementation target:

- Generate a random install secret at first launch.
- Optionally mix in non-sensitive machine traits only after hashing.
- Store the secret in Keychain or app container.
- Derive visual seeds from `HMAC(appInstallSecret, modeIdentifier + versionedSalt)`.
- Provide a reset/regenerate identity action in settings.
- Never display or transmit raw seed material.

This keeps the emotional value of "my gridOS looks unique" while reducing fingerprinting risk.

### System metrics

Metrics must be accurate enough to trust and cheap enough to leave running.

Initial metrics:

- CPU usage per core and top processes.
- Memory pressure, physical memory, compressed memory, swap.
- Disk capacity and recent I/O rate.
- Network throughput and active interface.
- Battery, power source, thermal pressure where available.

Later metrics:

- Process tree visualization.
- Connection graph.
- GPU activity if stable public APIs or acceptable fallbacks exist.
- Flame graphs only after a sampling design is proven and permission impact is understood.

Avoid for v1:

- Kernel extensions.
- Root helper tools unless absolutely required.
- Packet capture as a default feature.
- Anything that causes scary permission prompts without a strong user benefit.

### LLM features

The LLM layer should be helpful but never surprising.

MVP:

- `Command-K` opens a command palette.
- User can ask for a suggested command.
- The app shows command, explanation, working directory, and risk label.
- User must explicitly insert or run the command.
- Destructive commands require a stronger confirmation path.
- API keys are stored in Keychain.
- No shell context leaves the machine unless the user invokes an LLM action.

Provider design:

- `LLMCommandProvider` protocol.
- `AnthropicCommandProvider` and `OpenAICommandProvider` exist behind the same contract; a local provider can be added later without changing the palette contract.
- Context packer redacts obvious secrets and gives the user visibility into what will be sent.
- No prompt, provider response, generated command, or transcript audit log is stored by default.

### macOS integrations

Prioritize integrations that make the app feel native without dragging v1 into platform edge cases.

V1 candidates:

- Menu bar extra with quick open, recent sessions, current shell status, and compact system stats.
- Standard macOS Settings window.
- Notification Center alerts for completed long-running commands.
- Keychain integration for API keys and optional SSH-related secrets.
- Spotlight indexing for saved sessions or command snippets only if data model is ready.

Defer unless easy:

- Quick Look terminal session previews.
- Widgets.
- Stage Manager special behavior beyond good standard window behavior.
- Touch Bar.
- Continuity and Universal Control awareness.

### Plugins

Do not expose public plugins until the host API, signing model, permissions, and crash isolation are designed.

V1-safe alternative:

- Build an internal panel provider protocol.
- Ship built-in panels using that protocol.
- Keep ABI/API private.
- Document the future public plugin requirements but do not promise compatibility.

Production plugin requirements before public release:

- Signed plugin packages.
- Versioned manifest.
- Permission declarations.
- Crash containment.
- Uninstall path.
- Clear support boundary.

## Roadmap

### Phase 0 - Product, legal, and repo foundation

Goal: turn the repo from an idea into a buildable product workspace.

Deliverables:

- Choose project license and add `LICENSE`.
- Add attribution/legal note for eDEX-UI inspiration.
- Keep macOS integration terminology consistent across docs and product copy.
- Create Xcode project or Swift Package workspace.
- Add app bundle ID, versioning scheme, signing placeholders, and entitlements files.
- Add `docs/architecture.md`, `docs/security-privacy.md`, and `docs/release.md` as living docs.
- Add CI skeleton for build, test, lint, and release dry run.

Acceptance criteria:

- Fresh clone can open and build a blank app.
- `README.md` explains setup accurately.
- No legal ambiguity around whether eDEX-UI code/assets are being reused.
- CI runs on every PR.

### Phase 1 - Native shell MVP

Goal: a boring but real macOS terminal app.

Deliverables:

- SwiftUI/AppKit window shell.
- Embedded terminal via `TerminalCore` adapter.
- Default shell launch.
- Basic terminal preferences: shell path, font size, cursor style, color preset.
- Copy/paste/select/find/clear/reset.
- Window tabs or single-window sessions, whichever is simpler.
- Basic logging and local diagnostics export.

Acceptance criteria:

- Works with `zsh`, `vim`, `less`, `top`, `ssh`, `tmux`, and fast command output.
- No crashes during a two-hour terminal session.
- PTY process exits cleanly when windows close.
- Input latency target is measured, even if not yet final.

### Phase 2 - Metal identity MVP

Goal: prove the product can feel special without compromising terminal reliability.

Deliverables:

- `RenderCore` with one `MTKView` background.
- Tron-inspired shader mode.
- Procedural install seed.
- Event bridge from terminal activity to subtle visual effects.
- Renderer frame pacing and idle throttling.
- Performance overlay available in debug builds.

Acceptance criteria:

- Terminal remains usable during heavy output.
- Renderer idles below target CPU budget on a quiet terminal.
- Cold start and RAM are measured on supported hardware.
- Visual seed is deterministic after reinstall only if identity is intentionally preserved; otherwise regenerated.

### Phase 3 - Production app frame

Goal: make the app feel like a coherent Mac product instead of a prototype.

Deliverables:

- Polished window chrome.
- Command menu, keyboard shortcuts, responder-chain cleanup.
- Settings screen.
- Profile model and persistence.
- Three-panel layout: terminal, system strip, activity/context panel.
- Accessibility pass for labels, focus, contrast, reduced motion.
- Crash-safe state restoration.

Acceptance criteria:

- App feels native in full screen, windowed mode, and multiple displays.
- Keyboard shortcuts do not fight shell shortcuts.
- Reduced motion has a meaningful effect.
- App recovers cleanly after force quit.

### Phase 4 - Real system metrics

Goal: replace decorative panels with truthful, useful instrumentation.

Deliverables:

- `SystemMetrics` sampler service.
- CPU, memory, disk, network, battery, thermal data.
- Top process panel.
- Metrics sampling budget and backpressure.
- User-facing explanation for unavailable metrics.

Acceptance criteria:

- Metrics match Activity Monitor closely enough for normal use.
- Metrics sampling does not materially increase idle CPU.
- No root permissions required for normal metrics.
- Panels degrade gracefully when APIs are unavailable.

### Phase 5 - Aesthetic modes

Goal: prove gridOS is a visual system, not a single theme.

Deliverables:

- Mode registry and shared visual token model.
- Tron, Severance, and Apple-native modes.
- Mode switcher via `Command-Shift-M`.
- Motion/effect profiles per mode.
- Per-mode procedural variation.

Acceptance criteria:

- Three screenshots from the same app are visibly different by mode.
- Three installs in the same mode are subtly but visibly distinct.
- Apple-native mode is calm enough for real work.
- Visual effects never obscure terminal text.

### Phase 6 - LLM command palette

Goal: useful AI assistance without turning the terminal into an unsafe agent runner.

Deliverables:

- `Command-K` command palette.
- Provider abstraction.
- API key setup stored in Keychain.
- Suggested command flow with explanation and insert/run choices.
- Selected output explain flow.
- Failed command explain/fix flow.
- Risk classifier and confirmation policy.
- Secret redaction pass for context payloads.

Acceptance criteria:

- No context is sent without explicit user action.
- Destructive generated commands require confirmation.
- User can inspect what context will be sent.
- LLM failure states are human-readable.
- App remains fully usable without configuring an LLM provider.

### Phase 7 - Multi-pane and session management

Goal: make gridOS useful for real developer workflows beyond a single shell.

Deliverables:

- Split panes.
- Pane focus, resize, close, duplicate.
- Drag panes within a window.
- Session profiles.
- Recent directories and commands.
- Optional project/workspace launcher.

Acceptance criteria:

- Pane operations are keyboard-accessible.
- Shell processes are not leaked after pane close.
- Session model survives relaunch.
- Layout remains readable on laptop and external display sizes.

### Phase 8 - macOS integrations

Goal: earn the "Mac-first" claim.

Deliverables:

- Menu bar extra.
- Long-command completion notifications.
- Keychain-backed secrets.
- Spotlight indexing if saved sessions/snippets are implemented.
- Quick Look preview only if session file format exists.

Acceptance criteria:

- Menu bar extra works when main window is closed.
- Notifications are useful and not noisy.
- Secrets never appear in logs.
- Integrations can be disabled.

### Phase 9 - Performance hardening

Goal: hit the numbers that justify the native rewrite.

Deliverables:

- Repeatable benchmark suite.
- Cold start measurement.
- Memory baseline measurement.
- Idle CPU measurement.
- Input latency measurement.
- Heavy output stress test.
- ProMotion frame pacing test.
- Instruments profiles checked into release evidence.

Targets:

- Resident RAM under 100 MB for basic terminal plus one visual mode, or documented exception with mitigation plan.
- Cold start under 500 ms on target Apple Silicon hardware.
- Idle CPU under 0.5% with quiet terminal and effects throttled.
- Sustained smooth animation where hardware supports it.
- Terminal input latency close to Ghostty/iTerm-class behavior.

Acceptance criteria:

- Every performance target has a measured report, not an estimate.
- Any miss has an owner and a release-blocking decision.

### Phase 10 - Security and privacy hardening

Goal: make a terminal-plus-LLM app trustworthy.

Deliverables:

- Threat model.
- Privacy policy.
- Local data inventory.
- Secret redaction tests.
- Keychain access tests.
- Command risk policy tests.
- Hardened runtime compatibility pass.
- Dependency license and vulnerability review.

Acceptance criteria:

- No API keys, shell history, prompts, or selected terminal output are logged accidentally.
- LLM network requests are observable to the user before they happen.
- Dangerous command path has tests.
- Dependency license posture is known and documented.

### Phase 11 - Alpha

Goal: internal daily-driver trial.

Deliverables:

- Signed internal builds.
- Alpha release notes.
- Known issues doc.
- Feedback template.
- Crash/log export flow.
- 10-20 real workflows tested.

Acceptance criteria:

- At least one developer uses it for real work for a week.
- No data loss or shell correctness blockers.
- Top 10 crashes and hangs are resolved or understood.
- The app has a clear "why I would open this instead of Terminal" moment.

### Phase 12 - Beta

Goal: external trust and installability.

Deliverables:

- Developer ID signed build.
- Hardened runtime enabled.
- Notarized DMG or ZIP distribution.
- Sparkle or equivalent update mechanism, if direct distribution is chosen.
- Onboarding and first-run privacy disclosures.
- Support email/site.
- Public landing page.

Acceptance criteria:

- Clean Mac download/install/launch passes with Gatekeeper enabled.
- Update flow works from beta N to beta N+1.
- First-run setup is understandable without docs.
- Beta users can report diagnostics without exposing secrets.

### Phase 13 - 1.0 release candidate

Goal: stop adding features and prove release quality.

Deliverables:

- Complete release checklist.
- Full regression pass.
- Accessibility pass.
- Security/privacy signoff.
- Performance signoff.
- License/dependency signoff.
- Marketing screenshots generated from multiple procedural identities.
- Final notarized artifact.

Acceptance criteria:

- No known critical or high-severity issues.
- No release-blocking performance misses.
- No unsigned, unnotarized, or untracked release artifacts.
- Clean install, upgrade, and uninstall tested.
- Support and rollback process are ready.

### Phase 14 - Production launch

Goal: ship and operate.

Deliverables:

- Public download.
- Checksums.
- Release notes.
- Update feed live.
- Support docs.
- Known issues.
- Crash intake process.
- Post-launch hotfix branch process.

Acceptance criteria:

- Users can install without bypassing Gatekeeper.
- Update feed can deliver a hotfix.
- Crash/support reports can be triaged.
- Website, README, and app version all agree.

## Testing strategy

### Unit tests

- Procedural seed determinism.
- Visual token generation.
- Settings persistence.
- Command risk classification.
- Secret redaction.
- LLM provider request shaping.
- Metrics normalization.

### Integration tests

- PTY lifecycle.
- Shell launch and exit.
- Resize propagation.
- ANSI/OSC handling through selected terminal backend.
- Keychain read/write.
- Settings migration.
- Update feed parsing.

### UI tests

- First launch.
- New session.
- Split pane.
- Mode switch.
- Command palette.
- Settings.
- Reduced motion.
- Menu bar extra.

### Manual test matrix

- Apple Silicon laptop.
- Apple Silicon desktop if available.
- Multiple external display configurations.
- Full screen and Stage Manager.
- Fresh macOS user account.
- Clean Gatekeeper-enabled Mac.
- Offline mode.
- No LLM key configured.
- Long-running commands.
- Heavy terminal output.
- SSH and tmux sessions.

## Release checklist

Every release candidate needs evidence for:

- Version and build number incremented.
- Clean git tag.
- Dependencies reviewed.
- Tests passing.
- Benchmarks captured.
- App archived from clean checkout.
- Hardened runtime enabled.
- Code signature verified.
- Notarization accepted.
- Stapling verified if using a stapled package.
- Gatekeeper launch tested from quarantined download.
- Update feed tested.
- Checksums generated.
- Release notes written.
- Rollback path documented.

## Major risks and mitigations

| Risk | Why it matters | Mitigation |
|---|---|---|
| Terminal correctness takes longer than visuals | Users will forgive fewer effects before they forgive broken shell behavior | Use SwiftTerm first, isolate adapter, test real TUI apps early. |
| Metal renderer hurts idle CPU | The native rewrite is justified by performance | Build idle throttling and benchmarks in Phase 2. |
| Custom GPU text rendering becomes a trap | It can consume months | Treat it as a later experiment, not a Phase 1 dependency. |
| Machine-derived identity becomes fingerprinting | Privacy risk and user trust issue | Use install secret, hash/HMAC, reset option, no telemetry. |
| LLM feature feels unsafe | Terminal agents can do real damage | Insert-first default, risk labels, confirmation gates, context preview. |
| macOS sandbox blocks expected shell/system behavior | App Store rules may conflict with terminal use cases | Prefer direct Developer ID distribution first. Revisit Mac App Store later. |
| Plugin API destabilizes v1 | Public extension contracts are expensive | Keep plugin seams internal until after 1.0. |
| eDEX-UI inspiration creates license confusion | eDEX-UI is GPL-3.0 | From-scratch only, no copied code/assets/themes, explicit attribution. |

## Staffing and timeline reality

Solo senior engineer:

- Usable alpha: 8-12 weeks if scope stays tight.
- Credible beta: 4-6 months.
- Production 1.0: 6-12 months depending on terminal correctness, visuals, and release polish.

Small focused team:

- App/terminal engineer.
- Metal/graphics engineer.
- macOS systems engineer.
- Product/design engineer.

With that team, a serious 1.0 could plausibly land in 4-6 months if plugin support and advanced metrics are deferred.

## Recommended immediate next steps

1. Close license/distribution decisions.
2. Scaffold the Xcode project and CI.
3. Build a boring terminal MVP.
4. Add one Metal background shader behind it.
5. Add benchmark harness before adding more features.
6. Use the app for real shell work before investing in LLM, plugins, or advanced panels.

## External references checked

- Apple Xcode documentation: direct Mac distribution requires Developer ID signing for identified-developer launch behavior and hardened runtime for notarization: https://help.apple.com/xcode/mac/current/en.lproj/dev033e997ca.html
- Apple Developer documentation: notarization is the expected process for Developer ID-signed software distributed outside the Mac App Store: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- Apple Developer documentation: Mac App Store distribution requires App Sandbox: https://developer.apple.com/documentation/security/app-sandbox
- eDEX-UI repository: archived upstream inspiration, GPL-3.0 license, and original feature surface: https://github.com/GitSquared/edex-ui
