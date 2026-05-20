# Phase 3 research - Production app frame

## RESEARCH COMPLETE

## Goal

Answer what the planner needs to know before turning Phase 3 into executable work.

Phase 3 should make the current SwiftUI macOS prototype feel like a coherent app frame while preserving terminal correctness. The key work is a terminal-first cockpit, persisted settings/profile state, custom hidden-titlebar window behavior, terminal-safe command routing, accessibility, reduced motion, and honest state restoration.

## Current Codebase Findings

### App shell

- `Sources/GridOSApp/GridOSApp.swift` already uses `WindowGroup`, `.windowStyle(.hiddenTitleBar)`, a `Settings` scene, and a Terminal command menu.
- `Sources/GridOSApp/RootView.swift` currently composes `MetalBackgroundView`, a lightweight header, and `TerminalSurface`.
- `Sources/GridOSApp/SettingsView.swift` is placeholder-only local `@State`; values do not persist and do not feed the running terminal.
- `Sources/TerminalCore/TerminalSessionConfiguration.swift` already defines shell path, shell args, working directory, font name, font size, and startup command.
- `Sources/TerminalCore/TerminalSurface.swift` owns SwiftTerm setup, focus restoration, terminal command observers, and terminal activity events.
- `Sources/RenderCore/MetalBackgroundView.swift` owns the burst-driven Metal background, but it has no reduced-motion or intensity configuration yet.

### Existing constraints

- `project.yml` is authoritative; add tests or files there before regenerating `gridOS.xcodeproj`.
- `TerminalCore` must remain independent of `RenderCore`.
- `GridOSApp` composes modules; it should not absorb terminal or Metal internals.
- Terminal correctness outranks app chrome. Any frame, panel, command, or setting must be verified against shell launch/input behavior.

## Primary Source Research

### SwiftUI settings and persistence

Apple's SwiftUI `Settings` scene documentation describes a macOS settings scene that enables the Settings menu item and hosts app preference controls. Apple's macOS SwiftUI tutorial pattern uses `@AppStorage` for persisted preference values in a Settings scene.

Planning implication:

- Phase 3 should keep the existing `Settings` scene.
- Use simple local persistence for user preferences. `@AppStorage` is the right default for shell path, font size, reduced motion override, and visual intensity unless implementation finds a concrete reason to introduce a heavier store.

Sources:

- https://developer.apple.com/documentation/swiftui/settings
- https://developer.apple.com/tutorials/swiftui/creating-a-macos-app

### Commands, keyboard shortcuts, and focus

Apple's SwiftUI menu bar guidance says macOS menu commands are built with `commands`, `CommandMenu`, and `CommandGroup`; contextual command behavior can use focused values. Apple's `keyboardShortcut` documentation notes that shortcuts resolve through the key window/main window before command groups, and duplicate shortcuts resolve to the first control found.

Planning implication:

- Keep terminal commands in the menu system, but avoid adding broad shortcuts that can intercept shell workflows.
- Prefer explicit command-modifier shortcuts already familiar on macOS.
- If command availability becomes contextual, use SwiftUI focused values rather than global singleton state.

Sources:

- https://developer.apple.com/documentation/SwiftUI/Building-and-customizing-the-menu-bar-with-SwiftUI
- https://developer.apple.com/documentation/swiftui/view/keyboardshortcut%28_%3Amodifiers%3A%29

### Reduced motion and animation intensity

Apple's `accessibilityReduceMotion` environment value indicates whether the system Reduce Motion preference is enabled. Apple states that when true, UI should avoid large animations, especially those simulating three dimensions.

Planning implication:

- Phase 3 should read `@Environment(\.accessibilityReduceMotion)` in the app frame and combine it with the app's own reduced-motion preference.
- `RenderCore` should accept a visual effect configuration so reduced motion/intensity can reduce pulse magnitude and/or stop burst animation instead of merely hiding a control.

Source:

- https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion

### Scene and window restoration

Apple's `SceneStorage` documentation frames it as scene-scoped state that can be restored by the system, but also notes that if the scene is destroyed, the data is destroyed. Apple's AppKit `NSWindow` APIs provide frame autosave methods using the defaults system, including `setFrameAutosaveName`, `setFrameUsingName`, and `saveFrame(usingName:)`.

Planning implication:

- Use AppKit window frame autosave for the main window's size/position baseline because Phase 3 explicitly needs window recovery across relaunch.
- Use `@SceneStorage` only for ephemeral view-scoped details if needed, not as the main recovery mechanism.
- Do not restore killed shell processes. Restore app state and launch a fresh shell.

Sources:

