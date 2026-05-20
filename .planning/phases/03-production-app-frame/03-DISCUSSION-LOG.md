# Phase 3: Production app frame - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 03-production-app-frame
**Areas discussed:** app frame, window chrome, settings persistence, keyboard/focus policy, recovery/accessibility

---

## Discussion Scope

| Option | Description | Selected |
| --- | --- | --- |
| Recommended set | Cover all high-impact app-frame choices: window/layout, settings persistence, keyboard focus, accessibility, and state restoration. | yes |
| Core frame | Focus on window chrome, three-panel layout, terminal prominence, menus, and keyboard behavior first. | |
| Recovery polish | Focus on persisted preferences, force-quit recovery, reduced motion, and accessibility first. | |

**User's choice:** Recommended set.
**Notes:** User said, "I will go through all your recommended steps." Recommended choices below were accepted as the Phase 3 direction.

---

## Overall App Frame

| Option | Description | Selected |
| --- | --- | --- |
| Terminal-first cockpit | Terminal remains dominant; system/context panels are present but secondary. | yes |
| Balanced three-panel | Terminal, system strip, and activity/context panel have near-equal visual weight. | |
| Minimal terminal shell | Defer most side panels; focus on window/settings/focus polish. | |

**User's choice:** Terminal-first cockpit.
**Notes:** This keeps terminal usability ahead of visual/dashboard ambition.

---

## Window Chrome

| Option | Description | Selected |
| --- | --- | --- |
| Custom hidden-titlebar Mac window | Polished app-owned header, traffic lights preserved, terminal focus protected. | yes |
| Standard macOS titlebar | Less custom, more native by default. | |
| Full immersive frame | Strongest visual identity, higher risk around focus/fullscreen/accessibility. | |

**User's choice:** Custom hidden-titlebar Mac window.
**Notes:** Existing `GridOSApplication` already uses `.windowStyle(.hiddenTitleBar)`, so Phase 3 should harden this direction rather than pivot away.

---

## Settings Persistence

| Option | Description | Selected |
| --- | --- | --- |
| Real persisted terminal profile | Shell path, font size, reduced motion, visual intensity saved locally. | yes |
| Minimal preferences | Only persist shell/font now; defer visual and layout settings. | |
| Profile system foundation | Introduce named profiles now, even if only one default profile ships. | |

**User's choice:** Real persisted terminal profile.
**Notes:** Current `SettingsView` is placeholder state only. Phase 3 should make the settings real without taking on full named-profile management.

---

## Keyboard and Focus Policy

| Option | Description | Selected |
| --- | --- | --- |
| Terminal owns shell-like shortcuts by default | App shortcuts avoid fighting terminal input; commands use clear menu combos. | yes |
| App shortcuts take precedence | More app-control feel, higher risk for terminal users. | |
| Mode-based | Terminal mode vs app mode, more powerful but heavier UX. | |

**User's choice:** Terminal owns shell-like shortcuts by default.
**Notes:** This carries forward the product rule that terminal correctness beats app chrome.

---

## Recovery and Accessibility

| Option | Description | Selected |
| --- | --- | --- |
| Practical production baseline | Restore window size/position/settings, meaningful reduced motion, labels/focus/contrast pass. | yes |
| Aggressive recovery | Restore more session context like last working directory and layout state now. | |
| Minimal pass | Only fix obvious accessibility/reduced-motion gaps now; deeper recovery later. | |

**User's choice:** Practical production baseline.
**Notes:** Running shell process restoration is explicitly out of scope for Phase 3.

---

## the agent's Discretion

- Exact app-frame spacing and visual composition.
- Exact local persistence mechanism.
- Exact implementation structure for accessibility verification.

## Deferred Ideas

- Real system metrics.
- Multiple visual modes.
- LLM command palette.
- Multi-pane/session-management features.
- Production signing, notarization, packaging, and updater.
