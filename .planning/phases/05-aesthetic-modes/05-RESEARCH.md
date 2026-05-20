# Phase 05: Aesthetic Modes - Research

**Researched:** 2026-05-20
**Domain:** macOS SwiftUI app theming, Metal visual identity, local preference persistence
**Confidence:** HIGH for codebase architecture and implementation shape; MEDIUM for screenshot automation because macOS window capture remains partly manual.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Mode Taste and References
- **D-01:** Ship exactly three user-facing modes in Phase 5: `Tron`, `Severance`, and `Apple-native`. `Cyberpunk` and `Matrix` are visible in the long-term vision but deferred.
- **D-02:** Interpret `Tron` as an original cyber-grid homage, not a copy of Disney Tron, eDEX-UI code/assets, or exact theme files. It should use dark surfaces, cyan/blue luminous structure, vector grid/circuit rhythm, and restrained amber highlights only when they help scanning.
- **D-03:** Interpret `Severance` as austere corporate systems design, not a literal replica of the show. It should feel monochrome, precise, fluorescent, bureaucratic, and slightly uncanny, with minimal motion and one dim accent.
- **D-04:** Interpret `Apple-native` as the work-safe first-party-feeling mode. It should be calm enough for real terminal work, use disciplined macOS spacing/material restraint, and stay dark-first in Phase 5 while leaving room for a future adaptive light/dark implementation.
- **D-05:** Modes must be coherent systems, not color swaps. At minimum each mode should vary palette, Metal background behavior, panel/border treatment, mode display copy, motion profile, and procedural seed mapping.

### Mode Switching and Persistence
- **D-06:** `Command-Shift-M` is the required mode switcher. It should cycle modes instantly and predictably without stealing terminal focus.
- **D-07:** The selected mode should persist locally using the existing preferences pattern. Relaunching the app should restore the last selected mode.
- **D-08:** Add a menu-visible mode command so the shortcut is discoverable through native macOS menus. A simple Settings picker is acceptable if it stays small and reuses existing `@AppStorage` patterns.
- **D-09:** Default to a product-forward cyber mode for first launch. Existing `Signal Field` can either become the internal foundation for `Tron` or remain an implementation detail, but the user-facing Phase 5 modes should be the roadmap names.

### Theming Scope and Terminal Protection
- **D-10:** Modes should affect the app frame enough that three screenshots from the same app are visibly different: background, header indicator, accent colors, panel separators, metrics strip treatment, and activity panel treatment.
- **D-11:** Modes must never obscure terminal text, shrink terminal usable space, or fight shell keyboard behavior. Terminal readability and focus remain the highest priority.
- **D-12:** Phase 5 may tune terminal container colors and chrome, but it should not replace SwiftTerm rendering or implement custom GPU text rendering. GPU terminal text remains later vision work.
- **D-13:** Real Phase 4 metrics remain truthful and text-forward in every mode. Decorative effects must not make CPU/MEM/NET/BAT/THERM or top-process rows hard to read.

### Motion, Intensity, and Procedural Variation
- **D-14:** Each mode needs a distinct motion profile: `Tron` can pulse moderately with terminal activity, `Severance` should be mostly static/minimal, and `Apple-native` should use subtle quiet motion.
- **D-15:** The existing global visual-intensity setting remains a scalar across all modes. Reduced motion must suppress animation across every mode while preserving a static visual identity.
- **D-16:** Procedural variation should be stable per install, not random per launch. If a privacy-safe hardware-derived seed is not available yet, a first-launch locally persisted UUID/seed is acceptable for Phase 5.
- **D-17:** Per-install variation should be subtle but visible within each mode: palette offsets, field geometry, line cadence, micro-detail density, or motion curves. It must not break brand coherence or create unreadable combinations.

### Verification Direction
- **D-18:** Phase 5 verification should prove three modes exist, switching is fast/stable, selected mode persists, reduced motion still works, and visual effects do not obscure terminal and metrics text.
- **D-19:** Screenshot evidence is important for this phase. Planning should include a repeatable local way to capture or compare mode screenshots if feasible on macOS.

### Claude's Discretion
- Exact shader math, token names, palette values, and mode registry shape are left to the implementation agent, constrained by the decisions above.
- Exact Apple-native visual treatment is left to implementation taste as long as it is calm, dark-first for Phase 5, and recognizably macOS-native.
- Whether the existing `Signal Field` mode is renamed, migrated, or kept as an internal fallback is left to planning/implementation.

