---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: Production direct 1.0.6 artifact complete; Sparkle updates added; public GitHub release in progress
last_updated: "2026-06-15T21:05:00Z"
progress:
  total_phases: 15
  completed_phases: 12
  total_plans: 43
  completed_plans: 43
---

# gridOS state

## Active phase

Phase 14 - Production direct 1.0.6 and public GitHub release readiness

## Current status

gridOS is now on production direct version 1.0.6 build 14. App Store readiness remains paused while the direct product is distributed and tested. The versioned artifact is `build/release/production/gridOS-1.0.6-14-edda1ee.dmg`, SHA-256 `cf6e01770e43b94783fefa25493da01f2471b961280334f63fe804568a1fe9c1`; it is app-signed, DMG-signed, notarized, stapled, Gatekeeper-assessed, strict codesign-verified, launch-smoked from the DMG, visibly versioned as `v1.0.6`, visually inspected, performance-gated, and prepared for GitHub release `v1.0.6`. Version 1.0.6 adds the new app icon, username-free README screenshots, Sparkle automatic updates for the direct-download lane, and signed Sparkle helper binaries with secure timestamps while preserving the 1.0.5 AI Command Helper and Settings polish. The GitHub repository remains public as source-available proprietary code. Separate clean-Mac Finder/Gatekeeper install proof and Sparkle update proof from 1.0.6 to the next release remain external validation tasks.

## Decisions made