- https://developer.apple.com/documentation/swiftui/scenestorage
- https://developer.apple.com/documentation/appkit/nswindow/setframeautosavename%28_%3A%29
- https://developer.apple.com/documentation/appkit/nswindow/saveframe%28usingname%3A%29

### Accessibility

Apple's SwiftUI accessibility modifier documentation confirms SwiftUI has built-in accessibility support plus modifiers to improve labels, values, traits, and interaction.

Planning implication:

- Phase 3 should add explicit labels/values for non-textual controls and panels.
- The settings form must expose stable labels for shell path, font size, reduced motion, and visual intensity.
- Verification should include static grep checks for accessibility modifiers and live smoke rather than relying only on visual inspection.

Source:

- https://developer.apple.com/documentation/swiftui/view-accessibility

## Recommended Implementation Shape

### App preferences model

Create a small model for persisted app-frame preferences with deterministic defaults and clamping. Keep pure validation logic testable in `GridOSKit` or another non-app target. The app layer can store values through `@AppStorage` and map them into `TerminalSessionConfiguration` and a RenderCore visual configuration.

Recommended values:

- shell path default: `TerminalSessionConfiguration.default.shellPath`
- terminal font size range: `10...24`, default `13`
- visual intensity range: `0...1`, default around `0.65`
- reduced motion: default `false`, but effective reduced motion must also respect the system environment value

### Render configuration

Add `VisualEffectConfiguration` in `RenderCore` with:

- `intensity: Double`
- `reducedMotion: Bool`
- normalized/clamped values

Thread this into `MetalBackgroundView` and scale/disable event pulse animation. A reduced-motion configuration should still draw a calm background frame but should not animate terminal output pulses.

### Window frame restoration

Add an AppKit bridge view/controller in `GridOSApp`, for example `WindowFrameController` or `WindowAccessor`, that:

- finds the hosting `NSWindow`
- sets `window.titleVisibility`
- sets `window.titlebarAppearsTransparent`
- sets `window.setFrameAutosaveName("gridOS.main")`
- preserves the existing hidden-titlebar direction
- does not steal terminal first responder status

### Production frame layout

Refactor `RootView` into small local app-shell views:

- header/status strip
- terminal workspace
- system strip placeholder
- activity/context panel placeholder

The terminal should remain the dominant area. Placeholders should be intentionally light until later phases provide real metrics and command intelligence.

### Settings scene

Replace placeholder `@State` with persisted settings:

- shell path text field
- font size stepper or slider
- reduced motion toggle
- visual intensity slider
- reset-to-defaults action

Settings changes should apply on next terminal creation at minimum. If live update is simple and does not disrupt the PTY, it may apply visual intensity/reduced motion immediately, but shell path changes should not kill the current shell unexpectedly.

### Keyboard and focus verification

Keep Terminal commands:

- Copy: Command-C
- Paste: Command-V
- Clear: Command-K
- Reset: Option-Command-R

Do not add single-key shortcuts. Any new commands should be menu-visible and terminal-safe.

### Testing and smoke

Automated tests should cover:

- preference clamping/defaults
- render effect configuration reduced-motion behavior
- shell/font preference mapping where practical

Smoke tests should cover:

- app launches with `--cmd`
- shell starts and command reaches PTY
- terminal input still works after frame/settings changes
- app quits cleanly
- window autosave setup is grep-verifiable in source

## Validation Architecture

### Automated checks

- `xcodegen generate --use-cache`
- `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- `git diff --check`

### Source verification checks

- `Sources/GridOSApp/SettingsView.swift` no longer uses placeholder-only `@State` for shell/font values.
- App frame source contains `setFrameAutosaveName` or `saveFrame(usingName:)`.
- RenderCore source contains a reduced-motion/intensity configuration path.
- Settings source contains persisted keys for shell path, font size, reduced motion, and visual intensity.
- UI source contains accessibility labels or values for custom controls/panels.

### Manual/smoke checks

- Launch built `gridOS.app` with `--cmd "echo GRIDOS_PHASE3_SMOKE; exit"` and confirm output path is written.
- Launch normally, confirm a `-zsh` child exists, type `exit`, and confirm child cleanup.
- Sample app CPU after startup to confirm renderer still idles.
- Resize/relaunch smoke: verify source enables window autosave; if feasible, launch, resize, quit, relaunch, and inspect window frame behavior.

## Research Risks

- SwiftUI `@AppStorage` is appropriate for simple settings, but if execution discovers testability or multi-window constraints, use a tiny `UserDefaults` wrapper instead while preserving the same keys and behavior.
- AppKit window autosave is a good baseline, but SwiftUI scene lifecycle can make timing important. Use an `NSViewRepresentable` attached inside the root view after the window exists.
- Accessibility verification cannot be fully proven through unit tests. Combine source checks, focused UI code review, and app smoke.