### Deferred Ideas (OUT OF SCOPE)
- Cyberpunk and Matrix modes — present in the long-term vision but outside the Phase 5 production roadmap scope.
- Sound themes and UI audio — separate future work.
- User-authored themes or plugin theme APIs — later plugin/theme infrastructure.
- Full light-mode support for Apple-native — future adaptive appearance work unless planning finds a tiny safe path.
- GPU-accelerated custom terminal text rendering — long-term rendering work, not Phase 5.
- Theme marketplace, imported theme files, or eDEX theme compatibility — out of scope.
</user_constraints>

## Summary

Phase 5 should extend the existing Phase 2/3/4 architecture rather than introduce a theme engine or new dependency. The current code already has the right seams: `RenderCore.VisualMode`, `VisualIdentity`, `ProceduralSeed`, `VisualEffectConfiguration`, and `MetalBackgroundView`; `GridOSKit.GridOSAppPreferences`; and app-level `@AppStorage` usage in `RootView` and `SettingsView`. The missing pieces are a real mode registry/token model, a locally persisted selected mode and install seed, mode-aware app-frame styling, and a native menu command for `Command-Shift-M`.

The safest implementation shape is to keep all visual-mode semantics in `RenderCore`, keep persistence keys and validation in `GridOSKit`, and let `GridOSApp` compose tokens into SwiftUI colors, borders, terminal chrome, metrics surfaces, and the Metal renderer. The app should continue to treat SwiftTerm text as the readable foreground surface. Modes may tune terminal container colors and caret/accent chrome, but they should not modify terminal layout, replace terminal rendering, or add custom text effects.

**Primary recommendation:** Build one small visual token registry first, then thread it through persistence, menu switching, settings, app-frame styling, Metal uniforms, tests, and screenshot evidence in that order.

## Phase Requirements

No explicit requirement IDs were mapped in this roadmap. Planning should map the Phase 5 deliverables directly:

| Deliverable | Research Support |
|---|---|
| Mode registry and shared visual token model | Use `RenderCore` owned `VisualMode`, `VisualTheme`, `MotionProfile`, and mode-derived `VisualIdentity`. |
| Tron, Severance, Apple-native modes | Ship exactly these three public enum cases; treat current `signalField` as internal legacy/foundation or migrate it to `tron`. |
| `Command-Shift-M` switcher | Extend SwiftUI app commands with a menu-visible button using `.keyboardShortcut("m", modifiers: [.command, .shift])`. |
| Local persistence | Add `appearance.visualMode` and `appearance.installSeed` keys using the existing `@AppStorage`/`GridOSAppPreferences` pattern. |
| Per-mode motion/effects | Extend `VisualEffectConfiguration` or add `VisualMotionProfile` so global intensity and reduced motion scale mode defaults. |
| Stable per-install variation | Persist a locally generated UUID/seed and derive per-mode `ProceduralSeed` values from it. |

## Project Constraints

- No `AGENTS.md`, `CLAUDE.md`, `.claude/skills`, or `.agents/skills` were found in the repo.
- `project.yml` is authoritative. If Phase 5 adds files or test targets, update `project.yml` and run `xcodegen generate --use-cache`.
- Module boundaries from `docs/architecture.md` remain active: `RenderCore` owns shader/mode/procedural identity; `GridOSKit` owns shared preference models; `GridOSApp` composes features; `TerminalCore` must not depend on `RenderCore`.
- Non-negotiables from `.planning/PROJECT.md`: do not copy eDEX-UI code/assets/theme files, terminal correctness beats visual effects, privacy defaults stay conservative, and the app must remain useful without LLM configuration.

## Current Codebase Findings

### Existing Seams

- `Sources/RenderCore/VisualIdentity.swift` currently exposes `VisualMode.signalField`, `displayName`, `shaderValue`, and `VisualIdentity.default`.
- `Sources/RenderCore/ProceduralSeed.swift` already provides deterministic FNV-1a style seed creation from stable strings and a normalized `SIMD2<Float>` for shader input.
- `Sources/RenderCore/VisualEffectConfiguration.swift` already clamps global intensity and suppresses pulse magnitude when reduced motion is enabled.
- `Sources/RenderCore/MetalBackgroundView.swift` already passes `identity.mode.shaderValue`, seed vector, pulse, time, and resolution into the Metal shader.
- `Sources/GridOSApp/RootView.swift` currently hardcodes `VisualIdentity.default`, passes it to `MetalBackgroundView`, and displays `visualIdentity.mode.displayName` in the header.
- `Sources/GridOSApp/GridOSApp.swift` already has a `TerminalCommands` command menu with native keyboard shortcuts. Add a separate `Appearance` or `View` command group/menu for mode cycling.
- `Sources/GridOSApp/SettingsView.swift` already uses shared `@AppStorage` keys for appearance controls.
- `Sources/GridOSKit/GridOSAppPreferences.swift` already owns defaults and clamping for shell/font/intensity/reduced motion.

