---
phase: 03-production-app-frame
plan: 01
subsystem: ui
tags: [swiftui, appkit, appstorage, metal, accessibility, xcodegen]
requires:
  - phase: 01-native-shell-mvp
    provides: SwiftTerm-backed terminal surface and command bridge
  - phase: 02-metal-identity-mvp
    provides: Metal background, render events, and terminal activity pulses
provides:
  - Terminal-first Mac app frame around the existing terminal and Metal renderer
  - Persisted shell, font size, reduced motion, and visual intensity settings
  - AppKit window frame autosave bridge for the main window
  - Reduced-motion and visual-intensity contract for RenderCore pulses
  - Accessibility labels and values for custom frame and settings controls
affects: [phase-04-system-metrics, phase-05-aesthetic-modes, phase-07-session-management, release-readiness]
tech-stack:
  added: []
  patterns:
    - Shared AppStorage keys between RootView and SettingsView
    - Invisible NSViewRepresentable bridge for AppKit window configuration
    - RenderCore visual effect configuration composed by the app target
key-files:
  created:
    - Sources/GridOSKit/GridOSAppPreferences.swift
    - Tests/GridOSKitTests/GridOSAppPreferencesTests.swift
    - Sources/RenderCore/VisualEffectConfiguration.swift
    - Sources/GridOSApp/WindowFrameController.swift
  modified:
    - Sources/GridOSApp/GridOSApp.swift
    - Sources/GridOSApp/RootView.swift
    - Sources/GridOSApp/SettingsView.swift
    - Sources/RenderCore/MetalBackgroundView.swift
    - Tests/RenderCoreTests/RenderCoreModelTests.swift
    - docs/architecture.md
    - docs/release.md
    - .planning/STATE.md
key-decisions:
  - "Persist Phase 3 preferences with shared AppStorage keys and pure GridOSKit defaults/clamping."
  - "Use AppKit window frame autosave through WindowFrameController rather than custom window-state serialization."
  - "Combine app reduced-motion preference with system accessibilityReduceMotion before driving RenderCore."
patterns-established:
  - "Preference validation belongs in GridOSKit; SwiftUI views bind persisted values through shared keys."
  - "RootView composes module APIs and keeps terminal/rendering internals inside TerminalCore and RenderCore."
  - "Reduced motion still draws a static background frame while suppressing repeating pulse animation."
requirements-completed: [PHASE-03]
duration: 7 min
completed: 2026-05-20
---

# Phase 03 Plan 01: Production App Frame Summary

**Terminal-first Mac app frame with persisted preferences, AppKit window autosave, reduced-motion-aware Metal pulses, and accessible settings.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-20T14:41:45Z
- **Completed:** 2026-05-20T14:48:41Z
- **Tasks:** 8
- **Files modified:** 13

## Accomplishments

- Added `GridOSAppPreferences` and tests for default shell, font-size clamping, visual-intensity clamping, and reduced-motion storage.
- Added `VisualEffectConfiguration` so app/user reduced-motion and intensity settings directly affect Metal pulse behavior.
- Added `WindowFrameController` for hidden-titlebar chrome and `gridOS.main` frame autosave without stealing terminal focus.
- Refactored `RootView` into a terminal-first frame with header, system strip, activity panel, and dominant terminal workspace.
- Replaced Settings placeholders with persisted Terminal, Appearance, and Recovery controls.
- Kept terminal commands menu-visible through `TerminalCommands` while preserving SwiftTerm first-responder behavior.
- Added accessibility labels/values for custom frame regions, visual mode indicator, and persisted settings controls.
- Updated architecture/release/state docs and verified build, tests, source checks, diff hygiene, and launch smoke.

## Task Commits

Each task was committed atomically:

1. **Task 03-01-01: Create testable app preference model** - `b954f36` (feat)
2. **Task 03-01-02: Add reduced-motion and intensity contract to RenderCore** - `95eb32a` (feat)
3. **Task 03-01-03: Add AppKit window frame restoration bridge** - `37b62a7` (feat)
4. **Task 03-01-04: Refactor RootView into terminal-first production frame** - `f2a13d4` (feat)
5. **Task 03-01-05: Replace Settings placeholders with persisted controls** - `8786aae` (feat)
6. **Task 03-01-06: Harden terminal command menu and focus policy** - `9b6ebdc` (refactor)
7. **Task 03-01-07: Add accessibility labels and reduced-motion verification points** - `dd4639e` (feat)
8. **Task 03-01-08: Regenerate project, update docs, and run final verification** - `6e6476b` (docs)

## Files Created/Modified

- `Sources/GridOSKit/GridOSAppPreferences.swift` - Preference defaults, clamping, shell fallback, and reduced-motion storage.
- `Tests/GridOSKitTests/GridOSAppPreferencesTests.swift` - Regression tests for preference defaults and clamping.
- `Sources/RenderCore/VisualEffectConfiguration.swift` - Reduced-motion and intensity contract for render pulses.
- `Sources/RenderCore/MetalBackgroundView.swift` - Metal pulse recording now respects visual effect configuration.
- `Tests/RenderCoreTests/RenderCoreModelTests.swift` - Render effect configuration tests.
- `Sources/GridOSApp/WindowFrameController.swift` - AppKit window chrome and frame autosave bridge.
- `Sources/GridOSApp/RootView.swift` - Terminal-first app frame, persisted preference mapping, reduced-motion composition, and accessibility labels.
- `Sources/GridOSApp/SettingsView.swift` - Persisted settings form for terminal, appearance, and recovery controls.
- `Sources/GridOSApp/GridOSApp.swift` - Private `TerminalCommands` command menu.
- `gridOS.xcodeproj/project.pbxproj` - Regenerated project membership for new source and test files.
- `docs/architecture.md` - Phase 3 architecture target.
- `docs/release.md` - Phase 3 app-frame smoke process.
- `.planning/STATE.md` - Phase 3 execution evidence and decisions.

## Decisions Made

- Persisted settings use `@AppStorage` directly for Phase 3 because the phase needs one local default profile, not named profile management.
- Shell path changes are mapped into `TerminalSessionConfiguration` for new terminal creation; the app does not kill a running shell when Settings changes.
- Reduced motion is effective when either system accessibility or app preference is enabled.
- Window restoration uses AppKit frame autosave because it is the native recovery path for size and position.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `xcodegen generate --use-cache` passed.
- `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` passed.
- `git diff --check` passed.
- `rg "setFrameAutosaveName|@AppStorage|VisualEffectConfiguration|accessibilityReduceMotion" Sources` passed.
- Launch smoke wrote `GRIDOS_PHASE3_SMOKE` to `/tmp/gridos-phase3-smoke.txt` and the Debug app quit cleanly.

## Next Phase Readiness

Phase 4 can replace the Phase 3 system strip placeholder with truthful metrics using the app-frame, settings, accessibility, and window recovery baseline now in place.

No blockers.

---
*Phase: 03-production-app-frame*
*Completed: 2026-05-20*