- Use XcodeGen for deterministic Xcode project generation.
- Start with direct Developer ID distribution as the likely production path.
- Keep App Store distribution as a later evaluation because sandboxing may constrain terminal/system features.
- Start with SwiftTerm behind an adapter once TerminalCore begins.
- Treat public plugins and custom GPU text rendering as post-stability work, not initial blockers.
- Use a conservative proprietary license posture during private alpha unless changed before public release.
- Keep `project.yml` authoritative for Xcode project structure.
- Keep SwiftTerm isolated inside `TerminalCore`; `GridOSApp` should consume `TerminalSurface`, `TerminalSessionConfiguration`, and `TerminalCommandCenter` only.
- Keep Metal rendering isolated inside `RenderCore`; `TerminalCore` emits coarse activity events and does not depend on rendering code.
- Keep the Phase 2 renderer burst-driven so idle CPU stays quiet before heavier visual systems are added.
- Persist Phase 3 app-frame preferences with shared `@AppStorage` keys and test pure defaults/clamping through `GridOSKit.GridOSAppPreferences`.
- Use AppKit `setFrameAutosaveName("gridOS.main")` through an invisible SwiftUI bridge rather than custom window-state serialization.
- Combine the app reduced-motion setting with the system `accessibilityReduceMotion` environment before driving `RenderCore.VisualEffectConfiguration`.
- Keep native system sampling inside `SystemMetrics`; `GridOSApp` consumes `SystemMetricsSnapshot` through `SystemMetricsSampler`.
- Treat battery, thermal, network idle, and process-data absence as normal snapshot states with explicit copy instead of errors.
- For Phase 5, ship exactly the roadmap modes: Tron, Severance, and Apple-native; defer Cyberpunk and Matrix.
- Keep aesthetic modes as coherent visual systems, not color swaps, but do not replace SwiftTerm rendering or obscure terminal/metrics text.
- Use `Command-Shift-M` as the required native mode switcher and persist selected mode locally with existing app preference patterns.
- Make procedural variation stable per install and subtle within each mode.
- [Phase 05-aesthetic-modes]: Expose exactly Tron, Severance, and Apple-native as public VisualMode cases, with Tron as the default.
- [Phase 05-aesthetic-modes]: Keep GridOSKit preference helpers string-only so RenderCore remains downstream of GridOSKit.
- [Phase 05-aesthetic-modes]: Namespace install-derived visual seeds as gridOS.visual.v1.<installSeed>.<mode> for stable per-install variation.
- [Phase 05-aesthetic-modes]: Compose global visual intensity and reduced-motion settings with per-mode motion profiles instead of replacing the existing scalar contract.
- [Phase 05-aesthetic-modes]: Generate the stable local install seed in RootView on first launch, using a bootstrap fallback only until AppStorage is populated.
- [Phase 05-aesthetic-modes]: Use a separate AppearanceCommands type so Command-Shift-M changes only the visual mode preference and never routes through TerminalCommandCenter.
- [Phase 05-aesthetic-modes]: Preserve the install seed during Settings reset while restoring the selected visual mode to Tron.
- [Phase 05-aesthetic-modes]: Thread VisualTheme through existing SwiftUI frame components so mode styling does not change terminal layout geometry.
- [Phase 05-aesthetic-modes]: Keep the Metal renderer burst-driven and reuse the existing animation timer instead of adding a mode-specific or global timer.
- [Phase 05-aesthetic-modes]: Use identity.seed.normalizedVector in each shader mode branch so per-install variation is stable and mode-visible.
- [Phase 06-llm-command-palette]: Keep command intelligence opt-in, one-shot, and insert-first; no autonomous shell agent or persistent chat surface in Phase 6.
- [Phase 06-llm-command-palette]: Show a context preview and redactions before every provider request; send no shell context without explicit user action.
- [Phase 06-llm-command-palette]: Store provider API keys in Keychain and treat no-key configuration as a normal disabled state.
- [Phase 06-llm-command-palette]: Default to Anthropic/Claude if Phase 6 implements one live hosted provider, while preserving a provider abstraction for future OpenAI/local adapters.
- [Phase 06-llm-command-palette]: Keep provider requests typed around ApprovedCommandContextPayload so providers cannot receive raw CommandAssistanceInput.
- [Phase 06-llm-command-palette]: Keep credential access async from the first contract slice so Keychain-backed storage can be added without blocking SwiftUI.
- [Phase 06-llm-command-palette]: Map all provider/network/parser failures to product-level copy before UI rendering.
- [Phase 06-llm-command-palette]: Use deterministic local pattern rules as the command execution authority; provider labels remain advisory.
- [Phase 06-llm-command-palette]: Map high-risk and unknown commands to insertOnly so they cannot silently run.
- [Phase 06-llm-command-palette]: Treat local project mutations such as git add/git commit as medium-risk and requiring confirmation.
- [Phase 06-llm-command-palette]: Redact every included context block before constructing CommandContextPreview.approvedPayload.
- [Phase 06-llm-command-palette]: Treat private key blocks as redacted but blocked, making canSend false until the user edits context.
- [Phase 06-llm-command-palette]: Keep LLMCommandRequest construction dependent on ApprovedCommandContextPayload rather than raw CommandAssistanceInput.
- [Phase 06-llm-command-palette]: Use direct Anthropic Messages API calls with Foundation URLSession and no provider SDK dependency.
- [Phase 06-llm-command-palette]: Store provider API keys only in Keychain generic-password items under com.aaldere1.gridos.command-intelligence.
- [Phase 06-llm-command-palette]: Persist only provider and model IDs through GridOSKit/AppStorage; API keys, prompts, generated commands, and responses are not preference data.
- [Phase 06-llm-command-palette]: Keep terminal selected text, insert, run, and focus access inside TerminalCore.TerminalInteractionController so GridOSApp never imports SwiftTerm.
- [Phase 06-llm-command-palette]: Use CommandIntelligenceCommandCenter notifications for Command-K and Settings routing instead of binding app commands directly to view state.
- [Phase 06-llm-command-palette]: Keep Send Request behind a preview-approved injected closure until Plan 06-06 wires provider orchestration.
- [Phase 06-llm-command-palette]: Use CommandIntelligenceService as the provider orchestration boundary after preview approval.
- [Phase 06-llm-command-palette]: Keep DebugCommandIntelligenceFixtureProvider DEBUG-gated and launch-argument selected so smoke never needs a live Anthropic key.
- [Phase 06-llm-command-palette]: Treat CommandRiskClassifier as the local execution-policy authority; provider risk labels are advisory.
- [Phase 06-llm-command-palette]: Auto-approve the final human-verify checkpoint in workflow auto mode while recording manual smoke steps and noninteractive fixture evidence.
- [Phase 07-multi-pane-session-management]: Add multi-pane support inside the existing primary gridOS window rather than starting with a full tabs/windows overhaul.
- [Phase 07-multi-pane-session-management]: Route Terminal menu actions, focus restoration, and Command Intelligence selected-text/insert/run behavior to the active pane only.
- [Phase 07-multi-pane-session-management]: Restore layout, active pane, profile metadata, and last known working directories on relaunch, but never attempt to resurrect running shell processes.
- [Phase 07-multi-pane-session-management]: Treat pane close/app quit process cleanup as a required evidence item; no orphaned shell processes after pane close or app quit.
- [Phase 08-macos-integrations]: Implement the menu bar extra as a lightweight companion to the normal gridOS window, not a menu-bar-only replacement app.
- [Phase 08-macos-integrations]: Keep notification permission explicit and local-only; do not prompt on first launch.
- [Phase 08-macos-integrations]: Generalize reusable Keychain primitives in GridOSKit while keeping API keys out of AppStorage/UserDefaults/logs/snapshots/notifications/indexing.
- [Phase 08-macos-integrations]: Treat Spotlight/preview work as optional metadata-only foundation; do not index terminal output, command history, prompts, secrets, environment variables, process args, or full paths.
- [Phase 08-macos-integrations]: Defer Quick Look/Finder preview work until gridOS has a stable saved workspace document type.
- [Phase 08-macos-integrations]: Keep deterministic DEBUG smoke markers sanitized and independent of terminal screenshots.
- [Phase 09-performance-hardening]: Start with repeatable measurements and evidence before optimizing.
- [Phase 09-performance-hardening]: Use roadmap targets as the scorecard; any miss must be documented with owner, severity, likely cause, and mitigation.
- [Phase 09-performance-hardening]: Keep benchmark evidence synthetic and privacy-safe; do not capture real shell history, private output, environment variables, or screenshots containing user content.
- [Phase 09-performance-hardening]: Prefer targeted module-owned fixes over broad rewrites, preserving Phase 1-8 terminal, privacy, metrics, visual, Command Intelligence, and integration guarantees.
- [Phase 09-performance-hardening]: Use `/usr/bin/perl -MTime::HiRes=time` or app-side marker timestamps for sub-second benchmark timing; do not rely on `date +%s%N` on macOS.
- [Phase 09-performance-hardening]: Commit benchmark summaries and small sanitized exports by default; do not commit large/raw `.trace` bundles unless intentionally scrubbed and size-acceptable.
- [Phase 09-performance-hardening]: Treat terminal input latency as a documented controller-to-PTY marker proxy until deeper accessibility or rendering instrumentation is justified.
- [Phase 11-alpha]: Treat missing local Apple signing configuration as an explicit `SIGNING_BLOCKED` alpha blocker, not a false pass or generic build failure.
- [Phase 11-alpha]: Keep Developer ID notarization, stapling, public distribution packaging, and clean-Mac Gatekeeper proof deferred to Phase 12 Beta unless Phase 11 exposes an earlier blocker.
- [Phase 11-alpha]: Commit sanitized text evidence only; do not commit `.app`, `.xcarchive`, `.dmg`, `.zip`, `.pkg`, `.trace`, screenshots, shell history, terminal transcripts, environment dumps, API keys, prompts, generated commands, raw terminal output, or user-specific paths.
- [Phase 11-alpha]: Critical or high-severity terminal correctness issues block Alpha signoff.
- [Phase 11-alpha]: Signing readiness evidence is presence-only: missing local Apple configuration is recorded as SIGNING_BLOCKED without printing private values.
- [Phase 11-alpha]: Alpha evidence remains text-only and sanitized; build artifacts, traces, screenshots, terminal transcripts, raw output, prompts, generated commands, API keys, environment variables, and user-specific paths stay out of source control.
- [Phase 11-alpha]: High-severity terminal correctness blockers prevent Alpha completion.
- [Phase 11-alpha]: Alpha artifacts are written only to local output directories; committed evidence remains sanitized text.
- [Phase 11-alpha]: Missing signing prerequisites stop in signing preflight before archive creation.
- [Phase 11-alpha]: Artifact verification records codesign, checksum, bundle metadata, pass/fail status, and Phase 12 notarization deferral.
- [Phase 11-alpha]: DEBUG alpha smoke uses deterministic /tmp marker files and never records terminal transcripts, selected output, prompts, generated commands, environment variables, or shell history.
- [Phase 11-alpha]: Daily-driver UAT separates manual interactive terminal checks from a sanitized noninteractive command-availability helper.
- [Phase 11-alpha]: The generated Xcode project is regenerated from project.yml when new GridOSApp source files are added.
- [Phase 11-alpha]: Critical/high terminal correctness issues block Alpha signoff through the known-issues triage loop.
- [Phase 11-alpha]: Phase 11 diagnostics remain local and sanitized; telemetry, crash reporting, automatic diagnostics upload, and support portal functionality are deferred.
- [Phase 11-alpha]: Diagnostics source gating scans Phase 11 docs, evidence policy, and scripts while excluding generated artifacts.
- [Phase 11-alpha]: Final Alpha verification passed only after signing inputs, signed artifact verification, signed-artifact daily-driver UAT, known issues, diagnostics, and privacy gates were coherent.
- [Phase 11-alpha]: MenuBarExtra is disabled for Alpha after a signed-app launch loop in SwiftUI's status-item scene; re-enable only after the scene can launch without beachballing.
- [Phase 11-alpha]: Controller-owned terminal views are reused across SwiftUI split layout rebuilds so pane reconstruction does not spawn duplicate shell processes.

## Decisions still open

- Whether to change from source-available proprietary to an open-source license.
- Final bundle identifier and signing team.
- Whether Intel Macs are supported after beta.
- Final provider availability for alpha after Phase 6 implementation and credential readiness.
- Whether Sparkle should remain the long-term direct-distribution updater after 1.0.6 field proof.