### Current Gaps

- No selected visual mode preference exists.
- No stable per-install seed preference exists.
- No token model exists for app-frame colors, borders, opacity, terminal chrome, metric accents, or motion profile.
- `MetalBackgroundRenderer.shaderSource` has only one real visual treatment, despite a `mode` uniform.
- Tests currently only assert default `signalField`; they need coverage for all three Phase 5 modes and mode-derived token uniqueness.

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Swift / SwiftUI / AppKit | Swift 6.3.2 locally, project `SWIFT_VERSION: 6.0` | macOS app UI, menu commands, settings, local state binding | Existing native app stack; matches Mac-only product promise. |
| MetalKit / `MTKView` | macOS SDK 26.5 locally, deployment macOS 14.0 | GPU background and procedural mode rendering | Already used by `RenderCore`; Apple documents `MTKView` as the standard Metal display view and supports explicit drawing. |
| `RenderCore` local framework | project-local | Visual modes, shader host, procedural identity, motion configuration | Existing boundary for all rendering and visual identity logic. |
| `GridOSKit` local framework | project-local | Shared preference defaults, clamping, persistence model | Existing testable shared model boundary. |
| SwiftTerm | 1.13.0 | Stable terminal surface | Existing terminal backend; Phase 5 must protect it rather than replace it. |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---|---:|---|---|
| XcodeGen | 2.45.3 | Generate `gridOS.xcodeproj` from `project.yml` | Whenever adding files, targets, or changing package structure. |
| XCTest | Xcode 26.5 local | Unit tests for mode registry, preferences, seed derivation, shader compilation | Required for Wave 0 and per-task verification. |
| `screencapture`, `sips`, `osascript` | macOS built-ins present | Screenshot evidence and lightweight artifact checks | Use for manual or semi-scripted mode screenshot proof. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Local Swift models | External theming library | Not needed; adds dependency and does not solve Metal shader/token integration. |
| `@AppStorage` + `GridOSAppPreferences` | SwiftData | Too heavy for two primitive local settings. |
| Persisted random install seed | Hardware-derived ID + HMAC now | Better long-term privacy design, but Phase 5 context explicitly allows a locally persisted UUID/seed and avoids hardware fingerprinting risk. |
| SwiftUI-only backgrounds | More custom SwiftUI materials | Fails the product's Metal identity direction and existing `RenderCore` investment. |

**Version verification:**

- `xcodebuild -list -project gridOS.xcodeproj` resolved `SwiftTerm @ 1.13.0` and `swift-argument-parser @ 1.7.1`.
- `git ls-remote --tags https://github.com/migueldeicaza/SwiftTerm.git` confirmed `refs/tags/v1.13.0` at commit `8e7a1e154f470e19c709a00a8768df348ba5fc43`; GitHub commit API reports commit date `2026-03-27T12:43:23Z`.
- Local tool audit: XcodeGen `2.45.3`, Xcode `26.5`, Swift `6.3.2`, Metal device `Apple M2 Ultra`.

**Installation:** No new package installation is recommended for Phase 5.

## Architecture Patterns

### Recommended Project Structure

```text
Sources/
├── RenderCore/
│   ├── VisualIdentity.swift          # VisualMode, VisualIdentity, registry entry points
│   ├── VisualTheme.swift             # Palette, panel, terminal chrome, motion tokens
│   ├── ProceduralSeed.swift          # Existing seed primitive plus derivation helper
│   ├── VisualEffectConfiguration.swift
│   └── MetalBackgroundView.swift     # Shader mode branching and mode uniforms
├── GridOSKit/
│   └── GridOSAppPreferences.swift    # selected mode and install seed defaults/parsing
└── GridOSApp/
    ├── GridOSApp.swift               # Appearance commands and Command-Shift-M
    ├── RootView.swift                # @AppStorage mode/seed composition and themed frame
    └── SettingsView.swift            # Appearance picker and optional identity reset

Tests/
├── RenderCoreTests/
│   └── RenderCoreModelTests.swift    # modes, tokens, seed derivation, shader compile
└── GridOSKitTests/
    └── GridOSAppPreferencesTests.swift
```

