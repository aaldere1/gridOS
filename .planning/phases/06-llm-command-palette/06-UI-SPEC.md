---
phase: 06
slug: llm-command-palette
status: draft
shadcn_initialized: false
preset: none
created: 2026-05-20
---

# Phase 06 - UI Design Contract

> Visual and interaction contract for adding opt-in command intelligence. The terminal remains the dominant product surface.

---

## Product Surface

Phase 6 adds a compact `Command-K` command-intelligence palette over the existing terminal-first cockpit.

The palette is a one-shot operational tool, not a chat surface. It supports exactly three flows: `Suggest Command`, `Explain Output`, and `Fix Failed Command`. Every flow must show a context preview before any provider request, and every generated command must be inspectable before insertion or execution.

The terminal stays visible behind or around the palette. Closing, cancelling, or finishing a palette flow must restore focus to the active terminal.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI/AppKit |
| Preset | Not applicable |
| Component library | None |
| Icon library | SF Symbols if icons are needed |
| Font | System rounded for compact chrome; system monospaced for commands, paths, status, and context labels |
| Visual modes | Inherit current `VisualTheme` tokens for Tron, Severance, and Apple-native |

Registry safety:

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable |
| third-party UI blocks | none | not permitted in Phase 6 |

---

## Layout Contract

| Region | Contract |
|--------|----------|
| Palette shell | Single compact overlay/sheet centered over the app frame. Width `min(720px, windowWidth - 96px)`. Height `min(620px, windowHeight - 96px)`. At minimum app size, terminal chrome remains visible on all sides. |
| Terminal workspace | Remains visually dominant behind the palette. Do not convert the right activity panel into a persistent assistant or chat rail. |
| Flow selector | Top segmented control with exactly `Suggest Command`, `Explain Output`, and `Fix Failed Command`. Keep height stable when switching flows. |
| Compose area | One prompt/input area plus optional paste field for selected output or failed-command text. No conversation transcript. |
| Context preview | Required intermediate state before send. Shows prompt, working directory, selected/pasted output or failed-command context, context character counts, redaction labels, redaction counts, and blocked reasons. |
| Result area | Shows response summary and, when a command is generated, command text, explanation, working-directory assumption, context used, local risk label, and Insert/Run affordances. |
| Confirmation | For risky run paths, use a visually distinct confirmation surface inside the same palette or a native alert. It must show the exact command that would run. |
| Settings | Add a compact `Command Intelligence` Settings section for provider selection and Keychain-backed key setup. Do not expose or echo the saved key after save. |

Responsive behavior:

- Keep palette dimensions stable between loading, preview, result, and failure states; content scrolls inside the palette if needed.
- At narrow widths, reduce side padding before reducing terminal visibility below a usable frame.
- Do not use nested cards. Use one palette panel with separators, sections, and monospaced blocks.
- No landing-page, marketing, or hero layout. This is an operational terminal tool.

---

## Spacing Scale

Declared values must be multiples of 4:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline icon/text gaps, redaction count gaps |
| sm | 8px | Compact row gaps, segmented control spacing |
| md | 16px | Palette internal padding, section spacing |
| lg | 24px | Palette outer padding and result-section gaps |
| xl | 32px | Space between palette and visible terminal edge where possible |
| 2xl | 48px | Minimum large-window breathing room around the overlay |
| 3xl | 64px | Maximum top/bottom breathing room on tall displays |

Exceptions: native Settings form spacing, AppKit alert spacing, and existing app-frame geometry remain system-controlled. Icon-only buttons and compact run/insert affordances must keep at least a 44px hit target.

---

## Typography

Use exactly these Phase 6 sizes in new palette UI:

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Metadata | 11pt | regular | 1.30 | Redaction labels, counts, risk reasons, provider state |
| Label | 12pt | semibold | 1.25 | Flow labels, section titles, button labels |
| Body | 13pt | regular | 1.45 | Explanations, failure body copy, preview prose |
| Palette title | 16pt | semibold | 1.20 | `Command Intelligence` header only |

Rules:

- Use system monospaced at 12-13pt for commands, paths, context snippets, request IDs, and risk classifier details.
- Letter spacing stays at 0.
- No viewport-scaled font sizes.
- No hero-scale text, large marketing headings, or oversized empty states inside the palette.

---

## Color

The palette inherits the active `VisualTheme`; do not create a one-off LLM palette theme.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `theme.palette.background` with existing Metal background visible behind | App background, overlay surroundings, terminal continuity |
| Secondary (30%) | `theme.palette.background` at `theme.panel.backgroundOpacity` plus theme border/separator opacity | Palette panel, preview sections, result separators |
| Accent (10%) | `theme.palette.primaryAccent` | Active flow indicator, focused input ring, `Insert Command`, low-risk label, selected primary action |
| Status accent | `theme.palette.statusAccent` | Redaction summary, medium-risk warning, provider setup status |
| Destructive | system red | High-risk/destructive command warning and destructive confirmation only |

