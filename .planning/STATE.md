# gridOS state

## Active phase

Phase 3 - Production app frame

## Current status

Phase 2 is complete. The app now opens to a SwiftTerm-backed local shell over a burst-driven Metal `Signal Field` background from `RenderCore`, with terminal activity bridged into subtle render pulses and passing build/tests/smoke checks.

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

## Next target

Start Phase 3 Production app frame:

1. Make window behavior, focus, and state restoration production-shaped.
2. Replace Settings placeholders with persisted terminal/app preferences.
3. Harden keyboard commands and accessibility paths.
4. Add focused tests around app frame state and preference behavior.

## Session handoff

- 2026-05-20: Phase 03 context gathered.
- Resume file: `.planning/phases/03-production-app-frame/03-CONTEXT.md`.
- Next command: `$gsd-plan-phase 3`.