### Pattern 1: Registry-Owned Visual Tokens

**What:** Make `VisualMode` the public case list and expose a registry-derived token bundle for each mode. Keep token generation pure and deterministic.

**When to use:** Always. This phase needs coherent systems, not scattered `switch mode` color literals in SwiftUI views.

**Implementation implication:** Add a `VisualTheme` or `VisualModeTheme` in `RenderCore` with palette, panel, terminal, motion, and shader parameters. `RootView` should consume one token object, not re-decide colors independently.

```swift
public enum VisualMode: String, CaseIterable, Equatable, Sendable, Identifiable {
    case tron
    case severance
    case appleNative

    public var id: String { rawValue }
    public static let defaultMode: VisualMode = .tron

    public var displayName: String {
        switch self {
        case .tron: "Tron"
        case .severance: "Severance"
        case .appleNative: "Apple-native"
        }
    }
}

public struct VisualTheme: Equatable, Sendable {
    public let mode: VisualMode
    public let palette: VisualPalette
    public let panel: VisualPanelStyle
    public let terminal: VisualTerminalChrome
    public let motion: VisualMotionProfile
}
```

### Pattern 2: Mode Persistence Through Existing Preference Keys

**What:** Store the selected mode as a raw string in `@AppStorage("appearance.visualMode")`, parse it through `GridOSAppPreferences`, and fall back to `.tron` for unknown values.

**When to use:** For the selected visual mode and stable install seed. Apple documents `@AppStorage` as a SwiftUI property wrapper that reflects `UserDefaults` and invalidates views when the value changes, which fits this small local preference.

**Implementation implication:** Do not introduce a profile system or database. Add pure tests for raw-value parsing and defaults.

```swift
@AppStorage("appearance.visualMode") private var visualModeRawValue = GridOSAppPreferences.defaultVisualModeRawValue
@AppStorage("appearance.installSeed") private var installSeedRawValue = GridOSAppPreferences.defaultInstallSeedRawValue

private var visualMode: VisualMode {
    GridOSAppPreferences.visualMode(from: visualModeRawValue)
}
```

### Pattern 3: Local Install Seed Derivation

**What:** Generate a UUID/string on first launch if the stored seed is empty, then derive per-mode procedural seeds from `installSeed + mode.rawValue + versionedSalt`.

**When to use:** Phase 5 needs stable per-install variation without hardware fingerprinting. The roadmap's HMAC/Keychain design can remain a later hardening upgrade.

**Implementation implication:** Add an app-layer first-launch initializer or model helper that writes `appearance.installSeed` once. Derive `ProceduralSeed(stableString:)` in `RenderCore` or `GridOSKit`, but never expose raw machine identifiers.

```swift
public extension ProceduralSeed {
    static func installDerived(installSeed: String, mode: VisualMode) -> ProceduralSeed {
        ProceduralSeed(stableString: "gridOS.visual.v1.\(installSeed).\(mode.rawValue)")
    }
}
```

### Pattern 4: Native Command Menu for Mode Cycling

**What:** Add a menu-visible command, preferably in an `Appearance` command menu or existing app command placement, that cycles the stored mode. Use `Command-Shift-M`.

**When to use:** Required by D-06 and D-08. Apple documents `CommandMenu` as a macOS menu-bar command container, and its tutorial guidance notes that shortcuts help users discover frequent actions in menus.

**Implementation implication:** The command should update app preference state only. It should not call into `TerminalCore`, make the terminal resign first responder, or send bytes to the shell.

```swift
Button("Cycle Visual Mode") {
    VisualModeCommandCenter.cycle()
}
.keyboardShortcut("m", modifiers: [.command, .shift])
```

Planner note: a simple `NotificationCenter` command center is consistent with `TerminalCommandCenter`, but selected-mode state can also be shared via `@AppStorage`. Avoid global mutable state unless needed to bridge `Commands` into views.

### Pattern 5: Reduced-Motion and Intensity Remain Multipliers

**What:** Per-mode motion profiles should define defaults, but `VisualEffectConfiguration` remains the final gate. Reduced motion returns zero pulse animation in every mode; global intensity scales all pulses/effects.

**When to use:** Always. This preserves Phase 3 validated behavior and D-15.

**Implementation implication:** Add mode-specific properties such as `pulseDecay`, `basePulse`, `eventGain`, `idleDrift`, or `detailDensity`, then clamp them through the existing configuration before reaching timers/shaders.

### Anti-Patterns to Avoid

