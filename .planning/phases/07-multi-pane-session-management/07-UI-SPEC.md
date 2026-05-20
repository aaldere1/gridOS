---
phase: 07
slug: multi-pane-session-management
status: ready
shadcn_initialized: false
preset: none
created: 2026-05-20
---

# Phase 07 - UI Design Contract

> Visual and interaction contract for multi-pane terminal workflows. The terminal remains the dominant product surface.

## Product Surface

Phase 7 replaces the single terminal workspace with a multi-pane terminal workspace inside the existing gridOS app frame.

The user should be able to split the current shell, focus another pane, duplicate a pane, close a pane, resize splits, and relaunch into the same useful layout with fresh shells in the last known directories. This is an operational terminal workspace, not a dashboard, project launcher, or session marketing surface.

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI/AppKit |
| Preset | Not applicable |
| Component library | None |
| Icon library | SF Symbols if icons are needed |
| Font | Existing system rounded chrome and system monospaced terminal/status text |
| Visual modes | Inherit current `VisualTheme` tokens for Tron, Severance, and Apple-native |

Registry safety:

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable |
| third-party UI blocks | none | not permitted in Phase 7 |

## Layout Contract

| Region | Contract |
|--------|----------|
| App header | Remains stable. May include compact active pane count or active directory only if it fits without crowding existing product/version/mode signals. |
| System strip | Remains host-level metrics. Do not turn it into pane controls. |
| Terminal workspace | Replaces single terminal with split panes. It remains the largest region and consumes all available center space. |
| Pane surface | Each pane contains one SwiftTerm-backed terminal. No nested card inside pane. Pane border/active indicator is chrome around the terminal, not a content overlay. |
| Active pane indicator | Subtle mode-aware 1-2px border or leading edge using `theme.palette.primaryAccent`; must not obscure text. |
| Split handles | Thin draggable separators with at least 6px practical hit area. Default visual line should be 1px using existing separator opacity. |
| Pane labels | Optional compact metadata row only if necessary. Prefer no always-visible title bar unless focus/drag needs it. |
| Close confirmation | Native alert or compact in-app confirmation for terminating a live pane; copy must name that the shell process will terminate. |
| Settings/Recovery | Update copy to explain pane layout/directories restore and running processes do not restore. Avoid a large setup surface. |

Responsive behavior:

- Minimum app size must keep at least one pane readable.
- Two panes should be usable on laptop width without the activity panel crushing terminal text.
- For three or more panes, allow user-driven proportions rather than automatic tiny equal columns only.
- If a pane would shrink below readable minimums, disable further split or clamp proportions.
- Do not add decorative nested cards, oversized empty states, or landing-page content.

## Spacing Scale

Declared values must be multiples of 4:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Pane metadata gaps, compact icons |
| sm | 8px | Pane border/handle spacing, active indicator offset |
| md | 16px | Existing app-frame spacing between metrics/workspace/panel |
| lg | 24px | Confirmation and Settings section spacing |
| xl | 32px | Reserved only for modal padding |

Exceptions: SwiftTerm internal text layout, native split view handle behavior, native alert spacing, and existing app-frame geometry remain system-controlled.

## Typography

Use existing app typography. New pane chrome must stay compact:

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Pane metadata | 11pt | regular | 1.20 | Optional cwd/title/pane count labels |
| Pane command labels | 12pt | medium | 1.25 | Menus and confirmation labels |
| Recovery copy | 13pt | regular | 1.40 | Settings explanatory text |

Rules:

- Terminal content remains SwiftTerm-owned.
- Use monospaced text for directories and pane IDs when visible.
- Letter spacing stays at 0.
- No viewport-scaled font sizes.
- No hero-scale or marketing headings.

## Color

Multi-pane chrome inherits active `VisualTheme`.

| Role | Value | Usage |
|------|-------|-------|
| Dominant | existing terminal background and app background | Terminal surfaces and workspace continuity |
| Secondary | `theme.palette.background` at `theme.panel.backgroundOpacity` | Pane separators and optional metadata areas |
| Accent | `theme.palette.primaryAccent` | Active pane indicator and focused split handle |
| Status | `theme.palette.statusAccent` | Close/process warnings and restore fallback notes |
| Destructive | system red | Confirmed process termination warning only |