## Progress log

- 2026-05-19: Cloned repository and reviewed current planning-only state.
- 2026-05-19: Added `docs/production-roadmap.md` and linked it from `README.md`.
- 2026-05-19: Corrected `docs/vision.md` terminology from "Macros integration" to "macOS integration".
- 2026-05-19: Began Phase 0 with repo-local planning state.
- 2026-05-19: Added proprietary private-alpha license posture in `LICENSE`.
- 2026-05-19: Added XcodeGen scaffold, blank SwiftUI macOS app, framework module boundaries, initial unit tests, architecture/security/release docs, and CI skeleton.
- 2026-05-19: Generated `gridOS.xcodeproj`.
- 2026-05-19: Verified `xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build test` passed with 2 tests.
- 2026-05-19: Normalized phase directories to GSD-compatible `00-foundation` and `01-native-shell-mvp`.
- 2026-05-19: Added SwiftTerm `1.13.0` through XcodeGen/SwiftPM and embedded a real local shell in the app via `TerminalCore.TerminalSurface`.
- 2026-05-19: Added terminal command routing for copy, paste, clear, and reset.
- 2026-05-19: Added terminal profile placeholders in Settings and startup-command support for repeatable smoke verification.
- 2026-05-19: Verified `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` passed with 8 tests.
- 2026-05-19: Launch-smoke verified `gridOS.app` starts, creates a `-zsh` child, accepts keyboard input after window activation/click, and cleans up after `exit`.
- 2026-05-19: PTY smoke verified `vim --version`, `less --version`, `ssh -V`, `tmux -V`, `top -l 1 -n 0`, and a 1000-line fast-output burst through the app startup command path.
- 2026-05-20: Created the Phase 2 GSD execution plan because the roadmap had Phase 2 active but no phase directory yet.
- 2026-05-20: Added `RenderCore` visual identity types, deterministic procedural seeds, render events, and a Metal-backed `MetalBackgroundView`.
- 2026-05-20: Added coarse terminal activity events in `TerminalCore` and bridged them to render pulses in `GridOSApp`.
- 2026-05-20: Added `RenderCoreTests`, including Metal shader compilation when a device is available.
- 2026-05-20: Verified `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` passed with 13 unit tests.
- 2026-05-20: Launch-smoke verified `GRIDOS_PHASE2_SMOKE`, shell exit, clean app quit, and a post-burst app CPU sample of `0.0`.
- 2026-05-20: Added `GridOSAppPreferences` with tests for shell fallback, font-size clamping, visual-intensity clamping, and reduced-motion storage.
- 2026-05-20: Added `VisualEffectConfiguration` and threaded reduced-motion/intensity into the Metal background pulse path.
- 2026-05-20: Added `WindowFrameController` to configure hidden-titlebar chrome, minimum size, and `gridOS.main` frame autosave.
- 2026-05-20: Refactored `RootView` into a terminal-first app frame with header, system strip, activity panel, and dominant terminal workspace.
- 2026-05-20: Replaced Settings placeholders with persisted Terminal, Appearance, and Recovery controls.
- 2026-05-20: Hardened the terminal command menu as an explicit `TerminalCommands` type while preserving SwiftTerm focus behavior.
- 2026-05-20: Verified Phase 3 final automated gate: `xcodegen generate --use-cache`, `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`, and `git diff --check` passed.
- 2026-05-20: Launch-smoke verified `GRIDOS_PHASE3_SMOKE` written to `/tmp/gridos-phase3-smoke.txt` through the app startup command path and the Debug app quit cleanly.
- 2026-05-20: Phase 3 verification passed with 3/3 key links verified and no blocking gaps.
- 2026-05-20: Scaffolded Phase 4 directory and captured context for real system metrics, including metric truth, sampling budget, app-frame display, privacy, unavailable states, and verification direction.
- 2026-05-20: Researched Phase 4 native macOS metric APIs, added validation and UI design contracts, and created executable plan `.planning/phases/04-real-system-metrics/04-01-PLAN.md`.
- 2026-05-20: Added `SystemMetricsTests`, `SystemMetricAvailability`, `SystemMetricsSnapshot`, and model coverage for available, stale, unavailable, and graceful copy states.
- 2026-05-20: Added `SystemMetricsSamplingPolicy` plus deterministic CPU, network, and top-process delta tests.
- 2026-05-20: Added `NativeSystemMetricsProvider` using Mach, Foundation volume keys, `getifaddrs`, IOKit power sources, `ProcessInfo.thermalState`, and libproc without shelling out.
- 2026-05-20: Added `SystemMetricsSampler`, `LiveSystemMetricsSampler`, and deterministic preview snapshot data.
- 2026-05-20: Wired `RootView` to consume `SystemMetricsSnapshot` in `SystemStripView(snapshot:)` and `ActivityContextPanel(snapshot:)` with read-only top-process display.
- 2026-05-20: Verified Phase 4 final automated gate: `xcodegen generate --use-cache`, `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`, `git diff --check`, source `rg` checks, and key-link verification passed.
- 2026-05-20: Launch-smoke verified `GRIDOS_PHASE4_SMOKE` written to `/tmp/gridos-phase4-smoke.txt` through the app startup command path and the Debug app quit cleanly through LaunchServices.
- 2026-05-20: Scaffolded Phase 5 directory and captured context for aesthetic modes, including mode taste, switching/persistence, app-frame theming scope, terminal protection, motion profiles, procedural variation, and deferred visual ideas.
- 2026-05-20: Executed Phase 5 Plan 01 with TDD coverage for the public visual mode registry, exact mode token bundles, deterministic install-derived seeds, reduced-motion pulse suppression, and GridOSKit raw preference validation.
- 2026-05-20: Verified Phase 5 Plan 01 final automated gate: `xcodegen generate --use-cache`, `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`, required `rg` source checks, and `git diff --check` passed.
- 2026-05-20: Executed Phase 5 Plan 02 with AppStorage-backed visual identity composition, first-launch install seed creation, a native Appearance menu `Command-Shift-M` mode switcher, and a Settings picker for Tron, Severance, and Apple-native.
- 2026-05-20: Verified Phase 5 Plan 02 final automated gate: `xcodegen generate --use-cache`, `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`, required `rg` source checks, and `git diff --check` passed.
- 2026-05-20: Executed Phase 5 Plan 03 with token-driven app-frame styling, mode-aware Metal shader branches, seed uniforms in every mode branch, and reduced-motion-preserving pulse behavior.
- 2026-05-20: Verified Phase 5 Plan 03 final automated gate: `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`, required `rg` source checks, and `git diff --check` passed.
- 2026-05-20: Executed Phase 5 Plan 04 Task 01 by adding `.planning/phases/05-aesthetic-modes/capture-mode-evidence.sh` and `.planning/phases/05-aesthetic-modes/evidence/README.md` for shared-seed mode screenshots, same-mode install variation, and terminal-focus smoke documentation.
- 2026-05-20: Verified Phase 5 Plan 04 automated gate: `xcodegen generate --use-cache`, `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`, `git diff --check`, and required source `rg` checks passed.
- 2026-05-20: Ran `.planning/phases/05-aesthetic-modes/capture-mode-evidence.sh`; `tron.png`, `severance.png`, `apple-native.png`, `tron-install-a.png`, `tron-install-b.png`, and `tron-install-c.png` were produced and reported as 5120x2880 PNGs by `sips`.
- 2026-05-20: Phase 5 Plan 04 visual review approved the app-window isolated screenshots: Tron, Severance, and Apple-native are visibly distinct with the shared seed; terminal and metrics remain readable; deferred surfaces are absent; and Tron install variants A/B/C are subtly distinct without hurting readability.
- 2026-05-20: Live Command-Shift-M terminal-focus smoke passed from `appearance.visualMode=tron` and install seed `phase5-focus-smoke`; the app cycled `severance -> appleNative -> tron`, accepted shell input after each switch, created `/tmp/gridos_phase5_focus_before`, `/tmp/gridos_phase5_focus_after_1`, `/tmp/gridos_phase5_focus_after_2`, and `/tmp/gridos_phase5_focus_after_3`, and captured `.planning/phases/05-aesthetic-modes/evidence/focus-smoke-command-shift-m.png`.
- 2026-05-20: Final Phase 5 Plan 04 completion checks passed: `sips -g pixelWidth -g pixelHeight .planning/phases/05-aesthetic-modes/evidence/*.png` reported all seven evidence images at `3104x2024`, and `git diff --check` passed. Earlier full `xcodegen generate --use-cache` and `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` evidence from the checkpoint remains the full build/test gate for this plan.
- 2026-05-20: Executed Phase 06 Plan 01 with CommandIntelligence contracts, approved preview payloads, credential store abstraction, failure copy, and `CommandIntelligenceTests`.
- 2026-05-20: Executed Phase 06 Plan 02 with deterministic secret redaction, redacted context preview construction, and `SecretRedactorTests`/`CommandContextPreviewTests`.
- 2026-05-20: Executed Phase 06 Plan 03 with deterministic command risk classification, insert-only high/unknown run policy, and `CommandRiskClassifierTests`.
- 2026-05-20: Executed Phase 06 Plan 04 with the Anthropic Messages provider, Keychain credential storage, non-secret provider/model preferences, and Command Intelligence Settings setup.
- 2026-05-20: Executed Phase 06 Plan 05 with `TerminalInteractionController`, Command-K palette overlay, Command-Option-K Terminal Clear, Settings focus routing, and preview-before-send gating.
- 2026-05-20: Began Phase 06 Plan 06 with provider result orchestration, deterministic smoke fixture support, local insert/run policy wiring, and final evidence docs.
- 2026-05-20: Phase 06 Plan 06 final automated gate passed; Debug fixture launch without a live Anthropic key passed; human-verify checkpoint auto-approved by workflow auto-advance.
- 2026-05-20: Phase 06 verification passed with 13/13 must-haves verified; orchestrator reran the full automated gate, proved the Debug fixture launch, opened the Command-K palette with UI automation, and committed `06-VERIFICATION.md`.
- 2026-05-20: Phase 06 marked complete; Phase 07 multi-pane and session management is next.
- 2026-05-20: Phase 07 context gathered for multi-pane and session management, including active-pane routing, layout/directory restore, local recent-directory state, and process-cleanup evidence.
- 2026-05-20: Phase 07 research, UI design contract, validation strategy, and five executable plans created for multi-pane/session management.
- 2026-05-20: Phase 07 Plan 01 executed and verified with a pure TerminalCore workspace model, Codable snapshots, deterministic split/close/duplicate/focus behavior, recent-directory normalization, and no process resurrection state.
- 2026-05-20: Phase 07 Plan 02 executed and verified with per-pane terminal interaction controllers, pane-scoped activity callbacks, active-pane routing, close-pane termination, terminate-all cleanup, and deprecated legacy notification commands.
- 2026-05-20: Phase 07 Plan 03 executed and verified with recursive SwiftUI split-pane rendering, active-pane styling/accessibility, focused terminal menu commands, real split resizing, and active-pane Command Intelligence closures.
- 2026-05-20: Phase 07 Plan 04 executed and verified with Application Support JSON snapshots, recent-directory persistence, RootView restore/save wiring, Settings recovery copy, reset saved session, and architecture/release docs.
- 2026-05-20: Phase 07 Plan 05 executed and verified with DEBUG multi-pane/session smoke fixture, release launch helpers, final evidence log, full build/test, source gates, privacy checks, and diff check.
- 2026-05-20: Phase 07 verification passed with 12/12 must-haves verified after live DEBUG multi-pane and session-restore smoke wrote all markers and left no gridOS process after quit.
- 2026-05-20: Phase 08 context gathered for Mac-native integrations, with recommended defaults for lightweight menu bar companion, opt-in local notifications, reusable Keychain credential boundaries, optional metadata-only indexing/preview, and privacy-preserving verification.
- 2026-05-21: Phase 08 research, validation strategy, UI design contract, and four executable plans created for macOS integrations.
- 2026-05-21: Phase 08 Plan 01 executed and verified with an `Integrations` framework/test target, macOS integration preference defaults, pure integration models, reusable GridOSKit Keychain primitives, and Command Intelligence credential-store reuse.
- 2026-05-21: Phase 08 Plan 02 executed and verified with a SwiftUI `MenuBarExtra`, compact menu content, app/Settings/Finder-only actions, and the macOS Integrations Settings section.
- 2026-05-21: Phase 08 Plan 03 executed and verified with injectable local notifications, explicit `Enable Notifications` permission flow, and deterministic sanitized notification smoke support.
- 2026-05-21: Phase 08 Plan 04 executed and verified with metadata-only Core Spotlight indexing, path-stripping tests, Quick Look deferral, final evidence, and a stabilized notification smoke marker.
- 2026-05-21: Phase 08 verification passed with final build/test, menu bar, notification, Keychain, Spotlight, privacy, whitespace, and smoke gates green.
- 2026-05-21: Phase 09 context gathered for performance hardening, with measurement-first benchmark strategy, privacy-safe synthetic evidence, cold-start/readiness scope, settled memory/idle CPU scope, frame-pacing direction, terminal latency/heavy-output direction, and preservation rules.
- 2026-05-21: Phase 09 research, validation strategy, and four executable plans created for benchmark harness foundation, app-side smoke fixtures, measured scenarios, and final evidence/signoff.
- 2026-05-21: Phase 09 Plan 01 executed and verified with a repo-local benchmark runner, placeholder evidence report, release benchmark invocation, and privacy boundaries.
- 2026-05-21: Phase 09 Plan 02 executed and verified with DEBUG app-side benchmark fixtures, RootView workspace/render hooks, runner fixture functions, and full build/test/source/privacy gates.
- 2026-05-21: Phase 09 Plan 03 executed and verified with measured quick benchmark evidence, explicit target misses, and xctrace quick-mode unavailable status.
- 2026-05-21: Phase 09 Plan 04 executed and verified with final evidence, generated privacy proof, release docs, verification report, and Phase 10 handoff.
- 2026-05-21: Phase 09 verification passed with 9/9 must-haves verified as evidence/signoff items and 5 documented performance target misses carried forward.
- 2026-05-21: Phase 10 context gathered for security and privacy hardening, with auto-selected YOLO defaults covering threat model, privacy inventory, LLM redaction/provider boundaries, command-risk policy, Keychain proof, persistence/indexing/notification evidence, dependency/license review, and hardened-runtime compatibility.
- 2026-05-21: Phase 10 research, validation strategy, and five executable plans created for security and privacy hardening.
- 2026-05-21: Phase 10 Plan 01 executed and verified with `docs/security-threat-model.md`, `docs/privacy-data-inventory.md`, and release/security doc links.
- 2026-05-21: Phase 10 Plan 02 executed and verified with expanded realistic secret redaction fixtures and Anthropic approved-preview provider-boundary tests.
- 2026-05-21: Phase 10 Plan 03 executed and verified with expanded command-risk fixtures and local run-policy authority tests.
- 2026-05-21: Phase 10 Plan 04 executed and verified with Keychain/preference hygiene tests, persistence/indexing/notification privacy gates, and Phase 10 evidence README.
- 2026-05-21: Phase 10 Plan 05 executed with dependency/license review, hardened-runtime posture, and final security/privacy verification.
- 2026-05-21: Phase 10 verification passed with 11/11 must-haves verified and handoff to Phase 11 - Alpha.
- 2026-05-21: Phase 11 context, research, validation strategy, and five executable plans created for Alpha signing preflight, internal artifact build/verification, daily-driver UAT, feedback/diagnostics, and final verification.
- 2026-05-21: Phase 11 signing was unblocked with local Developer ID inputs, `scripts/build-alpha.sh` produced signed artifact `build/alpha/gridOS-0.1.0-1-ba71322.zip`, and `scripts/verify-alpha-artifact.sh` passed.
- 2026-05-21: Resolved signed Alpha launch beachball ALPHA-004 by disabling the SwiftUI `MenuBarExtra` scene for Alpha; archived signed app launch proof showed one window, a live shell child, and settled CPU of `3.4%` after 15 seconds.
- 2026-05-21: Resolved signed Alpha multi-pane shell lifecycle issue ALPHA-005 in `69e8518`; signed UAT proved split/close child shell counts `1 -> 2 -> 3 -> 2`, two-pane restore, and zero child shells after quit.
- 2026-05-21: Phase 11 Alpha passed with signed artifact `build/alpha/gridOS-0.1.0-1-69e8518.zip`; `11-VERIFICATION.md`, `ALPHA-UAT.md`, and `evidence/signed-artifact-uat.md` record the handoff to Phase 12 Beta.
- 2026-05-21: Phase 12 planned with context, research, validation, UI spec, and five executable Beta plans.
- 2026-05-21: Phase 12 Plan 01 executed and verified with Beta notarization preflight, evidence policy, release-doc links, and sanitized `BETA_NOTARIZATION_BLOCKED` evidence for missing notary credential mode.
- 2026-05-21: Phase 12 Plan 02 executed and verified with Beta build, notarization, stapling, and artifact verification scripts plus release/evidence docs; live artifact creation remains blocked until a notary credential mode is provided.
- 2026-05-21: Phase 12 Plan 03 executed and verified with Beta release manifest writer, placeholder manifest, distribution/update/rollback guide, and clean-Mac Gatekeeper UAT checklist.
- 2026-05-21: Phase 12 Plan 04 executed and verified with first-run Beta privacy disclosure, Settings review/support copy, feedback template, known-issues tracker, privacy docs, and full unsigned Xcode tests.
- 2026-05-21: Phase 12 Plan 05 executed with final Beta verification status `BLOCKED`; source gates pass, but notarization, stapling, clean-Mac Gatekeeper UAT, and update-flow proof require a notary credential mode and notarized artifacts.
- 2026-05-21: Phase 12 notary blocker cleared; `gridOS-0.1.0-1-20b35f0.dmg` was signed, notarized, stapled, locally Gatekeeper-verified, release-manifested, and local launch-smoked. Remaining blockers are clean-Mac Finder/Gatekeeper UAT and Beta N to N+1 update proof.
- 2026-06-02: Phase 13 App Store readiness started with staged App Sandbox entitlements, privacy manifest, production-facing privacy Settings copy, `docs/app-store-readiness.md`, and `scripts/app-store-preflight.sh`; preflight, XcodeGen regeneration, generated project checks, full unsigned build/test, and diff check passed.
- 2026-06-02: App Store readiness paused after product review; Phase 13 product desirability added a display-only local visual signature, upgraded first-run Privacy & Safety, added the signature to the app header and right rail, documented the product bar in `docs/product-desirability.md`, and passed full unsigned build/test plus diff check.
- 2026-06-03: Product ship pass kept the direct Developer ID Beta target unsandboxed, upgraded the right rail into a local system pulse, upgraded Command-K with briefing/example prompts, refreshed Phase 5 app-window screenshots, and prepared a fresh direct-release verification/build path.
- 2026-06-03: Ship-today artifact `build/beta/ship-today/gridOS-0.1.0-6-e1c7005.dmg` was signed, notarized, stapled, locally Gatekeeper-verified, release-manifested, and local launch-smoked. Final SHA-256 is `fc4e353604f7b5195678fc86320633a4918955146db7429146133f8be495879d`; clean-Mac Finder/Gatekeeper UAT and clean-Mac update-flow proof remain external blockers for broad Beta signoff.
- 2026-06-03: Production direct 1.0.2 build 10 artifact `build/release/production/gridOS-1.0.2-10-8f2865b.dmg` was app-signed, DMG-signed, notarized, stapled, locally Gatekeeper-verified, release-manifested, launch-smoked, and visually checked with a drag-to-Applications DMG layout. Final SHA-256 is `52db1e21ee81df5b5f6e1bda5aec05888baf64277bbe13fe8d5703ad402f867c`; clean-Mac Finder/Gatekeeper install and version-to-version update proof remain external validation tasks.

