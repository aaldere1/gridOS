---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: phase-04-complete
last_updated: "2026-05-20T15:32:39Z"
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 5
  completed_plans: 5
---

# gridOS state

## Active phase

Phase 4 - Real system metrics

## Current status

Phase 4 is complete. The app now replaces Phase 3's placeholder system/activity panels with `SystemMetrics` snapshots while preserving terminal dominance, local-only privacy, no-root operation, graceful unavailable states, and sampler-owned cadence/backpressure.

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

## Decisions still open

- Final public license and source availability.
- Final bundle identifier and signing team.
- Whether Intel Macs are supported after beta.
- Which LLM provider ships first.
- Whether Sparkle or another updater is used for direct distribution.

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

## Next target

Plan Phase 5 Aesthetic modes.

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
- Next command: `$gsd-discuss-phase 5`.