- **Scattered switch statements in SwiftUI views:** This becomes untestable and makes screenshots inconsistent. Use tokens.
- **Changing SwiftTerm internals for mode flavor:** This risks shell correctness and violates D-12.
- **Random seed on every launch:** Fails stable identity and screenshot reproducibility.
- **Decorative text or fake metrics per mode:** Phase 4 metrics must remain truthful and text-forward.
- **A global animated timer per mode:** `MTKView` should stay explicit/burst-driven where possible. Apple documents explicit drawing with `isPaused = true` for custom workflows; keep the current idle behavior.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Terminal theming engine | Custom renderer, custom terminal text pipeline, ANSI parser changes | SwiftTerm plus container/accent token tweaks | Terminal correctness is already proven through SwiftTerm; custom text is deferred. |
| General theme marketplace/API | User-authored theme schema, import/export, plugins | Three hardcoded registry entries | Public theme APIs are roadmap-deferred and expensive to stabilize. |
| Persistence framework | SwiftData/profile database | `@AppStorage` + `GridOSAppPreferences` pure parsing | Only primitive local preferences are needed. |
| Hardware identity system | Serial/hardware UUID collection | First-launch local random UUID/seed | Avoids fingerprinting and meets D-16. |
| Animation scheduler | Always-on `CADisplayLink`/timer loop | Existing `MTKView.draw()` plus burst timer | Protects idle CPU and Phase 2 evidence. |
| Screenshot diff framework | Heavy image-comparison harness | Manual screenshots plus `screencapture`/`sips` metadata and source/test checks | Phase 5 needs visual evidence, not pixel-perfect regression infra yet. |

**Key insight:** The phase succeeds by centralizing visual decisions, not by expanding rendering ambition. A small token registry that feeds both SwiftUI chrome and Metal shader uniforms is the leverage point.

## Common Pitfalls

### Pitfall 1: Modes Become Color Swaps

**What goes wrong:** Tron, Severance, and Apple-native only change accent colors while the app still reads as the same cyber panel.
**Why it happens:** Palette literals are changed without motion, panel, terminal chrome, and shader behavior tokens.
**How to avoid:** Require mode-unique palette, panel treatment, motion profile, shader branch, and display copy. Add tests that every public mode has unique shader value, display name, and theme token signature.
**Warning signs:** Screenshots differ only in cyan vs gray accents.

### Pitfall 2: Mode Switching Steals Shell Focus

**What goes wrong:** Pressing `Command-Shift-M` changes focus, sends text to shell, or interrupts typing.
**Why it happens:** Mode switching is implemented as a visible SwiftUI control/action inside the terminal layout instead of a menu command changing local app state.
**How to avoid:** Keep switching in `Commands`/preference state and smoke test a live terminal after switching.
**Warning signs:** First responder changes from `GridOSTerminalView`, keyboard input stops, or the shell receives `M`.

### Pitfall 3: Reduced Motion Only Hides One Animation

**What goes wrong:** The shader still drifts/pulses in reduced-motion mode because only SwiftUI animation is disabled.
**Why it happens:** Per-mode motion profile bypasses `VisualEffectConfiguration`.
**How to avoid:** Route every pulse/timer decision through `VisualEffectConfiguration` and add reduced-motion assertions for each mode profile.
**Warning signs:** Repeating timer starts when reduced motion is true.

### Pitfall 4: Install Variation Is Unstable

**What goes wrong:** Screenshots change after relaunch, making the product feel random rather than personal.
**Why it happens:** Seed uses `UUID()` or timestamp during view construction rather than persisted first-launch state.
**How to avoid:** Persist the install seed once and derive all mode seeds from it. Add tests for same seed/same mode stability and same seed/different mode distinction.
**Warning signs:** `UUID()` appears in `RootView.body` or `VisualIdentity.default`.

### Pitfall 5: Metal Branching Breaks Shader Compile

**What goes wrong:** A new shader mode compiles on one machine but not in tests.
**Why it happens:** Shader code grows with untested branches or mismatched uniform layout.
**How to avoid:** Keep one uniform struct, use numeric mode parameters conservatively, and extend the existing Metal shader compile test.
**Warning signs:** `MetalBackgroundRenderer.shaderSource` changes without test updates.

### Pitfall 6: Metrics Become Decorative

**What goes wrong:** Mode styling makes CPU/MEM/NET/BAT/THERM or top-process rows low contrast, tiny, or visually secondary to effects.
**Why it happens:** Decorative effects are tested in isolation, not over real Phase 4 panels.
**How to avoid:** Treat metric text as foreground content with stable high contrast in every mode and include screenshot review with real metrics visible.
**Warning signs:** Mode tokens set metric text opacity below the current readable baseline.