## Performance metrics

| Phase | Plan | Duration | Tasks | Files |
| --- | --- | --- | --- | --- |
| 05-aesthetic-modes | 01 | 5 min | 2 | 9 |
| 05-aesthetic-modes | 02 | 3 min | 2 | 3 |
| 05-aesthetic-modes | 03 | 5 min | 2 | 3 |
| 05-aesthetic-modes | 04 | 27 min | 3 | 14 |
| 06-llm-command-palette | 01 | 5 min | 1 | 12 |
| 06-llm-command-palette | 03 | 6 min | 1 | 3 |
| 06-llm-command-palette | 02 | 8 min | 1 | 6 |
| 06-llm-command-palette | 04 | 9 min | 3 | 9 |
| 06-llm-command-palette | 05 | 10min | 3 | 9 |
| Phase 06-llm-command-palette P06 | 14min | 3 tasks | 12 files |
| Phase 07 P01 | 4min | 1 tasks | 4 files |
| Phase 07 P02 | 6min | 2 tasks | 8 files |
| Phase 07 P03 | 6min | 2 tasks | 7 files |
| Phase 07 P04 | 7min | 2 tasks | 8 files |
| Phase 07 P05 | 5min | 2 tasks | 5 files |
| Phase 08 P01 | 6min | 2 tasks | 12 files |
| Phase 08 P02 | 5min | 2 tasks | 8 files |
| Phase 08 P03 | 5min | 2 tasks | 7 files |
| Phase 08 P04 | 12min | 2 tasks | 11 files |
| Phase 09 P01 | 2min | 2 tasks | 3 files |
| Phase 09 P02 | 7min | 2 tasks | 5 files |
| Phase 09 P03 | 8min | 3 tasks | 3 files |
| Phase 09 P04 | 5min | 2 tasks | 8 files |
| Phase 10 P01 | 4min | 2 tasks | 5 files |
| Phase 10 P02 | 5min | 2 tasks | 3 files |
| Phase 10 P03 | 4min | 2 tasks | 3 files |
| Phase 10 P04 | 5min | 2 tasks | 6 files |
| Phase 10 P05 | 4min | 2 tasks | 6 files |
| Phase 10 total | 22min | 10 tasks | 23 files |
| Phase 11 P01 | 2min | 2 tasks | 3 files |
| Phase 11-alpha P02 | 3 min | 2 tasks | 4 files |
| Phase 11-alpha P03 | 3 min | 2 tasks | 6 files |
| Phase 11-alpha P04 | 4 min | 2 tasks | 6 files |
| Phase 11-alpha P05 | 8 min | 2 tasks | 8 files |
| Phase 12-beta P01 | 4 min | 2 tasks | 5 files |
| Phase 12-beta P02 | 5 min | 2 tasks | 5 files |
| Phase 12-beta P03 | 3 min | 2 tasks | 5 files |
| Phase 12-beta P04 | 6 min | 2 tasks | 9 files |
| Phase 12-beta P05 | 4 min | 2 tasks | 5 files |
| Phase 13-app-store-readiness P01 | 12 min | 4 tasks | 8 files |
| Phase 13-product-desirability P02 | 18 min | 4 tasks | 6 files |

