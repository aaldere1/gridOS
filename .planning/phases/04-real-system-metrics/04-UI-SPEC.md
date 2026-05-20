---
phase: 04
slug: real-system-metrics
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-20
---

# Phase 04 - UI Design Contract

> Visual and interaction contract for replacing Phase 3 placeholder panels with truthful metrics.

---

## Product Surface

Phase 4 adds real instrumentation to the existing terminal-first cockpit.

The terminal remains the primary working area. Metrics support terminal work by showing compact host status in the system strip and a readable top-process/unavailable-context panel in the activity area.

---

## Layout Contract

| Region | Contract |
|--------|----------|
| Terminal workspace | Remains dominant and must not be narrowed below the Phase 3 usable width. |
| System strip | Compact horizontal scan line for CPU, memory, network, battery/power, and thermal. |
| Activity panel | Read-only top-process list plus concise unavailable-state explanations. |
| Settings | No new Settings controls in Phase 4 unless needed for reduced sampling during debug builds. |

Responsive behavior:

- At narrow widths, metric labels can abbreviate before terminal space shrinks.
- Top-process rows should truncate process names cleanly and never overlap numeric values.
- Metrics panels must not use nested card-in-card layouts.

---

## Typography

| Role | Size | Weight | Style |
|------|------|--------|-------|
| Metric label | 11-12pt | medium | monospaced preferred |
| Metric value | 12-13pt | semibold | monospaced preferred |
| Top process row | 11-12pt | regular/medium | monospaced values |
| Unavailable explanation | 11-12pt | regular | system |

Rules:

- No viewport-scaled font sizes.
- Letter spacing stays at 0.
- Use compact labels such as `CPU`, `MEM`, `NET`, `BAT`, `THERM`.

---

## Color

| Role | Usage |
|------|-------|
| Near-white text | Primary metric values. |
| White at 56-72% opacity | Labels, timestamps, unavailable explanations. |
| Cyan accent | Active/healthy metric highlights, used sparingly. |
| Amber accent | Warning-ish states such as high thermal pressure, used sparingly. |
| System red | Critical states only. |

Avoid turning metrics into a one-note cyan dashboard. Color should help scanning, not decorate fake urgency.

---

## Interaction Contract

- Metrics are read-only in Phase 4.
- No process action buttons, kill controls, command intelligence affordances, or alert configuration.
- Panels must not steal terminal focus during normal sampling updates.
- Updating metric text must not resize the terminal or jitter panel layout.

---

## Copywriting Contract

Required copy strings:

- `Battery unavailable`
- `Thermal unavailable`
- `Network idle`
- `No process data`
- `Stale`

Copy rules:

- Unavailable states should read as normal platform facts, not errors.
- Avoid tutorial text and explanations of how metrics are sampled inside the app frame.
- Do not expose full process command lines or arguments in this phase.

---

## Accessibility Contract

- System strip has an accessibility label summarizing host metrics.
- Activity panel has an accessibility label for top processes.
- Each metric value has a useful accessibility value, including stale or unavailable state.
- Decorative separators, ticks, and tiny chart shapes are hidden from accessibility.

---

## Checker Sign-Off

- [x] Copywriting: PASS
- [x] Visual hierarchy: PASS
- [x] Color: PASS
- [x] Typography: PASS
- [x] Spacing/layout stability: PASS
- [x] Scope safety: PASS

**Approval:** approved 2026-05-20
