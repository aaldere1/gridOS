# gridOS state

## Active phase

Phase 3 - Production app frame

## Current status

Phase 3 plan execution is code-complete and awaiting phase-level verification. The app now has a terminal-first production frame with persisted settings, window autosave, reduced-motion-aware rendering, menu-visible terminal commands, and accessibility labels/values layered around the SwiftTerm-backed shell and Metal `Signal Field` background.

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

## Next target

Complete Phase 3 final verification, launch smoke, summary, and phase-level verification.

## Session handoff

- 2026-05-20: Phase 03 context gathered.
- Resume file: `.planning/phases/03-production-app-frame/03-CONTEXT.md`.
- 2026-05-20: Phase 03 research, UI design contract, validation strategy, and executable plan created.
- Plan file: `.planning/phases/03-production-app-frame/03-01-PLAN.md`.
- Next command: `$gsd-execute-phase 3`.
