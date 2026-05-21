# Phase 08: macOS Integrations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 08-macos-integrations
**Areas discussed:** Menu bar extra, Notifications, Keychain-backed secrets, Spotlight and previews, Module boundaries, Verification

---

## Workflow Mode

The project is configured for YOLO execution:

```json
"mode": "yolo",
"workflow": {
  "auto_advance": true,
  "skip_discuss": true
}
```

Because the user previously requested full YOLO mode and `skip_discuss` is enabled, the orchestrator selected recommended defaults instead of pausing for interactive questions.

## Menu Bar Extra

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight companion | Quick open/show, compact metrics, current workspace, recent directories; not a second app UI | ✓ |
| Full control center | Add deeper pane/session manipulation from the menu bar | |
| No menu bar in v1 | Defer to later release polish | |

**Selected default:** Lightweight companion.
**Notes:** Best fit for Phase 8 because it makes gridOS feel Mac-native without competing with terminal focus or creating another control plane.

---

## Notifications

| Option | Description | Selected |
|--------|-------------|----------|
| Opt-in local notifications | Request permission only from Settings or explicit workflow; keep content private | ✓ |
| Ask on first launch | More discoverable but noisy and premature | |
| Always-on shell completion watcher | Broadest feature but likely requires invasive shell instrumentation | |

**Selected default:** Opt-in local notifications.
**Notes:** Long-running command completion remains the target, but hidden shell hooks are not acceptable by default. Research/planning should prefer explicit, reliable command boundaries and ship a narrower foundation if needed.

---

## Keychain-Backed Secrets

| Option | Description | Selected |
|--------|-------------|----------|
| Generalize existing Keychain wrapper | Reuse the tested `KeychainCommandCredentialStore` pattern for broader app secrets | ✓ |
| Keep API-key-only storage | Lower scope, but misses Phase 8's integration foundation | |
| Add SSH key import/management | Useful eventually, but high-risk for privacy and trust | |

**Selected default:** Generalize existing Keychain wrapper.
**Notes:** Provider keys are already Keychain-backed. Phase 8 should improve shared credential infrastructure without scanning or importing SSH secrets.

---

## Spotlight And Previews

| Option | Description | Selected |
|--------|-------------|----------|
| Optional metadata-only foundation | Implement only if data model is ready and privacy boundaries are clear | ✓ |
| Full transcript/session indexing | Powerful, but violates current privacy posture | |
| Skip all indexing/preview work | Safe fallback if research shows too much cost | |

**Selected default:** Optional metadata-only foundation.
**Notes:** If shipped, only low-sensitivity session labels/directory basenames should be indexed. Command output, shell history, prompts, generated commands, secrets, and transcripts are out of scope.

---

## Module Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Add `Integrations` module when shared abstractions appear | Matches architecture target and keeps app composition clean | ✓ |
| Keep all code in `GridOSApp` | Faster initially, but risks app-shell sprawl | |
| Split every integration into separate modules | Too much structure for Phase 8 | |

**Selected default:** Add `Integrations` module when shared abstractions appear.
**Notes:** App code should compose menu bar scenes and settings; notification, indexing, and credential service logic should have testable module-owned APIs.

---

## Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Unit tests plus DEBUG smoke/source gates | Repeatable, privacy-safe, matches previous phase evidence style | ✓ |
| Manual-only verification | Too weak for OS integrations | |
| Live OS services in unit tests | Brittle because notification/menu bar/Spotlight state depends on user machine state | |

**Selected default:** Unit tests plus DEBUG smoke/source gates.
**Notes:** Use injectable clients for Notification Center, Spotlight, and Keychain. Keep manual release smoke for real menu bar/permission behavior.

---

## the agent's Discretion

- Exact menu bar icon treatment, menu item labels, compact metrics formatting, and Settings layout.
- Exact notification threshold for "long-running" after research.
- Whether Spotlight/preview work ships in Phase 8 or is explicitly deferred after research.
- Exact module/target split if implementation can stay simpler while preserving boundaries.

## Deferred Ideas

- Public plugin architecture.
- Release signing/notarization/updater.
- Full command history/search and transcript indexing.
- Automatic SSH key import.
- Widgets, Touch Bar, Continuity, Universal Control, Stage Manager-specific behavior.
