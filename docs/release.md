# gridOS release process

This document starts as a release checklist and should become the operational source of truth before alpha.

## Versioning

Initial version:

- Marketing version: `0.1.0`
- Build number: `1`

Before alpha, decide whether the version source of truth lives in `project.yml`, a generated config file, or CI.

## Local build

```sh
xcodegen generate
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' build
```

For unsigned CI builds:

```sh
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build test
```

The project currently depends on SwiftTerm pinned through XcodeGen/SwiftPM. Regenerate the project after changing `project.yml` so package resolution stays in sync.

## Terminal smoke

Debug builds support a startup command for verification:

```sh
open -n path/to/gridOS.app --args --cmd 'echo ok; exit'
```

This is intended for local smoke tests of the shell bridge, not as a user-facing automation contract yet.

## Visual identity smoke

Phase 2 adds a Metal-backed background through `RenderCore.MetalBackgroundView`. The current smoke bar is:

- app launches without shader setup crashes
- startup command still reaches the shell
- shell child exits after command completion
- app quits cleanly
- app CPU returns to idle after the startup render burst

Recent local Phase 2 evidence:

```text
GRIDOS_PHASE2_SMOKE
APP_SAMPLE=0.0 106496 SN .../gridOS.app/Contents/MacOS/gridOS
```

This is not a substitute for Phase 9 performance hardening; it is only the Phase 2 guardrail that the first renderer does not obviously spin while idle.

## Phase 3 app-frame smoke

Phase 3 adds persisted app-frame settings, hidden-titlebar window autosave, reduced-motion-aware rendering, and accessibility coverage. The current local smoke bar is:

- app launches with the Debug binary and accepts `--cmd`
- startup command writes `GRIDOS_PHASE3_SMOKE` through the terminal path
- app quits cleanly after shell exit
- `SettingsView` persists shell path, font size, reduced motion, and visual intensity through shared keys
- `WindowFrameController` configures `setFrameAutosaveName("gridOS.main")`
- reduced motion suppresses Metal pulse magnitude through `VisualEffectConfiguration`

Smoke command:

```sh
rm -f /tmp/gridos-phase3-smoke.txt
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --cmd "printf 'GRIDOS_PHASE3_SMOKE\n' > /tmp/gridos-phase3-smoke.txt; exit"
cat /tmp/gridos-phase3-smoke.txt
```

## Phase 4 metrics smoke

Phase 4 adds truthful local metrics through `SystemMetrics` and wires them into the app frame. The current smoke bar is:

- app launches with the Debug binary and accepts `--cmd`
- startup command writes `GRIDOS_PHASE4_SMOKE` through the terminal path
- app quits cleanly after shell exit
- `SystemMetricsSnapshot`, `SystemMetricsSampler`, `SystemMetricsSamplingPolicy`, and `NativeSystemMetricsProvider` are present in source
- graceful copy strings are present for `Battery unavailable`, `Thermal unavailable`, `Network idle`, `No process data`, and `Stale`
- metrics sampling stays local-only and no-root; no telemetry, LLM handoff, persistent logs, or shell command provider is used for normal metrics
- idle CPU sampling after startup remains a Phase 9 hardening target, but Phase 4 verifies that startup smoke still completes with metrics integrated

Smoke command:

```sh
rm -f /tmp/gridos-phase4-smoke.txt
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --cmd "printf 'GRIDOS_PHASE4_SMOKE\n' > /tmp/gridos-phase4-smoke.txt; exit"
cat /tmp/gridos-phase4-smoke.txt
```

For automated local verification, quit the launched Debug app through LaunchServices after the smoke file appears and confirm no `gridOS` process remains.

Recent local Phase 4 evidence:

```text
GRIDOS_PHASE4_SMOKE
APP_QUIT=clean
```

## Phase 5 aesthetic mode evidence

Phase 5 adds local aesthetic modes for Tron, Severance, and Apple-native. The release evidence lane verifies the mode contract with automated checks, shared-seed screenshots, same-mode install-variation screenshots, and a human Command-Shift-M terminal-focus smoke.

Final automated commands:

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
rg "case tron|case severance|case appleNative|VisualTheme|VisualMotionProfile" Sources/RenderCore Tests/RenderCoreTests
rg "identity\\.seed\\.normalizedVector|uniforms.seed|testInstallDerivedSeedIsInstallSpecificWithinSameMode" Sources/RenderCore Tests/RenderCoreTests
rg "appearance.visualMode|appearance.installSeed|@AppStorage" Sources/GridOSApp Sources/GridOSKit Tests/GridOSKitTests
rg "keyboardShortcut\\(\"m\", modifiers: \\[\\.command, \\.shift\\]\\)|Cycle Visual Mode" Sources/GridOSApp
rg "accessibilityReduceMotion|reducedMotion|VisualEffectConfiguration" Sources/GridOSApp Sources/RenderCore
.planning/phases/05-aesthetic-modes/capture-mode-evidence.sh
sips -g pixelWidth -g pixelHeight .planning/phases/05-aesthetic-modes/evidence/*.png
```

The mode-comparison screenshots must use the same install seed, `phase5-evidence-shared-seed`, for `tron.png`, `severance.png`, and `apple-native.png`. The install-variation screenshots must use the same raw mode, `tron`, with three different seeds for `tron-install-a.png`, `tron-install-b.png`, and `tron-install-c.png`.

Command-Shift-M terminal-focus smoke:

1. Launch the built Debug app.
2. Click or focus the terminal.
3. Type `echo PHASE5_FOCUS_SMOKE`.
4. Press `Command-Shift-M` at least three times and verify the visual mode indicator cycles.
5. Type `echo PHASE5_FOCUS_AFTER` and confirm shell input still works.
6. Record pass/fail and any focus anomaly in `05-04-SUMMARY.md` or `.planning/phases/05-aesthetic-modes/evidence/README.md`.

Cyberpunk, Matrix, sound themes, plugin/user themes, full light mode, GPU terminal text rendering, marketplace/import themes, and eDEX theme compatibility remain deferred and out of scope for this release evidence lane.

## Production distribution target

The likely 1.0 path is direct Mac distribution:

- archive from clean checkout
- sign with Developer ID Application certificate
- enable hardened runtime
- notarize with Apple
- staple the notarization ticket where applicable
- package as DMG or ZIP
- publish checksum
- verify launch on a clean Gatekeeper-enabled Mac

## Release candidate checklist

- Clean working tree.
- Version and build number incremented.
- Tests passing.
- Performance report captured.
- Dependency licenses reviewed.
- Privacy/security checklist reviewed.
- App archived from clean checkout.
- Code signature verified.
- Notarization accepted.
- Gatekeeper launch tested from downloaded artifact.
- Update flow tested, if updater has shipped.
- Release notes written.
- Rollback/hotfix path documented.

## CI responsibilities

The initial CI skeleton should:

- install XcodeGen
- generate the Xcode project
- build the app with signing disabled
- run unit tests

Release signing and notarization should remain manual or protected until credentials and branch protections are ready.
