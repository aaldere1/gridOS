# Debug: intermittent multi-pane clipboard routing

Started: 2026-06-19
Resolved: 2026-06-19
Status: resolved

## Symptoms

- Expected: Copy/select-all in any terminal pane should copy from that pane and paste into any other active terminal pane, even after opening multiple panes and moving between them.
- Actual: It works for some panes, then after opening multiple panes and switching between them, copy/paste works on some panes and not others.
- Errors: No known visible errors.
- Timeline: Reported after public v1.0.14 build 22. v1.0.14 fixed the direct source-pane Command-A/Command-C path, but real usage still shows intermittent pane failures.
- Reproduction: Open several terminal panes, move between panes, select/copy from one pane, paste into another. Repeat across panes until some source/target panes stop participating correctly.

## Initial Hypotheses

1. Some `TerminalSurface` instances emit activity without the correct current pane ID after layout changes or view reuse.
2. Pane move/split/focus state can leave a terminal view attached to a controller whose ID no longer matches the visible pane.
3. Copy uses the source pane correctly, but paste still targets stale active pane after drag/cycle/click movement.
4. Selected inactive-pane fallback can pick the wrong pane when multiple panes retain selection.
5. Tests cover two-pane paths but not repeated multi-pane split/switch/move sequences.

## Investigation Log

- Created persistent debug session.
- Local code trace found that terminal-originated `.pasteRequested` still calls
  `pasteIntoActivePane()`. If SwiftUI/AppKit active-pane state lags the actual
  first-responder terminal after multi-pane switching or drag moves, Command-V
  from pane S can paste into stale active pane A. Command-C and Command-A were
  already source-pane aware in v1.0.13/v1.0.14, but Command-V was not.
- Two `gsd-debugger` sidecars independently confirmed the same root cause.
  Drag/move preserves pane IDs and controllers; the failure path was paste
  routing ignoring the emitting terminal pane.

## Evidence

- v1.0.14 release proof confirms source-pane Select All and source-pane Copy tests pass for direct/simple paths.
- `TerminalSurface.GridOSTerminalView.handlePasteboardKeyEquivalent` already
  emits `.pasteRequested` from the terminal view receiving Command-V, so the
  source pane ID is available.
- `TerminalWorkspaceController.handleActivity(.pasteRequested, from:)` used that
  pane ID only after this fix. Before this session, it routed through
  `pasteIntoActivePane()`.
- `movePane` rebuilds layout around the same `TerminalPaneID` and leaves
  `panesByID` intact, so moved panes do not lose controller identity.

## Fix

- Added `paste(into:)` to target the emitting source pane when it still exists,
  falling back to `pasteIntoActivePane()` only for a missing/stale source pane.
- Changed terminal-originated `.pasteRequested` to call `paste(into: paneID)`.
- Added regressions for source-pane paste, stale active pane after switching,
  moved pane paste, missing-source fallback, and rapid multi-pane paste events.

## Verification

- `git diff --check`
- `xcodebuild test -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:TerminalCoreTests`
- `./scripts/ci-build-test.sh`
