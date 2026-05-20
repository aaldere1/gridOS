---
phase: 03
slug: production-app-frame
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 03 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest via Xcode scheme |
| **Config file** | `project.yml` and `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` |
| **Quick run command** | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| **Full suite command** | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` |
| **Estimated runtime** | ~5-20 seconds locally |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- **After every plan wave:** Run `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check`
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 20 seconds locally.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 03-01 | 1 | Persisted app-frame preference model | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` | yes | pending |
| 03-01-02 | 03-01 | 1 | Render reduced-motion/intensity contract | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` | yes | pending |
| 03-01-03 | 03-01 | 1 | AppKit window frame autosave bridge | source + smoke | `rg "setFrameAutosaveName|saveFrame\\(usingName" Sources/GridOSApp` | yes | pending |
| 03-01-04 | 03-01 | 1 | Terminal-first production frame layout | build + source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` | yes | pending |
| 03-01-05 | 03-01 | 1 | Persisted settings UI | source + unit | `rg "@AppStorage|UserDefaults" Sources/GridOSApp/SettingsView.swift` | yes | pending |
| 03-01-06 | 03-01 | 1 | Terminal-safe command/focus policy | smoke | app launch smoke with `--cmd` plus keyboard `exit` child cleanup | yes | pending |
| 03-01-07 | 03-01 | 1 | Accessibility and reduced-motion source coverage | source + build | `rg "accessibilityLabel|accessibilityValue|accessibilityHint|accessibilityReduceMotion" Sources/GridOSApp Sources/RenderCore` | yes | pending |
| 03-01-08 | 03-01 | 1 | Documentation and final verification | full | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` | yes | pending |

*Status: pending until execution.*

---

## Wave 0 Requirements

Existing infrastructure covers this phase:

- `GridOSKitTests`
- `TerminalCoreTests`
- `RenderCoreTests`
- XcodeGen-generated `gridOS` scheme with unit tests

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Window behavior across displays/fullscreen | App feels native in windowed mode, fullscreen, and multiple displays | Requires human-visible window manager behavior | Launch app, enter/exit fullscreen, move window, confirm terminal remains dominant and focused |
| Accessibility quality | Labels/focus/contrast pass | Source checks cannot prove VoiceOver usefulness alone | Use Accessibility Inspector or VoiceOver spot check on settings/header/panels |
| Window size/position restoration | App recovers cleanly after force quit/relaunch | Requires real app lifecycle | Resize window, quit/force quit, relaunch, confirm window frame returns through autosave |

---

## Validation Sign-Off

- [x] All tasks have automated verification or smoke coverage.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target under 20 seconds locally.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-20
