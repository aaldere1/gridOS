---
phase: 05-aesthetic-modes
plan: 01
subsystem: rendering
tags: [swift, xcodegen, rendercore, gridoskit, visual-modes, xctest]
requires:
  - phase: 02-metal-identity-mvp
    provides: Metal background renderer, VisualIdentity, ProceduralSeed, and render pulse model
  - phase: 03-production-app-frame
    provides: GridOSAppPreferences and reduced-motion/intensity preference contract
  - phase: 04-real-system-metrics
    provides: terminal-first frame constraints and truthful metrics surfaces for future theming
provides:
  - Public RenderCore registry for exactly Tron, Severance, and Apple-native visual modes
  - Shared VisualTheme token model covering palette, panel, terminal, motion, and shader profiles
  - Deterministic install-derived ProceduralSeed namespace per install seed and mode
  - GridOSKit raw-value preference keys and validation helpers for selected mode and install seed
affects: [phase-05-plan-02-mode-switching, phase-05-plan-03-mode-ui-theming, phase-05-plan-04-screenshot-verification]
tech-stack:
  added: []
  patterns:
    - RenderCore owns typed mode and theme models while GridOSKit owns string-only persistence helpers
    - VisualEffectConfiguration remains the global intensity/reduced-motion gate and composes per-mode motion profiles
key-files:
  created:
    - Sources/RenderCore/VisualTheme.swift
  modified:
    - gridOS.xcodeproj/project.pbxproj
    - Sources/RenderCore/VisualIdentity.swift
    - Sources/RenderCore/ProceduralSeed.swift
    - Sources/RenderCore/VisualEffectConfiguration.swift
    - Sources/RenderCore/MetalBackgroundView.swift
    - Sources/GridOSKit/GridOSAppPreferences.swift
    - Tests/RenderCoreTests/RenderCoreModelTests.swift
    - Tests/GridOSKitTests/GridOSAppPreferencesTests.swift
key-decisions:
  - "Expose exactly Tron, Severance, and Apple-native as public VisualMode cases, with Tron as the default."
  - "Keep GridOSKit preference helpers string-only so RenderCore remains downstream of GridOSKit."
  - "Namespace install-derived visual seeds as gridOS.visual.v1.<installSeed>.<mode> for stable per-install variation."
  - "Compose global visual intensity and reduced-motion settings with per-mode motion profiles instead of replacing the existing scalar contract."
patterns-established:
  - "Mode-specific visual tokens are grouped in VisualTheme and resolved through VisualMode.theme."
  - "Raw persisted visual mode values normalize through GridOSAppPreferences before the app maps them to RenderCore types."
requirements-completed: [PHASE-05]
duration: 5 min
completed: 2026-05-20
---

# Phase 05 Plan 01: Aesthetic Mode Foundation Summary

**RenderCore three-mode visual identity contract with exact mode tokens, deterministic install-derived seeds, and GridOSKit raw preference validation.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-20T16:27:49Z
- **Completed:** 2026-05-20T16:32:48Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Replaced the single public `signalField` mode with exactly `tron`, `severance`, and `appleNative`, including display names, shader values, default `.tron`, and cycle order.
- Added `VisualTheme` and token structs for palette, panel, terminal chrome, motion, and shader profiles with exact Phase 5 token values.
- Added deterministic `ProceduralSeed.installDerived(installSeed:mode:)` using the `gridOS.visual.v1` namespace.
- Threaded per-mode motion and palette data into the Metal background while preserving the existing reduced-motion/intensity contract.
- Added GridOSKit preference keys and string normalization helpers for `appearance.visualMode` and `appearance.installSeed` without importing RenderCore.

## Task Commits

TDD tasks have separate red and green commits:

1. **Task 05-01-01: Create RenderCore mode registry, tokens, seed derivation, and tests**
   - `0a96344` test: failing RenderCore visual mode coverage
   - `4d15d39` feat: RenderCore visual modes and theme implementation
2. **Task 05-01-02: Add visual mode and install seed preference helpers**
   - `bbbb400` test: failing visual preference coverage
   - `8749e41` feat: GridOSKit visual mode preference helpers

## Files Created/Modified

- `Sources/RenderCore/VisualTheme.swift` - Visual token structs and exact Tron, Severance, and Apple-native theme bundles.
- `Sources/RenderCore/VisualIdentity.swift` - Public three-mode registry, default mode, display names, cycle order, shader values, and theme resolution.
- `Sources/RenderCore/ProceduralSeed.swift` - Stable install-derived visual seed generation.
- `Sources/RenderCore/VisualEffectConfiguration.swift` - Per-mode motion-profile pulse composition while keeping reduced-motion suppression.
- `Sources/RenderCore/MetalBackgroundView.swift` - Mode palette, motion, and shader profile data wired into renderer uniforms.
- `Sources/GridOSKit/GridOSAppPreferences.swift` - Exact storage keys, supported raw values, fallback behavior, mode cycling, and install seed trimming.
- `Tests/RenderCoreTests/RenderCoreModelTests.swift` - Regression coverage for modes, tokens, seeds, and reduced-motion pulse suppression.
- `Tests/GridOSKitTests/GridOSAppPreferencesTests.swift` - Regression coverage for preference keys, defaults, raw fallback, cycling, and seed trimming.
- `gridOS.xcodeproj/project.pbxproj` - Regenerated project membership for the new RenderCore source file.

## Decisions Made

- Public Phase 5 modes are exactly the roadmap set: Tron, Severance, and Apple-native.
- Tron is the default public mode and first-launch raw preference value.
- GridOSKit keeps only raw string helpers for mode persistence; app-layer integration will map those strings to RenderCore in Plan 02.
- Install seed generation remains outside GridOSKit; this plan only validates and consumes raw seed strings.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- `gsd-tools state advance-plan`, `state record-metric`, and `state record-session` could not parse this repository's current `STATE.md` shape or missing sections. I updated progress, roadmap, decisions, metrics, and session handoff directly in `STATE.md` and `.planning/ROADMAP.md`.

## Known Stubs

None. Stub scan matched the intentional `defaultInstallSeedRawValue = ""` blank default and the Metal shader multiline string delimiter only; neither is a UI placeholder or goal-blocking stub.

## User Setup Required

None - no external service configuration required.

## Verification

- `xcodegen generate --use-cache` passed.
- `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` passed.
- `rg "case tron|case severance|case appleNative|VisualTheme|VisualMotionProfile" Sources/RenderCore Tests/RenderCoreTests` passed.
- `rg "appearance\\.visualMode|appearance\\.installSeed|@AppStorage" Sources/GridOSApp Sources/GridOSKit Tests/GridOSKitTests` passed.
- `git diff --check` passed.

## Next Phase Readiness

Plan 02 can now compose `VisualIdentity(mode:installSeed:)` from persisted raw values, add `Command-Shift-M` mode cycling, and generate/store the first-launch install seed in the app layer.

No blockers.

## Self-Check: PASSED

- Confirmed all created/modified files listed in this summary exist.
- Confirmed commits `0a96344`, `4d15d39`, `bbbb400`, and `8749e41` exist in git history.

---
*Phase: 05-aesthetic-modes*
*Completed: 2026-05-20*