Accent reserved for:

- active flow selector state
- focused prompt/context fields
- `Insert Command` primary affordance
- low-risk `Ready to insert` signal
- context preview approval state

Risk color rules:

- `Low`: primary accent, subdued opacity, no alarm styling.
- `Medium`: status accent with clear reason text.
- `High`: system red label and border; default handling is insert-only.
- `Unknown`: status accent plus high-contrast outline; default handling is insert-only unless exact-command confirmation is implemented.

---

## Interaction Contract

### Command Entry

- `Command-K` opens the command-intelligence palette.
- Existing Terminal `Clear` must move to a visible non-conflicting shortcut, recommended `Command-Option-K`.
- `Escape` closes the palette from every state and restores terminal focus.
- `Command-Return` may trigger `Preview Context` or `Send Request`; it must never run a generated command.
- No palette interaction may execute shell text as a side effect of provider response receipt.

### Flow 1: Suggest Command

1. User opens `Command-K` and selects `Suggest Command`.
2. User enters a natural-language request.
3. Primary action is `Preview Context`.
4. Preview shows prompt, working directory assumption, redactions, and the exact payload summary.
5. User chooses `Send Request` or `Close Preview`.
6. Result shows command, explanation, working-directory assumption, context used, local risk label, `Insert Command`, and eligible `Run Command` affordance.
7. `Insert Command` inserts text into the active terminal without a trailing newline.
8. `Run Command` appends a newline only after the user explicitly chooses it and the local risk policy allows it.

### Flow 2: Explain Output

1. User selects terminal output or pastes output into the palette.
2. If terminal selection is unavailable, show the paste fallback instead of scraping scrollback.
3. Primary action is `Preview Context`.
4. Preview shows selected/pasted output character count, redaction labels/counts, and working directory if available.
5. Result is read-only: meaning, likely cause, and next checks.
6. Do not show Run controls in explain-only results unless the provider returns a separate fix command, and then route it through the same generated-command result and risk policy.

### Flow 3: Fix Failed Command

1. User pastes or supplies the failed command and output, or uses selected output if available.
2. Primary action is `Preview Context`.
3. Preview shows failed command, output character count, working directory if available, and redactions.
4. Result shows diagnosis first.
5. Any suggested fix command must show command, explanation, working-directory assumption, context used, local risk label, and Insert/Run affordances.
6. Fix commands follow the same insert-first and risk-confirmation policy as suggested commands.

### Provider Setup

- No-key state is normal. The palette remains calm and dismissible, and the terminal remains usable.
- Provider key setup belongs in Settings under `Command Intelligence`.
- Store API keys in Keychain only. Non-secret provider/model preferences may use existing app preference patterns.
- Do not show a saved key value. Use status copy such as `Provider configured`.

### Motion

- Palette presentation uses a short native opacity/scale transition only.
- Respect app and system reduced-motion settings by removing scale movement and using opacity only.
- No animated typing, assistant avatar, particle burst, gradient orb, or background effect specific to the palette.

---

## Command Result Contract

Every generated-command result must render these fields in this order:

| Field | Contract |
|-------|----------|
| Command | Monospaced block, selectable/copyable if feasible, no wrapping that hides the command ending. |
| Explanation | Plain-language reason for the command and what it will change or inspect. |
| Working directory assumption | Display exact path or `Current terminal directory` when unavailable. |
| Context used | Compact list of prompt, working directory, selected output, pasted output, failed command, and redaction counts. |
| Local risk label | Deterministic local classifier result, not provider-only risk. |
| Actions | `Insert Command` primary. `Run Command` only when allowed by policy. |

Execution policy:

| Risk | Visual Treatment | Run Policy |
|------|------------------|------------|
| Low | Subdued primary-accent label: `Low risk` | `Run Command` may be shown as secondary after result is visible. |
| Medium | Status-accent label with reason | Prefer `Insert Command`; if Run is offered, require confirmation showing the exact command. |
| High | System-red label and border with reason | Default to insert-only. If implementation adds Run, require exact-command confirmation and destructive copy. |
| Unknown | Status-accent outline with reason | Default to insert-only. Unknown never silently downgrades to low. |

---

## Context Preview Contract

The preview is the approval artifact. The provider receives only the approved redacted payload.

Required preview fields:

- Flow name.
- User prompt or supplied failed-command request.
- Working directory if available.
- Selected terminal output count and preview, if included.
- Pasted output count and preview, if included.
- Failed command and failed output count, if included.
- Redaction labels and counts, including API key, bearer/basic token, private key, password assignment, `.env` value, and credential URL when detected.
- Blocked reasons when redaction cannot produce a safe payload.

