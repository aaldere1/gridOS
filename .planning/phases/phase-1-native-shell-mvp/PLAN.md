# Phase 1 plan - Native shell MVP

## Goal

Build a boring but real terminal surface before expanding visual ambition.

## Scope

Phase 1 introduces terminal functionality only. Metal visuals, system metrics, LLM assistance, multi-pane sessions, and production updater work remain out of scope.

## Tasks

- [ ] Select and add the initial terminal backend dependency.
- [ ] Keep the backend behind `TerminalCore` APIs.
- [ ] Define `TerminalSession` and lifecycle states.
- [ ] Launch the user's default shell.
- [ ] Embed the terminal view in the app window.
- [ ] Propagate window/view resize events to the PTY.
- [ ] Support copy, paste, clear, and reset affordances.
- [ ] Add basic terminal profile settings placeholders.
- [ ] Add tests for session configuration and lifecycle state.
- [ ] Manually verify `zsh`, `vim`, `less`, `top`, `ssh`, `tmux`, and fast output.
- [ ] Update `.planning/STATE.md` with verification evidence.

## Acceptance criteria

- The app opens to a usable shell.
- Closing the window cleans up the shell process.
- Resize behavior is correct.
- Basic copy/paste works.
- Common terminal programs are usable enough to continue development inside gridOS.
- No visual feature work blocks terminal correctness.

## Initial recommendation

Start with SwiftTerm behind an adapter. Do not let SwiftTerm types spread into `GridOSApp`; the app should depend on `TerminalCore` concepts so the backend can be replaced later if needed.

## Verification commands

```sh
xcodegen generate
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build test
```

Manual verification should be recorded in `.planning/STATE.md`.
