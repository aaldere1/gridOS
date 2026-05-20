# Phase 05: Aesthetic modes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 05-aesthetic-modes
**Areas discussed:** Mode taste and references, Mode switching and persistence, Theming scope and terminal protection, Motion and procedural variation

---

## Mode Taste and References

The interactive choice tool was unavailable in Default mode. Following the GSD fallback, Codex selected the recommended default and recorded it for review.

| Option | Description | Selected |
|--------|-------------|----------|
| Three roadmap modes | Ship Tron, Severance, and Apple-native as coherent systems; defer Cyberpunk/Matrix. | ✓ |
| Expand to all vision modes | Include Cyberpunk and Matrix now; higher scope and verification burden. | |
| Color-only theme pass | Change palettes without deeper mode behavior; faster but fails the "visual system" goal. | |

**User's choice:** Recommended default selected by Codex fallback.
**Notes:** The roadmap explicitly scopes Phase 5 to Tron, Severance, and Apple-native. `docs/vision.md` lists more long-term modes, so those are deferred rather than folded in.

---

## Mode Switching and Persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Native cycle + persistence | `Command-Shift-M` cycles modes, menu command exposes it, selected mode persists locally. | ✓ |
| Settings-only picker | Simpler but fails the hotkey promise and makes switching feel heavy. | |
| Command palette style UI | More discoverable but belongs closer to Phase 6 command palette work. | |

**User's choice:** Recommended default selected by Codex fallback.
**Notes:** The existing app already has native command menus and `@AppStorage` preferences, so this is consistent with Phase 3.

---

## Theming Scope and Terminal Protection

| Option | Description | Selected |
|--------|-------------|----------|
| Full app-frame tokens | Mode affects background, header, accents, panels, metrics strip, and motion while preserving terminal readability. | ✓ |
| Shader-only modes | Lower risk but screenshots may not be distinct enough. | |
| Terminal-renderer modes | More ambitious, but custom GPU text rendering is later roadmap work. | |

**User's choice:** Recommended default selected by Codex fallback.
**Notes:** Prior phases lock terminal dominance, focus safety, and truthful metrics. Modes must decorate the cockpit, not take it over.

---

## Motion and Procedural Variation

| Option | Description | Selected |
|--------|-------------|----------|
| Per-mode motion profiles + stable install seed | Distinct mode behavior with reduced-motion support and stable per-install variation. | ✓ |
| Shared motion across modes | Simpler but weakens the "modes are systems" requirement. | |
| Randomized every launch | Visually exciting but undermines identity and screenshot consistency. | |

**User's choice:** Recommended default selected by Codex fallback.
**Notes:** Existing `ProceduralSeed` gives the foundation; Phase 5 should make the seed stable per install and visibly, subtly different.

---

## the agent's Discretion

- Exact shader implementation and token naming.
- Exact palette values and per-mode micro-variation mapping.
- Whether current `Signal Field` is renamed, migrated into `Tron`, or kept as an internal fallback.
- Exact Settings UI shape if a simple picker is added.

## Deferred Ideas

- Cyberpunk mode.
- Matrix mode.
- Theme sounds.
- User-authored theme/plugin API.
- Full Apple-native light-mode support.
- Custom GPU terminal text rendering.
