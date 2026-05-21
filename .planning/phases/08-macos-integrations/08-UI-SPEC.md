---
phase: 08
slug: macos-integrations
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-20
---

# Phase 08 — UI Design Contract

> Visual and interaction contract for menu bar, notification, and Settings integration surfaces.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | SwiftUI/AppKit native controls |
| Icon library | SF Symbols |
| Font | System / monospaced system where metric values need scanning |

Phase 8 UI must feel like a Mac-native utility surface orbiting the main terminal workspace. No landing pages, hero sections, oversized cards, or marketing copy. Menu bar and Settings surfaces should be compact, predictable, and work-focused.

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-label gaps, compact metric separators |
| sm | 8px | Menu row spacing, inline status clusters |
| md | 16px | Settings row/group spacing |
| lg | 24px | Settings section padding where native form spacing is not enough |
| xl | 32px | Major Settings group separation |
| 2xl | 48px | Not used in Phase 8 unless a modal needs breathing room |
| 3xl | 64px | Not used |

Exceptions: Native `Form`, `MenuBarExtra`, and macOS menu spacing may use platform defaults where SwiftUI/AppKit owns exact metrics.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | system default | regular | platform default |
| Label | 11-13px | medium | platform default |
| Heading | 13-15px | semibold | platform default |
| Display | not used | not used | not used |

Metric values in the menu bar extra may use monospaced digits or `.monospaced` system styling. Do not use hero-scale typography in menu bar, popover, notification, or Settings surfaces.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Existing `VisualTheme.palette.background` or native menu material | Popover/settings backgrounds |
| Secondary (30%) | Existing panel/background token or native grouped form surface | Settings sections, menu grouping |
| Accent (10%) | Current visual mode primary accent | Active status dot, selected/on states, small emphasis only |
| Destructive | System red | Reset/revoke/delete actions only |

Accent reserved for: menu bar status indicator, active/on toggles, notification permission status, current workspace marker, small metric emphasis. Never tint every interactive element or make menu bar UI read as a custom neon panel.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Menu bar open action | `Open gridOS` |
| Menu bar status | `Active workspace` |
| Menu bar recent directories heading | `Recent Directories` |
| Menu bar metrics heading | `Host Status` |
| Notification setting | `Notify when long-running work finishes` |
| Notification permission CTA | `Enable Notifications` |
| Notification unavailable copy | `Notifications are off. Terminal work continues normally.` |
| Secret storage setting | `Manage Stored Secrets` |
| Secret delete confirmation | `Remove Secret: This removes the stored credential from Keychain.` |
| Indexing setting | `Index saved workspace metadata` |
| Indexing privacy copy | `Only saved workspace labels and directory names are indexed. Terminal output and command history are never indexed.` |
| Empty recent directories | `No recent directories yet.` |
| Error state | `Integration unavailable. Check macOS permissions and try again.` |

Notification content defaults:

| Notification Field | Copy |
|--------------------|------|
| Title | `gridOS work finished` |
| Body | `A long-running task completed in your workspace.` |
| Action | `Open gridOS` |

Do not include full commands, output, secrets, environment values, process arguments, or full paths in default notification copy.

---

## Interaction Contract

### Menu Bar Extra

- Shows a compact gridOS status item using native `MenuBarExtra` or AppKit equivalent.
- Required actions: `Open gridOS`, current workspace/status, compact host metrics, recent directories when available, Settings, Quit.
- Opening gridOS must activate the app and return focus to the active pane.
- Recent-directory actions may create/focus a pane only after explicit user choice; no automatic shell command execution.
- Menu bar extra visibility must be user-controllable from Settings.

### Notifications

- Notification permission is requested only after explicit user action.
- Notification failures surface as status copy, not terminal errors.
- Notification settings must be available in Settings and testable without requiring live Notification Center prompts.

### Settings

- Add a compact `macOS Integrations` section to the existing Settings form.
- Use toggles for binary settings, buttons for permission/management actions, and small secondary copy for privacy boundaries.
- Do not add a new onboarding screen.

### Spotlight And Preview

- If implemented, use explicit opt-in Settings controls.
- Show clear privacy copy before enabling.
- Do not render terminal transcript previews.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| third-party | none | not allowed without explicit plan update |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-20