## Next target

Run clean-Mac Finder/Gatekeeper UAT for `gridOS-1.0.2-10-8f2865b.dmg`, then prove clean-Mac version-to-version replacement/update from 1.0.1 build 9 to 1.0.2 build 10. Phase 9 performance gates are passing.

## Session handoff

- 2026-05-20: Phase 03 context gathered.
- Resume file: `.planning/phases/03-production-app-frame/03-CONTEXT.md`.
- 2026-05-20: Phase 03 research, UI design contract, validation strategy, and executable plan created.
- Plan file: `.planning/phases/03-production-app-frame/03-01-PLAN.md`.
- 2026-05-20: Phase 04 context gathered.
- Resume file: `.planning/phases/04-real-system-metrics/04-CONTEXT.md`.
- 2026-05-20: Phase 04 research, validation strategy, UI design contract, and executable plan created.
- Plan file: `.planning/phases/04-real-system-metrics/04-01-PLAN.md`.
- 2026-05-20: Phase 04 executed and verified.
- Summary file: `.planning/phases/04-real-system-metrics/04-01-SUMMARY.md`.
- Verification file: `.planning/phases/04-real-system-metrics/04-VERIFICATION.md`.
- 2026-05-20: Phase 05 context gathered.
- Resume file: `.planning/phases/05-aesthetic-modes/05-CONTEXT.md`.
- Discussion log: `.planning/phases/05-aesthetic-modes/05-DISCUSSION-LOG.md`.
- 2026-05-20: Phase 05 Plan 01 executed and verified.
- Summary file: `.planning/phases/05-aesthetic-modes/05-01-SUMMARY.md`.
- 2026-05-20: Phase 05 Plan 02 executed and verified.
- Summary file: `.planning/phases/05-aesthetic-modes/05-02-SUMMARY.md`.
- 2026-05-20: Phase 05 Plan 03 executed and verified.
- Summary file: `.planning/phases/05-aesthetic-modes/05-03-SUMMARY.md`.
- 2026-05-20: Phase 05 Plan 04 automated evidence capture completed and paused at human visual/focus checkpoint.
- Evidence README: `.planning/phases/05-aesthetic-modes/evidence/README.md`.
- Screenshot files: `.planning/phases/05-aesthetic-modes/evidence/tron.png`, `.planning/phases/05-aesthetic-modes/evidence/severance.png`, `.planning/phases/05-aesthetic-modes/evidence/apple-native.png`, `.planning/phases/05-aesthetic-modes/evidence/tron-install-a.png`, `.planning/phases/05-aesthetic-modes/evidence/tron-install-b.png`, `.planning/phases/05-aesthetic-modes/evidence/tron-install-c.png`, `.planning/phases/05-aesthetic-modes/evidence/focus-smoke-command-shift-m.png`.
- 2026-05-20: Phase 05 Plan 04 completed after approved visual review and live focus smoke.
- Summary file: `.planning/phases/05-aesthetic-modes/05-04-SUMMARY.md`.
- 2026-05-20: Phase 05 verification passed with 8/8 must-haves verified.
- Verification file: `.planning/phases/05-aesthetic-modes/05-VERIFICATION.md`.
- 2026-05-20: Phase 06 context gathered for the LLM command palette with conservative command safety, explicit context preview, Keychain-backed provider setup, and insert-first generated-command handling.
- Resume file: `.planning/phases/06-llm-command-palette/06-CONTEXT.md`.
- Discussion log: `.planning/phases/06-llm-command-palette/06-DISCUSSION-LOG.md`.
- 2026-05-20: Phase 06 Plan 01 executed and verified.
- Summary file: `.planning/phases/06-llm-command-palette/06-01-SUMMARY.md`.
- 2026-05-20: Phase 06 Plan 02 executed and verified in Wave 2.
- Summary file: `.planning/phases/06-llm-command-palette/06-02-SUMMARY.md`.
- 2026-05-20: Phase 06 Plan 03 executed and verified in Wave 2.
- Summary file: `.planning/phases/06-llm-command-palette/06-03-SUMMARY.md`.
- 2026-05-20: Phase 06 Plan 04 executed and verified.
- Summary file: `.planning/phases/06-llm-command-palette/06-04-SUMMARY.md`.
- 2026-05-20: Phase 06 Plan 05 executed and verified.
- Summary file: `.planning/phases/06-llm-command-palette/06-05-SUMMARY.md`.
- 2026-05-20: Phase 06 Plan 06 executed and verified.
- Summary file: `.planning/phases/06-llm-command-palette/06-06-SUMMARY.md`.
- 2026-05-20: Phase 07 context gathered for multi-pane and session management.
- Resume file: `.planning/phases/07-multi-pane-session-management/07-CONTEXT.md`.
- Discussion log: `.planning/phases/07-multi-pane-session-management/07-DISCUSSION-LOG.md`.
- 2026-05-20: Phase 07 research, UI design contract, validation strategy, and executable plans created.
- Research file: `.planning/phases/07-multi-pane-session-management/07-RESEARCH.md`.
- UI design contract: `.planning/phases/07-multi-pane-session-management/07-UI-SPEC.md`.
- Validation strategy: `.planning/phases/07-multi-pane-session-management/07-VALIDATION.md`.
- Plan files: `.planning/phases/07-multi-pane-session-management/07-01-PLAN.md` through `.planning/phases/07-multi-pane-session-management/07-05-PLAN.md`.
- 2026-05-20: Phase 07 Plan 01 executed and verified.
- Summary file: `.planning/phases/07-multi-pane-session-management/07-01-SUMMARY.md`.
- 2026-05-20: Phase 07 Plan 02 executed and verified.
- Summary file: `.planning/phases/07-multi-pane-session-management/07-02-SUMMARY.md`.
- 2026-05-20: Phase 07 Plan 03 executed and verified.
- Summary file: `.planning/phases/07-multi-pane-session-management/07-03-SUMMARY.md`.
- 2026-05-20: Phase 07 Plan 04 executed and verified.
- Summary file: `.planning/phases/07-multi-pane-session-management/07-04-SUMMARY.md`.
- 2026-05-20: Phase 07 Plan 05 executed and verified.
- Summary file: `.planning/phases/07-multi-pane-session-management/07-05-SUMMARY.md`.
- Evidence file: `.planning/phases/07-multi-pane-session-management/evidence/README.md`.
- 2026-05-20: Phase 07 verification passed.
- Verification file: `.planning/phases/07-multi-pane-session-management/07-VERIFICATION.md`.
- 2026-05-20: Phase 08 context gathered.
- Resume file: `.planning/phases/08-macos-integrations/08-CONTEXT.md`.
- Discussion log: `.planning/phases/08-macos-integrations/08-DISCUSSION-LOG.md`.
- 2026-05-21: Phase 08 research, UI design contract, validation strategy, and executable plans created.
- Research file: `.planning/phases/08-macos-integrations/08-RESEARCH.md`.
- UI design contract: `.planning/phases/08-macos-integrations/08-UI-SPEC.md`.
- Validation strategy: `.planning/phases/08-macos-integrations/08-VALIDATION.md`.
- Plan files: `.planning/phases/08-macos-integrations/08-01-PLAN.md` through `.planning/phases/08-macos-integrations/08-04-PLAN.md`.
- 2026-05-21: Phase 08 Plan 01 executed and verified.
- Summary file: `.planning/phases/08-macos-integrations/08-01-SUMMARY.md`.
- 2026-05-21: Phase 08 Plan 02 executed and verified.
- Summary file: `.planning/phases/08-macos-integrations/08-02-SUMMARY.md`.
- 2026-05-21: Phase 08 Plan 03 executed and verified.
- Summary file: `.planning/phases/08-macos-integrations/08-03-SUMMARY.md`.
- 2026-05-21: Phase 08 Plan 04 executed and verified.
- Summary file: `.planning/phases/08-macos-integrations/08-04-SUMMARY.md`.
- Evidence file: `.planning/phases/08-macos-integrations/evidence/README.md`.
- 2026-05-21: Phase 08 verification passed.
- Verification file: `.planning/phases/08-macos-integrations/08-VERIFICATION.md`.
- 2026-05-21: Phase 09 context gathered.
- Resume file: `.planning/phases/09-performance-hardening/09-CONTEXT.md`.
- Discussion log: `.planning/phases/09-performance-hardening/09-DISCUSSION-LOG.md`.
- 2026-05-21: Phase 09 research, validation strategy, and executable plans created.
- Research file: `.planning/phases/09-performance-hardening/09-RESEARCH.md`.
- Validation strategy: `.planning/phases/09-performance-hardening/09-VALIDATION.md`.
- Plan files: `.planning/phases/09-performance-hardening/09-01-PLAN.md` through `.planning/phases/09-performance-hardening/09-04-PLAN.md`.
- 2026-05-21: Phase 09 Plan 01 executed and verified.
- Summary file: `.planning/phases/09-performance-hardening/09-01-SUMMARY.md`.
- 2026-05-21: Phase 09 Plan 02 executed and verified.
- Summary file: `.planning/phases/09-performance-hardening/09-02-SUMMARY.md`.
- 2026-05-21: Phase 09 Plan 03 executed and verified.
- Summary file: `.planning/phases/09-performance-hardening/09-03-SUMMARY.md`.
- Evidence file: `.planning/phases/09-performance-hardening/evidence/README.md`.
- 2026-05-21: Phase 09 Plan 04 executed and verified.
- Summary file: `.planning/phases/09-performance-hardening/09-04-SUMMARY.md`.
- Verification file: `.planning/phases/09-performance-hardening/09-VERIFICATION.md`.
- Phase 09 status: verification passed with cold start PASS and resident memory, idle CPU, input latency, heavy output, and frame pacing misses documented in final evidence.
- 2026-05-21: Phase 10 context gathered.
- Resume file: `.planning/phases/10-security-and-privacy-hardening/10-CONTEXT.md`.
- Discussion log: `.planning/phases/10-security-and-privacy-hardening/10-DISCUSSION-LOG.md`.
- 2026-05-21: Phase 10 research and planning completed.
- Research file: `.planning/phases/10-security-and-privacy-hardening/10-RESEARCH.md`.
- Validation strategy: `.planning/phases/10-security-and-privacy-hardening/10-VALIDATION.md`.
- Plan files: `.planning/phases/10-security-and-privacy-hardening/10-01-PLAN.md` through `.planning/phases/10-security-and-privacy-hardening/10-05-PLAN.md`.
- 2026-05-21: Phase 10 Plan 01 executed and verified.
- Summary file: `.planning/phases/10-security-and-privacy-hardening/10-01-SUMMARY.md`.
- 2026-05-21: Phase 10 Plan 02 executed and verified.
- Summary file: `.planning/phases/10-security-and-privacy-hardening/10-02-SUMMARY.md`.
- 2026-05-21: Phase 10 Plan 03 executed and verified.
- Summary file: `.planning/phases/10-security-and-privacy-hardening/10-03-SUMMARY.md`.
- 2026-05-21: Phase 10 Plan 04 executed and verified.
- Summary file: `.planning/phases/10-security-and-privacy-hardening/10-04-SUMMARY.md`.
- Evidence file: `.planning/phases/10-security-and-privacy-hardening/evidence/README.md`.
- 2026-05-21: Phase 10 Plan 05 executed and verified.
- Summary file: `.planning/phases/10-security-and-privacy-hardening/10-05-SUMMARY.md`.
- Verification file: `.planning/phases/10-security-and-privacy-hardening/10-VERIFICATION.md`.
- Phase 10 status: verification passed with 11/11 must-haves verified.
- 2026-05-21: Phase 11 planning completed.
- Research file: `.planning/phases/11-alpha/11-RESEARCH.md`.
- Validation strategy: `.planning/phases/11-alpha/11-VALIDATION.md`.
- Context file: `.planning/phases/11-alpha/11-CONTEXT.md`.
- Plan files: `.planning/phases/11-alpha/11-01-PLAN.md` through `.planning/phases/11-alpha/11-05-PLAN.md`.
- 2026-05-21: Phase 11 Plan 01 executed and verified with signing preflight, Alpha evidence policy, release-doc links, and final dry-run `SIGNING_BLOCKED` evidence for missing local signing env vars.
- Summary file: `.planning/phases/11-alpha/11-01-SUMMARY.md`.
- 2026-05-21: Phase 11 Plan 02 executed and verified with signed alpha build scripting, artifact verification scripting, release/evidence docs, and final syntax/source gates.
- Summary file: `.planning/phases/11-alpha/11-02-SUMMARY.md`.
- 2026-05-21: Phase 11 Plan 03 executed and verified with DEBUG alpha terminal/workspace/privacy smoke, daily-driver UAT checklist, sanitized helper script, and final build/test plus syntax/source gates.
- Summary file: `.planning/phases/11-alpha/11-03-SUMMARY.md`.
- 2026-05-21: Phase 11 Plan 04 executed and verified with Alpha known-issues tracking, feedback intake, sanitized diagnostics policy, release/evidence links, and final source gates.
- Summary file: `.planning/phases/11-alpha/11-04-SUMMARY.md`.
- 2026-05-21: Phase 11 Plan 05 final verification executed. Unsigned build/test and sanitized UAT helper passed, but Alpha is blocked by `SIGNING_BLOCKED`, absent signed artifact verification, missing DEBUG alpha smoke markers, and the broad privacy command overmatching legitimate source/docs references.
- 2026-05-21: Phase 11 local blocker recheck resolved ALPHA-002 and ALPHA-003 with passing DEBUG alpha smoke markers, a focused evidence privacy leak scan, and sanitized evidence in `local-blocker-recheck.md`.
- 2026-05-21: User-provided app icon assets were incorporated into the reproducible XcodeGen/project setup; the Debug bundle now contains `AppIcon.icns` and `Assets.car`.
- 2026-05-21: Phase 11 signed artifact `gridOS-0.1.0-1-69e8518.zip` built and verified with Developer ID signing evidence.
- 2026-05-21: Phase 11 signed daily-driver UAT passed, including terminal launch, keyboard, paste, copy, clear/reset, split/close process cleanup, relaunch restore, command availability, Command Intelligence policy, and macOS integration privacy/default checks.
- Verification file: `.planning/phases/11-alpha/11-VERIFICATION.md`.
- Known issues: `.planning/phases/11-alpha/KNOWN-ISSUES.md`.
- UAT file: `.planning/phases/11-alpha/ALPHA-UAT.md`.
- Signed UAT evidence: `.planning/phases/11-alpha/evidence/signed-artifact-uat.md`.
- Evidence README: `.planning/phases/11-alpha/evidence/README.md`.
- Phase 12 Plan 01 summary: `.planning/phases/12-beta/12-01-SUMMARY.md`.
- Phase 12 Plan 01 evidence: `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt`.
- Phase 12 Plan 02 summary: `.planning/phases/12-beta/12-02-SUMMARY.md`.
- Phase 12 Plan 02 scripts: `scripts/build-beta.sh`, `scripts/notarize-beta-artifact.sh`, `scripts/verify-beta-artifact.sh`.
- Phase 12 Plan 03 summary: `.planning/phases/12-beta/12-03-SUMMARY.md`.
- Phase 12 Plan 03 docs: `docs/beta-distribution.md`, `.planning/phases/12-beta/BETA-UAT.md`, `.planning/phases/12-beta/beta-release-manifest.json`.
- Phase 12 Plan 04 summary: `.planning/phases/12-beta/12-04-SUMMARY.md`.
- Phase 12 Plan 04 UI: `Sources/GridOSApp/BetaPrivacyDisclosureView.swift`, `Sources/GridOSApp/RootView.swift`, `Sources/GridOSApp/SettingsView.swift`.
- Phase 12 Plan 04 feedback docs: `.planning/phases/12-beta/BETA-FEEDBACK.md`, `.planning/phases/12-beta/KNOWN-ISSUES.md`.
- Phase 12 Plan 05 summary: `.planning/phases/12-beta/12-05-SUMMARY.md`.
- Phase 12 verification: `.planning/phases/12-beta/12-VERIFICATION.md`.
- Phase 12 clean-Mac evidence: `.planning/phases/12-beta/evidence/clean-mac-gatekeeper.md`.
- Phase 12 notary setup docs: `docs/notarization-setup.md`.
- Phase 12 notary profile helpers: `scripts/setup-beta-notary-profile.sh`, `scripts/check-beta-notary-profile.sh`.
- Phase 12 notary profile check evidence: `.planning/phases/12-beta/evidence/beta-notary-profile-check.txt`.
- Phase 12 signing discovery: Beta scripts resolve `GRIDOS_SIGNING_IDENTITY` from the local Developer ID Application identity and derive `GRIDOS_DEVELOPMENT_TEAM` from that identity when env overrides are absent.
- Phase 12 notarization evidence: `.planning/phases/12-beta/evidence/beta-notarization.md`.
- Phase 12 artifact verification evidence: `.planning/phases/12-beta/evidence/beta-artifact-verification.md`.
- Phase 12 local launch smoke evidence: `.planning/phases/12-beta/evidence/local-notarized-launch-smoke.md`.
- 2026-06-15: Public GitHub release-readiness pass aligned current docs to 1.0.5, verified local CI/artifact/Gatekeeper checks, and Computer Use inspected the mounted DMG plus running Applications copy.
- Stopped at: Production direct 1.0.5 is public on GitHub as source-available proprietary code; separate clean-Mac Finder/Gatekeeper UAT and clean-Mac update proof remain external validation.
- 2026-06-15: Prepared production direct 1.0.6 with the new icon, username-free README visuals, Sparkle automatic updates, signed Sparkle helpers, final signed/notarized `gridOS-1.0.6-14-edda1ee.dmg`, v1.0.6 release notes, and a signed `appcast.xml` with validated feed and enclosure Ed25519 signatures.
- 2026-06-16: Published GitHub release `v1.0.6` with the signed/notarized DMG, ZIP, and signed appcast assets; pushed `main` through commit `026a58d` and GitHub Actions CI passed.
- Stopped at: Production direct 1.0.6 is public; clean-Mac Finder/Gatekeeper UAT and 1.0.6-to-next Sparkle update proof remain external validation.
