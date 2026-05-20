# Phase 05: Aesthetic modes - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 5 proves gridOS is a visual system, not a single theme. The phase delivers a mode registry and shared visual token model, three coherent user-facing modes (`Tron`, `Severance`, and `Apple-native`), fast and stable mode switching via `Command-Shift-M`, per-mode motion/effect profiles, and per-install procedural variation.

This phase does not add Cyberpunk, Matrix, sound themes, plugin theming APIs, a custom GPU terminal text renderer, full light-mode support, a theme marketplace, user-authored themes, or production performance hardening. Those remain later roadmap work unless explicitly added.

</domain>

<decisions>
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

### the agent's Discretion
- Exact shader math, token names, palette values, and mode registry shape are left to the implementation agent, constrained by the decisions above.
- Exact Apple-native visual treatment is left to implementation taste as long as it is calm, dark-first for Phase 5, and recognizably macOS-native.
- Whether the existing `Signal Field` mode is renamed, migrated, or kept as an internal fallback is left to planning/implementation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Product Vision
- `.planning/ROADMAP.md` — Current Phase 5 status, goal, and exit criteria.
- `docs/production-roadmap.md` — Phase 5 deliverables and acceptance criteria, including `Command-Shift-M` and three screenshot requirements.
- `docs/vision.md` — Product-level aesthetic intent, non-goals, procedural signature, and long-term mode vocabulary.
- `.planning/PROJECT.md` — Product promise, module boundaries, and non-negotiables.
- `.planning/STATE.md` — Current validated implementation state and decisions carried forward.

### Prior Phase Contracts
- `.planning/phases/02-metal-identity-mvp/02-01-SUMMARY.md` — Existing visual identity model, procedural seed, Metal background, event pulses, and idle behavior.
- `.planning/phases/02-metal-identity-mvp/02-VERIFICATION.md` — Evidence for Metal rendering, terminal activity pulses, and idle CPU behavior.
- `.planning/phases/03-production-app-frame/03-CONTEXT.md` — Terminal-first cockpit, focus policy, keyboard policy, settings, reduced motion, and accessibility decisions.
- `.planning/phases/03-production-app-frame/03-VERIFICATION.md` — Evidence for app frame, settings, reduced motion, and window behavior.
- `.planning/phases/04-real-system-metrics/04-CONTEXT.md` — Metrics panel truthfulness, text-forward display, and local-only behavior.
- `.planning/phases/04-real-system-metrics/04-VERIFICATION.md` — Evidence for real metrics strip and top-process panel integration.

### Architecture and Code
- `docs/architecture.md` — Current module boundaries and Phase 2/3/4 architecture contracts.
- `docs/release.md` — Existing smoke patterns and launch-command verification.
- `Sources/RenderCore/VisualIdentity.swift` — Current `VisualMode`, `VisualIdentity`, and default mode model.
- `Sources/RenderCore/ProceduralSeed.swift` — Deterministic seed model for procedural variation.
- `Sources/RenderCore/VisualEffectConfiguration.swift` — Global visual intensity and reduced-motion pulse contract.
- `Sources/RenderCore/MetalBackgroundView.swift` — Current shader host, mode uniform, burst animation, and fallback rendering path.
- `Sources/GridOSApp/RootView.swift` — App composition, visual identity consumption, header indicator, terminal-first layout, and metrics surfaces.
- `Sources/GridOSApp/SettingsView.swift` — Existing settings persistence pattern and Appearance section.
- `Sources/GridOSKit/GridOSAppPreferences.swift` — Shared app preference model and clamping patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `VisualMode` and `VisualIdentity`: current single-mode foundation that can become a mode registry.
- `ProceduralSeed`: deterministic seed vector already available for mode variation.
- `VisualEffectConfiguration`: existing global intensity/reduced-motion scalar to preserve across modes.
- `MetalBackgroundView`: already accepts `VisualIdentity`, sends mode into shader uniforms, idles after event bursts, and falls back when Metal is unavailable.
- `RootView`: already displays `visualIdentity.mode.displayName` in the header and maps terminal activity into `RenderEvent`.
- `GridOSAppPreferences` / `SettingsView`: existing local persistence pattern for appearance values.

### Established Patterns
- `project.yml` is authoritative; regenerate `gridOS.xcodeproj` after adding sources/tests.
- Feature modules own models and behavior; `GridOSApp` composes them.
- `RenderCore` owns shader/mode logic. `TerminalCore` must not depend on `RenderCore`.
- The app is terminal-first: visual identity supports shell work and must not compete with focus or readability.
- Reduced motion and visual intensity are already tested model behavior and should stay testable.
- Phase 4 metrics are truthful text surfaces; aesthetic modes must decorate around them without changing their meaning.

### Integration Points
- Add mode/token primitives in `RenderCore`, then consume them from `RootView`.
- Add local mode persistence in `GridOSKit.GridOSAppPreferences` and shared `@AppStorage` keys in `RootView` and possibly `SettingsView`.
- Extend app commands in `GridOSApp.swift` for `Command-Shift-M`.
- Extend `MetalBackgroundRenderer` shader branching or shader inputs to make mode differences visible.
- Update `RenderCoreTests` and app preference tests for mode defaults, persistence values, reduced-motion behavior, and mode uniqueness.

</code_context>

<specifics>
## Specific Ideas

- The product should avoid being merely a "Tron-themed iTerm"; Phase 5 should make screenshots feel like different coherent worlds.
- `Tron` should satisfy the original eDEX-inspired promise while staying from-scratch and legally/creatively distinct.
- `Severance` should be quiet, severe, and useful, almost anti-sci-fi compared to Tron.
- `Apple-native` is the mode a person can leave on during real work without feeling like they are performing for a demo.
- The existing `Command-Shift-M` promise from the vision/roadmap should become a real native command in this phase.

</specifics>

<deferred>
## Deferred Ideas

- Cyberpunk and Matrix modes — present in the long-term vision but outside the Phase 5 production roadmap scope.
- Sound themes and UI audio — separate future work.
- User-authored themes or plugin theme APIs — later plugin/theme infrastructure.
- Full light-mode support for Apple-native — future adaptive appearance work unless planning finds a tiny safe path.
- GPU-accelerated custom terminal text rendering — long-term rendering work, not Phase 5.
- Theme marketplace, imported theme files, or eDEX theme compatibility — out of scope.

</deferred>

---

*Phase: 05-aesthetic-modes*
*Context gathered: 2026-05-20*