## Code Examples

### Mode Cycling

```swift
public extension VisualMode {
    func next() -> VisualMode {
        let allModes = Self.allCases
        guard let currentIndex = allModes.firstIndex(of: self) else {
            return Self.defaultMode
        }

        let nextIndex = allModes.index(after: currentIndex)
        return nextIndex == allModes.endIndex ? allModes[allModes.startIndex] : allModes[nextIndex]
    }
}
```

### Preference Parsing

```swift
public static let defaultVisualModeRawValue = VisualMode.defaultMode.rawValue
public static let defaultInstallSeedRawValue = ""

public static func visualMode(from rawValue: String) -> VisualMode {
    VisualMode(rawValue: rawValue) ?? .defaultMode
}
```

### First-Launch Seed Initialization

```swift
.onAppear {
    if installSeedRawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        installSeedRawValue = UUID().uuidString
    }
}
```

Planner note: keep this app-layer write small and deterministic. Tests should cover the pure derivation, not SwiftUI lifecycle timing.

### Mode-Aware Identity Composition

```swift
private var visualIdentity: VisualIdentity {
    VisualIdentity(
        mode: visualMode,
        seed: .installDerived(installSeed: installSeedRawValue, mode: visualMode)
    )
}

private var visualTheme: VisualTheme {
    VisualTheme.theme(for: visualIdentity)
}
```

## Recommended Plan Breakdown

1. **Wave 0: Model/test foundation**
   Add or extend tests for `VisualMode` cases, default `.tron`, display names, cycling order, raw-value fallback, theme uniqueness, per-install seed derivation, and reduced-motion profile behavior.

2. **Mode registry and token model**
   Replace `signalField` as the public default with `tron`, add `severance` and `appleNative`, and introduce `VisualTheme` tokens in `RenderCore`. Keep any legacy `signalField` as private implementation detail only if needed.

3. **Persistence and settings**
   Add `appearance.visualMode` and `appearance.installSeed` handling to `GridOSAppPreferences`, `RootView`, and `SettingsView`. Add a compact picker for the three modes. Decide whether "Reset to Defaults" resets only selected mode/intensity or also install identity; recommendation: do not reset install identity except through an explicit "Regenerate Visual Identity" action.

4. **Native mode command**
   Add `Command-Shift-M` as a menu-visible command. Verify the command cycles the preference and does not touch terminal commands.

5. **App-frame token integration**
   Thread `VisualTheme` through `AppFrameHeader`, `SystemStripView`, `ActivityContextPanel`, `MetricReadout`, `TopProcessRow`, and `TerminalWorkspaceView`. Keep text opacities readable and terminal layout unchanged.

6. **Metal shader mode integration**
   Extend shader uniforms or use the existing `mode` field to produce distinct background behavior per mode. Maintain explicit/burst drawing and static reduced-motion behavior.

7. **Verification and evidence**
   Run full build/test/diff checks, source checks for mode cases/keys/shortcut, launch smoke, persistence smoke, reduced-motion smoke, and capture three mode screenshots.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Xcode / `xcodebuild` | Build/test | yes | Xcode 26.5 build 17F42 | Blocking if missing |
| Swift | Build/test | yes | 6.3.2 local compiler, project `SWIFT_VERSION: 6.0` | Blocking if missing |
| XcodeGen | Project regeneration | yes | 2.45.3 | Install with Homebrew if missing |
| Metal device | Shader compile/runtime visual proof | yes | Apple M2 Ultra | Shader compile test skips if no device; visual proof blocked |
| Git | Version/source audit | yes | 2.50.1 Apple Git-155 | Blocking for commit workflow |
| `screencapture` | Screenshot evidence | yes | macOS built-in | Manual screenshots |
| `sips` | Screenshot metadata | yes | sips-316 | Manual visual review |
| `osascript` | Launch/window smoke scripting | yes | AppleScript 2.8 | Manual app interaction |

**Missing dependencies with no fallback:** None found.

