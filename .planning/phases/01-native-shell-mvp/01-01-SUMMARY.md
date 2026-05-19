# Phase 1 summary - Native shell MVP

## Completed

- Added SwiftTerm `1.13.0` through XcodeGen/SwiftPM.
- Added `TerminalCore` APIs:
  - `TerminalSessionConfiguration`
  - `TerminalSessionState`
  - `TerminalSurface`
  - `TerminalCommandCenter`
- Embedded a SwiftTerm `LocalProcessTerminalView` behind `TerminalSurface`.
- Launches the user's default shell, falling back to `/bin/zsh`.
- Starts a login-style shell name such as `-zsh`.
- Terminates the shell during SwiftUI/AppKit dismantle.
- Added app menu commands for copy, paste, clear, and reset.
- Added Settings placeholders for shell path and terminal font size.
- Added `--cmd` startup command support for smoke verification.
- Added `TerminalCoreTests`.
- Normalized phase directory names so GSD helpers can find Phase 1.

## Verification

Build and tests:

```sh
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
```

Result: passed with 8 tests.

Launch smoke:

- Debug `gridOS.app` launched.
- `-zsh` child process was observed.
- AppleScript activated/clicked the window, typed `exit`, and the shell child exited.
- App process was cleaned up after verification.

PTY command smoke through `--cmd`:

- `vim --version`
- `less --version`
- `ssh -V`
- `tmux -V`
- `top -l 1 -n 0`
- `yes gridos-fast-output | head -1000 | wc -l`

Result: commands completed and wrote expected smoke evidence to `/tmp/gridos-phase1-smoke.txt`.

## Notes

- SwiftTerm remains isolated to `TerminalCore`; `GridOSApp` consumes only gridOS-owned APIs.
- The app is intentionally unsandboxed for this terminal MVP lane, matching the direct-distribution direction documented in the roadmap.
- Full human daily-driver testing still matters before alpha, but Phase 1's implementation and smoke gates are complete.
