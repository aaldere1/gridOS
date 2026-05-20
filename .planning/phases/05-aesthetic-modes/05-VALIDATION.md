---
phase: 05
slug: aesthetic-modes
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-20
---

# Phase 05 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest via Xcode scheme |
| **Config file** | `project.yml` and `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` |
| **Quick run command** | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| **Full suite command** | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` |
| **Estimated runtime** | ~90-180 seconds |

## Sampling Rate

- **After every task commit:** Run `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- **After every plan wave:** Run `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check`
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 180 seconds for automated build/test feedback.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | Mode registry exposes exactly `tron`, `severance`, and `appleNative` with default `.tron` | unit | Full suite command plus `rg "case tron|case severance|case appleNative|VisualTheme|VisualMotionProfile" Sources/RenderCore Tests/RenderCoreTests` | yes, extend `Tests/RenderCoreTests/RenderCoreModelTests.swift` | pending |
| 05-01-02 | 01 | 1 | Local preferences parse selected mode and stable install seed safely | unit | Full suite command plus `rg "appearance.visualMode|appearance.installSeed|defaultVisualModeRawValue" Sources/GridOSKit Tests/GridOSKitTests` | yes, extend `Tests/GridOSKitTests/GridOSAppPreferencesTests.swift` | pending |
| 05-02-01 | 02 | 2 | `RootView` composes selected mode and install-derived `VisualIdentity` from `@AppStorage` | unit/source | Full suite command plus `rg "appearance.visualMode|appearance.installSeed|VisualIdentity\\(" Sources/GridOSApp/RootView.swift` | source exists, tests may be model/source checks | pending |
| 05-02-02 | 02 | 2 | `Command-Shift-M` menu command cycles visual modes without shell command changes | source/smoke | Full suite command plus `rg "Cycle Visual Mode|keyboardShortcut\\(\"m\", modifiers: \\[\\.command, \\.shift\\]\\)" Sources/GridOSApp` | no dedicated test target | pending |
| 05-03-01 | 03 | 3 | App frame applies mode-specific tokens to header, metrics, activity, and terminal chrome without shrinking terminal layout | unit/source/manual | Full suite command plus screenshot review | source exists, manual screenshot required | pending |
| 05-03-02 | 03 | 3 | Metal shader compiles and branches visibly for all modes while reduced motion suppresses pulse animation | unit/manual | Full suite command plus `rg "uniforms.mode|shaderValue|reducedMotion" Sources/RenderCore Tests/RenderCoreTests` | yes, extend shader compile/model tests | pending |
| 05-04-01 | 04 | 4 | Three mode screenshots are captured and reviewed for visible difference and readable terminal/metrics text | manual/semi-scripted | `sips -g pixelWidth -g pixelHeight .planning/phases/05-aesthetic-modes/evidence/*.png` after screenshots exist | evidence directory not yet present | pending |

## Wave 0 Requirements

- [ ] `Tests/RenderCoreTests/RenderCoreModelTests.swift` covers mode cases, default `.tron`, display names, cycling order, theme token uniqueness, install-derived seed stability/distinction, reduced-motion pulse behavior, and shader compilation.
- [ ] `Tests/GridOSKitTests/GridOSAppPreferencesTests.swift` covers `appearance.visualMode` raw fallback, default mode raw value, and install seed default behavior.
- [ ] Source-check commands are listed in the plan verification criteria so the executor can prove shortcut keys, storage keys, and mode cases are present.
- [ ] No new test framework is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual distinctness across `Tron`, `Severance`, and `Apple-native` | Three screenshots from the same app are visibly different by mode | Pixel-perfect assertions are premature; visual taste and text readability need human review | Build Debug, set `appearance.visualMode` to each raw value, launch app, capture screenshots into `.planning/phases/05-aesthetic-modes/evidence/`, and review terminal/metrics readability in each |
| `Command-Shift-M` does not steal terminal focus | Mode switching is fast and stable without shell disruption | Existing app has no UI automation target for first responder or terminal bytes | Launch app, type in terminal, press `Command-Shift-M` repeatedly, confirm mode indicator changes and shell input remains usable |
| Stable per-install variation | Three installs in same mode are subtly distinct while same install stays stable | Requires comparing screenshots with different install seeds | Use different `appearance.installSeed` values, capture same-mode screenshots, confirm subtle but visible variation without readability loss |

## Recommended Source Checks

```bash
rg "case tron|case severance|case appleNative|VisualTheme|VisualMotionProfile" Sources/RenderCore Tests/RenderCoreTests
rg "appearance.visualMode|appearance.installSeed|@AppStorage" Sources/GridOSApp Sources/GridOSKit Tests/GridOSKitTests
rg "keyboardShortcut\\(\"m\", modifiers: \\[\\.command, \\.shift\\]\\)|Cycle Visual Mode" Sources/GridOSApp
rg "accessibilityReduceMotion|reducedMotion|VisualEffectConfiguration" Sources/GridOSApp Sources/RenderCore
```

## Validation Sign-Off

- [x] All planned work has automated verification or explicit manual evidence.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers missing automated model and preference coverage.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 180 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending Phase 5 execution evidence.
