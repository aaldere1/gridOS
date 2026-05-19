# gridOS state

## Active phase

Phase 1 - Native shell MVP

## Current status

Phase 0 is complete. The repo now has a reproducible XcodeGen scaffold, blank macOS SwiftUI app, module boundaries, initial docs, CI skeleton, and a passing local build/test run.

## Decisions made

- Use XcodeGen for deterministic Xcode project generation.
- Start with direct Developer ID distribution as the likely production path.
- Keep App Store distribution as a later evaluation because sandboxing may constrain terminal/system features.
- Start with SwiftTerm behind an adapter once TerminalCore begins.
- Treat public plugins and custom GPU text rendering as post-stability work, not initial blockers.
- Use a conservative proprietary license posture during private alpha unless changed before public release.
- Keep `project.yml` authoritative for Xcode project structure.

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

## Next target

Start Phase 1 native shell MVP:

1. Add a terminal backend dependency behind `TerminalCore`.
2. Create a `TerminalSession` API.
3. Render a real shell in the app window.
4. Verify `zsh`, resize, copy/paste, and basic TUI behavior.