Preview actions:

- `Send Request` submits the approved redacted payload.
- `Close Preview` closes the preview and returns to compose without sending.
- `Edit Context` returns to compose.

Do not include full shell history, environment variables, process lists, hidden files, SSH config, Keychain data, metrics snapshots, raw API keys, or unrequested scrollback by default.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Palette title | Command Intelligence |
| Flow tab 1 | Suggest Command |
| Flow tab 2 | Explain Output |
| Flow tab 3 | Fix Failed Command |
| Suggest placeholder | Describe the command you want. |
| Explain placeholder | Select terminal output or paste it here. |
| Fix placeholder | Paste the failed command and output. |
| Primary compose CTA | Preview Context |
| Preview send CTA | Send Request |
| Preview close CTA | Close Preview |
| Preview edit CTA | Edit Context |
| Generated insert CTA | Insert Command |
| Generated run CTA | Run Command |
| High-risk insert CTA | Insert for Review |
| No-key heading | Provider not configured |
| No-key body | Add a provider key in Settings to use command intelligence. The terminal still works normally. |
| No-key action | Open Command Intelligence Settings |
| Offline heading | Provider unreachable |
| Offline body | Check your connection or try again later. Nothing was sent after the failure. |
| Offline action | Retry Request |
| Rate-limit heading | Provider is busy |
| Rate-limit body | Wait a moment and try again. The terminal is still available. |
| Rate-limit action | Retry Request |
| Provider error heading | Command intelligence is unavailable |
| Provider error body | Try again or continue in the terminal without assistance. |
| Redaction blocked heading | Context needs review |
| Redaction blocked body | Sensitive content was detected that cannot be safely sent. Remove it or continue manually. |
| Unsupported selection heading | Selection unavailable |
| Unsupported selection body | Paste the output into the field to continue. |
| Destructive confirmation | Run exactly this command? |

Copy rules:

- Use calm product-level language. Do not surface raw `URLError`, HTTP, JSON decoding, or provider enum strings.
- Avoid `AI`, `agent`, `autonomous`, and `magic` framing in primary chrome. `Command Intelligence` is the feature label.
- Keep failure copy short and actionable; the terminal is never described as broken because of provider failure.

---

## Failure and Risk States

| State | UI Contract | Terminal Contract |
|-------|-------------|-------------------|
| No provider key | Calm setup state with `Provider not configured`, `Open Command Intelligence Settings`, and disabled send. | Terminal remains focused after dismissal and fully usable. |
| Cancelled before send | Return to compose or close palette with no error styling. | No context sent. Focus returns to terminal on close. |
| Offline/network failure | Show `Provider unreachable` with retry and cancel. | No shell interruption; no command inserted or run. |
| Rate limit | Show `Provider is busy` with retry after user action only. | Terminal remains usable. |
| Provider error/refusal | Show product-level unavailable/refusal message and preserve editable prompt/context. | No command execution path. |
| Invalid/truncated response | Show `Command intelligence is unavailable`; do not render partial commands as runnable. | Terminal remains usable. |
| Redaction blocked | Show blocked reasons and `Edit Context`; sending is disabled. | No context sent. |
| Unsupported selection | Show paste fallback; do not overwrite clipboard to harvest selection. | Terminal selection/clipboard behavior remains predictable. |
| High-risk command | System-red risk label and insert-only default. | Direct run requires explicit exact-command confirmation if implemented. |
| Unknown-risk command | Status-accent risk label and insert-only default. | Unknown never auto-runs. |

---

## Accessibility Contract

- Palette has accessibility label `Command Intelligence`.
- Flow selector exposes the selected flow and exactly three options.
- Every prompt, paste, and failed-output field has a visible label and matching accessibility label.
- Context preview redaction summary is readable by VoiceOver as counts and labels, not only color.
- Risk labels include reason text and do not rely on color alone.
- `Insert Command`, `Run Command`, `Preview Context`, `Send Request`, `Close Preview`, `Edit Context`, `Open Command Intelligence Settings`, and `Retry Request` must be keyboard reachable.
- Focus order is: flow selector, primary input, optional context field, preview/result content, primary action, secondary actions.
- Decorative separators, glow strokes, and background blur are hidden from accessibility.
- Closing the palette returns VoiceOver and keyboard focus to the terminal workspace where feasible.
- Respect reduced motion across palette open/close, loading, and result transitions.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: READY FOR CHECKER
- [ ] Dimension 2 Visuals: READY FOR CHECKER
- [ ] Dimension 3 Color: READY FOR CHECKER
- [ ] Dimension 4 Typography: READY FOR CHECKER
- [ ] Dimension 5 Spacing/layout stability: READY FOR CHECKER
- [ ] Dimension 6 Registry Safety: READY FOR CHECKER

**Approval:** pending checker
