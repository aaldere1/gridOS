---
phase: 03
slug: production-app-frame
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-20
---

# Phase 03 - UI Design Contract

> Visual and interaction contract for Phase 3. The app frame must serve terminal work first.

---

## Product Surface

Phase 3 builds a production app frame for a native macOS terminal cockpit.

The first screen is the app itself, not a landing page. The terminal remains the primary working area. The frame supports the terminal with a restrained header, system strip placeholder, activity/context placeholder, persisted settings, and recovery/accessibility behavior.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI/AppKit |
| Preset | Not applicable |
| Component library | None |
| Icon library | SF Symbols if icons are needed |
| Font | System rounded for product chrome; system monospaced for shell/status values |

---

## Layout Contract

| Region | Contract |
|--------|----------|
| Main terminal | Dominant region. Minimum 70% of usable content area on desktop widths. Never visually subordinate to panels. |
| Header | Compact app-owned chrome inside hidden titlebar window. Must leave native traffic lights usable. |
| System strip | Lightweight placeholder for Phase 4 metrics. Keep compact and truthful; no fake metric values. |
| Activity/context panel | Secondary placeholder for future activity/command context. Keep narrow and quiet; no LLM affordances yet. |
| Settings | Native macOS Settings scene with grouped sections for Terminal, Appearance, and Recovery. |

Responsive behavior:

- At narrow widths, secondary panels collapse or reduce before terminal width drops below a usable threshold.
- Text must not overlap or truncate incoherently in header, settings, or panel labels.
- Do not nest visual cards inside other cards. Use full-height panels or unframed layout regions.

---

## Spacing Scale

Declared values must be multiples of 4:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, tiny status separators |
| sm | 8px | Compact control gaps |
| md | 16px | Default panel/header spacing |
| lg | 24px | Outer frame padding on roomy windows |
| xl | 32px | Large layout gap only if terminal remains dominant |

Exceptions: use AppKit/SwiftUI native traffic-light spacing and Settings form defaults where system controls dictate spacing.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Terminal | User preference, default 13pt | regular | SwiftTerm-managed |
| Body | 13pt | regular | native/default |
| Label | 11-12pt | medium | native/default |
| Header title | 17-18pt | semibold | native/default |
| Status value | 11-13pt | medium | monospaced/default |

Rules:

- No viewport-scaled font sizes.
- Letter spacing stays at 0.
- Header/status copy must stay compact; no hero-scale text inside app chrome.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant | `#010307` to `#060A0E` range | App background and Metal quiet base |
| Secondary | `#0A1118` to `#111923` range | Panels and header separation |
| Accent | Cyan `#19B8C7`, restrained amber `#F28533` | Terminal focus, active visual mode, rare status accents |
| Text primary | near-white `#E8F3F5` | Main labels |
| Text secondary | white at 56-72% opacity | Metadata/status |
| Destructive | system red | Destructive/reset confirmation only |

Accent reserved for:

- terminal focus ring/stroke
- active visual mode indicator
- command status highlights
- reduced, isolated setting affordances

Do not turn the app into a one-note cyan dashboard. The palette should read dark, technical, and premium, with cyan/amber as sparse signal colors.

---

## Interaction Contract

### Keyboard

- Terminal owns shell-like shortcuts by default.
- App shortcuts must be menu-visible and command-modifier based.
- Preserve Copy `Command-C`, Paste `Command-V`, Clear `Command-K`, Reset `Option-Command-R`.
- Add no single-key global shortcuts in this phase.

### Focus

- On launch, terminal receives first responder focus.
- Clicking header/panels/settings can focus those controls, but returning to the main app should restore terminal focus when appropriate.
- Visual effects and placeholder panels must never consume key input intended for the terminal.

### Reduced Motion

- Effective reduced motion is true when either the system environment setting or app preference is true.
- Reduced motion disables or sharply reduces Metal pulse animation after terminal activity.
- Reduced motion still permits a calm static background frame.

### State Restoration

- Restore window size/position and persisted settings.
- Do not restore killed shell processes.
- Relaunch starts a fresh shell using the persisted profile.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Settings terminal section | Terminal |
| Settings shell field | Shell |
| Settings font control | Font size |
| Settings appearance section | Appearance |
| Reduced motion toggle | Reduce motion |
| Visual intensity control | Visual intensity |
| Recovery section | Recovery |
| Reset action | Reset to Defaults |
| System strip placeholder | Systems ready |
| Activity panel placeholder | Activity |

Copy rules:

- Do not explain keyboard shortcuts or product features inside the app frame.
- Use short nouns/verbs in chrome and settings.
- Avoid visible "AI" or command intelligence language in Phase 3.

---

## Accessibility Contract

- Custom controls, indicators, and placeholders need explicit accessibility labels.
- Sliders/steppers need useful accessibility values.
- Header and panel decorative elements should be hidden from accessibility if they add noise.
- Settings fields must expose stable labels matching visible text.
- Contrast for text and strokes must remain readable over the Metal background.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable |
| third-party UI blocks | none | not permitted in Phase 3 |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-20