Rules:

- Active pane accent must be visible in all three visual modes.
- Inactive pane borders use existing separator opacity, not a new color family.
- Do not introduce a new multi-pane theme or one-off gradient treatment.

## Interaction Contract

### Pane Creation and Layout

- `Split Right` creates a new pane to the right of the active pane.
- `Split Down` creates a new pane below the active pane.
- New panes start in the active pane's last known working directory when available and valid; otherwise use the default working directory.
- `Duplicate Pane` creates a fresh shell using the active pane's configuration and last known working directory. It does not clone process state.
- Split proportions are user-resizable and clamped to preserve readability.

### Pane Focus

- Clicking inside a pane activates it and gives terminal focus.
- Keyboard focus next/previous cycles through panes in visual order.
- The active indicator updates immediately on focus change.
- Closing Command Intelligence, Settings routing, or pane commands returns focus to the active pane.

### Menu and Keyboard Commands

Recommended visible menu copy and shortcuts:

| Menu Item | Shortcut |
|-----------|----------|
| Split Right | `Command-D` |
| Split Down | `Command-Shift-D` |
| Duplicate Pane | `Command-Option-D` |
| Close Pane | `Command-W` when more than one pane exists |
| Focus Next Pane | `Command-]` |
| Focus Previous Pane | `Command-[` |
| Resize Pane Left/Right/Up/Down | `Command-Control-Arrow` |

Existing Terminal actions remain:

- `Copy`
- `Paste`
- `Clear`
- `Reset`

All of these must target only the active pane.

### Close and Cleanup

- Closing a pane terminates that pane's shell.
- If the app cannot reliably detect foreground work, use conservative copy: `Close this pane and terminate its shell?`
- Closing the last pane should either be disabled or create a fresh default pane; it must not leave an empty broken workspace.
- App quit/window close must clean up every live pane process.

### Session Restore

- Relaunch restores layout, active pane identity, shell/profile settings, and last known directories.
- Relaunch starts fresh shell processes.
- Missing directories fall back to default/home with calm copy if surfaced.
- Settings/Recovery copy must say: `Running shell processes are not restored after relaunch.`

### Recent Directories

- Recent directories should be available for new-pane choices if implemented visibly.
- Do not expose recent commands in the UI unless implementation is opt-in and local. Recent command capture can be deferred.
- No shell history or environment capture.

### Command Intelligence

- Command Intelligence selected text, working directory, insert, run, and focus restoration target the active pane only.
- If the active pane changes while the palette is open, the palette should either keep the pane it opened from or clearly use the new active pane. Prefer keeping the pane it opened from for one request, then return focus to that pane on close.
- Generated commands must still follow Phase 6 insert/run policy.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Menu | Split Right |
| Menu | Split Down |
| Menu | Duplicate Pane |
| Menu | Close Pane |
| Menu | Focus Next Pane |
| Menu | Focus Previous Pane |
| Close confirm title | Close pane? |
| Close confirm body | This will terminate the shell running in this pane. |
| Close confirm action | Close Pane |
| Restore copy | Pane layout and directories are restored on relaunch. |
| Recovery copy | Running shell processes are not restored after relaunch. |
| Missing directory copy | Directory unavailable. Starting in your default directory. |

## Accessibility Contract

- Every pane must have an accessibility label that includes pane position or index and active state.
- Split handles must be keyboard-accessible through menu commands even if direct handle accessibility is limited.
- Focus order follows visual pane order.
- Active pane indicator is not color-only; include accessibility value `Active pane`.
- Close confirmations must be reachable without a mouse.
- Reduced motion should avoid animated pane rearrangement; use immediate layout updates or opacity only.

## Motion Contract

- Pane split/close transitions should be short and functional.
- Respect app and system reduced motion by disabling layout animation.
- Do not add pane-specific pulse effects, particle bursts, or decorative background motion.

## Verification Contract

UI verification must include:

- source check for menu labels and shortcuts
- source check that `GridOSApp` still does not import SwiftTerm
- app smoke with at least two panes visible and active indicator changing
- focus smoke proving typing after pane focus/Command Intelligence close goes to the intended pane
- screenshot/evidence may be captured, but private terminal content should not be committed