**Missing dependencies with fallback:** None found.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | XCTest via Xcode scheme |
| Config file | `project.yml` and `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` |
| Quick run command | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| Full suite command | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` |

### Phase Deliverables -> Test Map

| Deliverable | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| Mode registry | Three public modes, default `.tron`, stable display names/cycle order | unit | Full XCTest command | yes, extend `Tests/RenderCoreTests/RenderCoreModelTests.swift` |
| Token model | Each mode has unique palette/panel/motion/shader signature | unit | Full XCTest command | no, add in Wave 0 |
| Persistence | Raw selected mode fallback and install seed defaults | unit | Full XCTest command | yes, extend `Tests/GridOSKitTests/GridOSAppPreferencesTests.swift` |
| Reduced motion | Every mode suppresses pulse animation when reduced motion is effective | unit/source | Full XCTest command plus `rg "reducedMotion|VisualEffectConfiguration" Sources/RenderCore Sources/GridOSApp` | yes, extend |
| Shortcut | `Command-Shift-M` exists and is menu-visible | source/smoke | `rg "Cycle Visual Mode|keyboardShortcut\\(\"m\", modifiers: \\[\\.command, \\.shift\\]\\)" Sources/GridOSApp` | no |
| Shader | Metal shader compiles with all mode branches | unit | Full XCTest command | yes, extend existing shader compile test |
| Screenshots | Three modes are visibly different and text remains readable | manual/semi-scripted | `screencapture` plus human review | no script yet |

### Sampling Rate

- **Per task commit:** Run the quick XCTest command.
- **Per wave merge:** Run full suite command and relevant `rg` checks.
- **Phase gate:** Full suite green, launch smoke passes, and three screenshots captured/reviewed.

### Wave 0 Gaps

- [ ] Extend `Tests/RenderCoreTests/RenderCoreModelTests.swift` for `VisualMode` cases, cycling, default, token uniqueness, mode seed derivation, and shader compile.
- [ ] Extend `Tests/GridOSKitTests/GridOSAppPreferencesTests.swift` for selected-mode raw fallback and install-seed default behavior.
- [ ] Decide whether to add a tiny app smoke helper or document `defaults write com.aaldere1.gridos appearance.visualMode <mode>` for screenshot setup.

### Recommended Source Checks

```bash
rg "case tron|case severance|case appleNative|VisualTheme|VisualMotionProfile" Sources/RenderCore Tests/RenderCoreTests
rg "appearance.visualMode|appearance.installSeed|@AppStorage" Sources/GridOSApp Sources/GridOSKit Tests/GridOSKitTests
rg "keyboardShortcut\\(\"m\", modifiers: \\[\\.command, \\.shift\\]\\)|Cycle Visual Mode" Sources/GridOSApp
rg "accessibilityReduceMotion|reducedMotion|VisualEffectConfiguration" Sources/GridOSApp Sources/RenderCore
```

### Screenshot Evidence Path

Recommended local evidence flow:

1. Build Debug app with full suite command.
2. Set mode with `defaults write com.aaldere1.gridos appearance.visualMode tron`, launch app, capture screenshot.
3. Repeat for `severance` and `appleNative`.
4. Confirm terminal and metrics text remain readable in each screenshot.
5. Optionally use `sips -g pixelWidth -g pixelHeight <screenshot>` only to prove artifacts exist; visual distinctness remains human review for Phase 5.

## Risks and Mitigations

| Risk | Level | Mitigation |
|---|---:|---|
| Visual modes are too subtle to pass screenshot acceptance | HIGH | Require mode-unique shader, panel, accent, and motion tokens before app integration is considered done. |
| Shortcut conflicts with shell focus | MEDIUM | Implement as menu command that mutates app preference only; run live terminal smoke after cycling. |
| Reduced motion regression | HIGH | Preserve `VisualEffectConfiguration` as final animation gate and test every mode. |
| Procedural variation breaks readability | MEDIUM | Constrain variation ranges inside mode palettes; test token contrast manually and keep text colors stable. |
| Shader complexity increases idle CPU | MEDIUM | Keep explicit drawing/burst timer; no always-on animation for Severance or reduced motion. |
| Apple-native drifts into light-mode scope | MEDIUM | Keep dark-first in Phase 5; leave adaptive light/dark as deferred. |
| "Tron" becomes too literal | MEDIUM | Use original cyber-grid homage language and avoid copied Disney/eDEX assets, names, or theme files. |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Single `Signal Field` visual mode | Public three-mode registry with shared tokens | Phase 5 | Enables coherent visual systems and screenshot proof. |
| Random/prototype seed | Persisted local install seed with per-mode derivation | Phase 5 | Gives stable personal variation without hardware fingerprinting. |
| Fixed shader palette | Mode token + shader mode parameters | Phase 5 | Makes Metal background part of the design system. |
| Settings-only appearance sliders | Mode picker plus command-menu cycling | Phase 5 | Makes switching fast and discoverable. |

**Deprecated/outdated for Phase 5:**

- `VisualMode.signalField` as the only user-facing mode: replace or hide behind `.tron`.
- Any fake metric styling: Phase 4 made metrics truthful, and Phase 5 must preserve that.
- Hardware-derived raw identifiers: privacy posture prefers local generated seed unless/until Keychain/HMAC hardening lands.

## Open Questions

1. **Should "Reset to Defaults" regenerate install identity?**
   - What we know: roadmap eventually wants a reset/regenerate identity action; context only requires stable per-install variation.
   - What's unclear: whether users expect the existing reset button to change personal visual identity.
   - Recommendation: keep reset-to-defaults scoped to preferences and add a separate small "Regenerate Visual Identity" action only if implementation time permits.

2. **Should mode screenshots be scripted or manual?**
   - What we know: `screencapture`, `sips`, and `osascript` exist locally; no UI test target exists.
   - What's unclear: whether macOS privacy/screen-recording state will allow fully automated capture in every execution environment.
   - Recommendation: plan semi-scripted setup plus manual capture/review, not pixel-diff gating.

3. **Should `Signal Field` remain as an internal mode?**
   - What we know: D-09 allows it to become the internal foundation for Tron or remain implementation detail.
   - What's unclear: whether keeping a non-public enum case complicates `CaseIterable` and settings pickers.
   - Recommendation: migrate public `signalField` to `.tron`; avoid a hidden public enum case unless needed for backwards compatibility. Existing persisted users are not a concern in this private alpha repo.

## Sources

### Primary (HIGH confidence)

- `.planning/phases/05-aesthetic-modes/05-CONTEXT.md` - locked Phase 5 decisions, scope, and verification direction.
- `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` - product promise, active phase, completed prior decisions.
- `docs/production-roadmap.md` - Phase 5 deliverables and acceptance criteria.
- `docs/vision.md` - mode vocabulary, procedural identity intent, and deferred long-term visual ambitions.
- `docs/architecture.md` - module boundaries and Phase 2/3/4 architecture contracts.
- `Sources/RenderCore/VisualIdentity.swift`, `ProceduralSeed.swift`, `VisualEffectConfiguration.swift`, `MetalBackgroundView.swift` - current rendering primitives.
- `Sources/GridOSApp/RootView.swift`, `GridOSApp.swift`, `SettingsView.swift` - app composition, commands, and persistence seams.
- `Sources/GridOSKit/GridOSAppPreferences.swift` - preference defaults/clamping pattern.
- Apple Developer Documentation: `AppStorage` - https://developer.apple.com/documentation/swiftui/appstorage
- Apple Developer Documentation: `CommandMenu` - https://developer.apple.com/documentation/SwiftUI/CommandMenu
- Apple Developer Documentation: `KeyboardShortcut` - https://developer.apple.com/documentation/SwiftUI/KeyboardShortcut
- Apple Developer Documentation: `accessibilityReduceMotion` - https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- Apple Developer Documentation: `MTKView` - https://developer.apple.com/documentation/metalkit/mtkview/

### Secondary (MEDIUM confidence)

- Apple Human Interface Guidelines: Keyboards - https://developer.apple.com/design/human-interface-guidelines/keyboards/
- Apple Human Interface Guidelines: Motion - https://developer.apple.com/design/Human-Interface-Guidelines/motion
- Apple Support: Dark Mode - https://support.apple.com/en-us/HT208976
- SwiftTerm GitHub tag and commit API for `v1.13.0` - https://github.com/migueldeicaza/SwiftTerm/commit/8e7a1e154f470e19c709a00a8768df348ba5fc43

### Tertiary (LOW confidence)

- None used for implementation recommendations.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - existing code and local toolchain verified; no new dependencies recommended.
- Architecture: HIGH - current module boundaries and seams are explicit in code and docs.
- Persistence: HIGH - existing `@AppStorage`/`GridOSAppPreferences` pattern is already validated in Phase 3.
- Metal mode behavior: MEDIUM-HIGH - shader compile path exists, but exact visual values need implementation iteration.
- Screenshot automation: MEDIUM - local tools exist, but macOS capture permissions/window targeting may require manual verification.
- Visual taste: MEDIUM - context strongly defines direction, but final screenshots require human review.

**Research date:** 2026-05-20
**Valid until:** 2026-06-19 for architecture/persistence; re-check Apple API/tool versions before release hardening.

## RESEARCH COMPLETE
