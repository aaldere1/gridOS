---
status: passed
phase: 02-metal-identity-mvp
verified: 2026-05-20
---

# Phase 2 verification - Metal identity MVP

## Goal

Prove gridOS can have a distinctive native visual identity without weakening terminal usability.

## Must-Haves

| Requirement | Evidence | Status |
| --- | --- | --- |
| One Metal background shader renders behind or around the terminal. | `RenderCore.MetalBackgroundView` hosts `MTKView`; `MetalBackgroundRenderer` compiles and draws the embedded `Signal Field` shader. | Passed |
| Procedural install seed exists. | `ProceduralSeed` supports deterministic stable-string seeds and normalized shader vectors. | Passed |
| Terminal activity can trigger subtle visual effects. | `TerminalActivityEvent` is emitted by `TerminalSurface`; `RootView` maps input/output/resize/process events to `RenderEvent`. | Passed |
| Renderer idles responsibly. | `MetalBackgroundView.Coordinator` uses a short timer burst after events and invalidates the timer when animation decays. Idle sample after startup burst showed app `%CPU` at `0.0`. | Passed |
| Terminal correctness is not coupled to shader work. | `TerminalCore` has no `RenderCore` dependency; app shell composes the modules. | Passed |

## Automated Checks

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
```

Result: passed with 13 unit tests.

## Smoke Checks

Launch command:

```sh
gridOS.app/Contents/MacOS/gridOS --cmd "printf 'GRIDOS_PHASE2_SMOKE\n' > /tmp/gridos-phase2-smoke.txt; exit"
```

Evidence:

- `/tmp/gridos-phase2-smoke.txt` contained `GRIDOS_PHASE2_SMOKE`.
- Shell child was gone after command completion.
- App process quit cleanly.

Idle sample command launched the app with a sleeping shell, waited for the startup render burst to decay, then sampled the process:

```text
APP_SAMPLE=0.0 106496 SN .../gridOS.app/Contents/MacOS/gridOS
CHILD_SAMPLE=... -zsh
```

## Residual Risk

- Visual quality still needs human review in a real window before alpha.
- The idle CPU sample is a narrow local check, not a performance report. Phase 9 still owns full performance hardening.
- Phase 5 still owns multiple polished aesthetic modes.
