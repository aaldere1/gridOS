# Phase 06: LLM command palette - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 6 adds opt-in command intelligence without turning gridOS into an unsafe autonomous terminal agent. The phase delivers a `Command-K` command palette, provider abstraction, Keychain-backed API key setup, suggested-command UX with explanation and insert/run choices, selected-output explain flow, failed-command explain/fix flow, context preview, secret redaction, risk classification, confirmation policy, and human-readable failure states.

This phase does not add conversational shell mode, autonomous command execution, shell-history indexing, always-on command monitoring, telemetry, public plugins, multi-pane session management, menu bar integrations, production signing, updater infrastructure, or beta threat-model hardening. Those belong to later roadmap phases unless explicitly added.

Note: `gsd-tools init phase-op 6` did not parse this repo's simple roadmap format even though `.planning/ROADMAP.md` contains Phase 6. The phase directory was created from the roadmap source of truth.

</domain>

<decisions>
## Implementation Decisions

### Command Palette Shape
- **D-01:** `Command-K` opens a compact command-intelligence palette/sheet over the existing app frame. The terminal remains visible behind or around it, and closing the palette must return focus to the terminal.
- **D-02:** The palette should expose three Phase 6 flows: suggest a command from natural language, explain selected/pasted terminal output, and explain/fix a failed command. These are user-invoked actions only.
- **D-03:** Do not ship conversational shell mode or a persistent agent chat surface in Phase 6. A one-shot request/response palette is enough for the first safe command-intelligence layer.
- **D-04:** `Command-K` may supersede the current `Command-K` terminal clear shortcut, but only if the clear command remains available through an explicit Terminal menu item and a non-conflicting shortcut. Terminal correctness and discoverability must be preserved.

### Provider and Key Setup
- **D-05:** Implement `CommandIntelligence` as the provider, context-packing, redaction, and command-safety boundary. `GridOSApp` composes the UI; provider details must not leak into terminal or app-frame code.
- **D-06:** Build a provider abstraction first. If Phase 6 implements one live hosted provider, default to Anthropic/Claude because the product vision references Claude and command-palette help; keep OpenAI and local providers as protocol-ready future adapters unless planning finds a tiny safe path.
- **D-07:** API key setup is opt-in and stored in Keychain. The app remains fully usable without a configured provider and should show a calm setup/disabled state instead of errors.
- **D-08:** Do not log API keys, prompts, context payloads, generated commands, selected output, shell history, or provider responses by default. A user-enabled audit log is deferred.

### Context Visibility and Redaction
- **D-09:** No shell context leaves the machine unless the user explicitly invokes an LLM action and confirms the request context.
- **D-10:** Before each request, show a concise context preview that includes what will be sent: user prompt, working directory, selected or pasted output if present, recent failed command context if available, and redactions applied. The user can cancel before any network request.
- **D-11:** Context packing should start minimal. Include only the fields needed for the selected flow; do not send full shell history, environment variables, process lists, hidden files, SSH config, Keychain data, or metrics snapshots by default.
- **D-12:** Redaction is required before provider submission. Cover obvious secrets such as API keys, bearer/basic tokens, private key blocks, password assignments, common `.env` values, and credential-looking URLs. Redactions should be visible in the preview.
- **D-13:** Selected-output and failed-command flows should prefer explicit terminal selection or user-pasted text. If SwiftTerm does not expose reliable selected text or scrollback APIs, provide a manual paste/fallback path rather than adding invisible shell hooks.

### Suggested Command and Safety Flow
- **D-14:** Suggested command responses must show the command, plain-language explanation, working directory assumption, context used, and a risk label before any insert/run action.
- **D-15:** Default generated-command handling is insert-first. The primary safe action is to insert the command into the terminal for user inspection/editing.
- **D-16:** A direct Run action may exist only after an explicit user choice. High-risk or unknown-risk commands require a visually distinct confirmation step and should prefer insert-only unless the user confirms the exact command.
- **D-17:** Risk classification must conservatively flag destructive filesystem operations, credential/keychain access, privilege escalation, process killing, network transfer piped into shell, package-manager install scripts, and commands that mutate remote services. Unknowns should bias toward higher risk.
- **D-18:** The app must never execute a generated command automatically as a side effect of receiving a model response.

### Explain and Failed-Command Help
- **D-19:** Explain-output is a read-only assistance flow. It should explain what the selected or pasted terminal output means, likely cause, and possible next checks without mutating the shell.
- **D-20:** Failed-command help is also user-invoked. Phase 6 should not require always-on shell instrumentation; it may use selected/pasted output, current working directory, and any safe terminal metadata the app already has.
- **D-21:** Fix suggestions should follow the same command safety policy as normal suggested commands: explanation first, insert/run choices second, stronger confirmation for risky commands.

### Failure States and Offline Behavior
- **D-22:** Failure copy must be human-readable and product-level: no provider key configured, cancelled before send, offline/network failure, provider rate limit, provider error, redaction blocked request, and unsupported terminal selection should each have a clear path forward.
- **D-23:** LLM failures must not affect shell availability, terminal focus, metrics, or visual rendering. The terminal remains the product's reliable center.

### Verification Direction
- **D-24:** Plan for model/unit tests around provider protocol behavior, Keychain credential storage abstraction, context redaction, risk classification, context preview construction, and no-key/offline failure states.
- **D-25:** Plan for app smoke verification that `Command-K` opens/closes the palette, returns terminal focus, and generated command insertion does not execute until the user explicitly chooses to run.

### the agent's Discretion
- Exact palette layout, copy tone, iconography, and animation are left to planning/implementation, constrained by the terminal-first cockpit and current aesthetic modes.
- Exact provider protocol method names and request/response models are left to research/planning, constrained by testability and provider isolation.
- Exact Keychain wrapper shape is left to research/planning, constrained by not leaking secrets into logs or user defaults.
- Exact risk classifier taxonomy can be refined during planning, as long as it is conservative and testable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap, Product, and Security
- `.planning/ROADMAP.md` — Phase 6 goal and exit criteria.
- `docs/production-roadmap.md` — LLM feature principles, Phase 6 deliverables/acceptance criteria, provider design, and later security hardening scope.
- `docs/vision.md` — Product-level LLM command palette, inline explain, conversational shell deferral, and privacy-first intent.
- `docs/security-privacy.md` — Current security posture, LLM context policy, command safety examples, and open security tasks.
- `.planning/PROJECT.md` — Product promise, module boundaries, non-negotiables, and Phase 5 validated state.
- `.planning/STATE.md` — Current phase status and carried-forward decisions.

### Prior Phase Contracts
- `.planning/phases/03-production-app-frame/03-CONTEXT.md` — Terminal-first cockpit, keyboard/focus policy, settings, accessibility, and recovery decisions.
- `.planning/phases/03-production-app-frame/03-VERIFICATION.md` — Evidence for app-frame focus, settings, keyboard, and smoke behavior.
- `.planning/phases/04-real-system-metrics/04-CONTEXT.md` — Privacy/local-only posture for sensitive app-frame data and terminal dominance.
- `.planning/phases/04-real-system-metrics/04-VERIFICATION.md` — Evidence that metrics are local-only and text-forward.
- `.planning/phases/05-aesthetic-modes/05-CONTEXT.md` — Terminal protection, mode switching focus policy, settings persistence, and aesthetic-mode constraints.
- `.planning/phases/05-aesthetic-modes/05-VERIFICATION.md` — Evidence that visual-mode switching preserves terminal focus and readability.

### Architecture and Code
- `docs/architecture.md` — Module dependency direction and `CommandIntelligence` boundary.
- `docs/release.md` — Existing smoke-test patterns and app launch verification style.
- `project.yml` — Target membership, dependency direction, and XcodeGen source of truth.
- `Sources/CommandIntelligence/CommandIntelligenceStatus.swift` — Current scaffold for the provider/context/redaction/safety module.
- `Sources/GridOSApp/GridOSApp.swift` — Existing app command menus and shortcut registration.
- `Sources/GridOSApp/RootView.swift` — Current terminal-first composition, metrics panel, and visual-mode app frame.
- `Sources/GridOSApp/SettingsView.swift` — Existing Settings and `@AppStorage` persistence pattern.
- `Sources/GridOSKit/GridOSAppPreferences.swift` — Existing preference helper style.
- `Sources/TerminalCore/TerminalSurface.swift` — SwiftTerm adapter, focus restoration, and terminal command bridge.
- `Sources/TerminalCore/TerminalCommandCenter.swift` — Existing menu-to-terminal notification pattern.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Sources/CommandIntelligence/CommandIntelligenceStatus.swift`: Existing scaffold and correct module boundary for provider abstraction, context packing, redaction, and safety policy.
- `Sources/GridOSApp/GridOSApp.swift`: Existing command registration pattern for Terminal and Appearance menus; Phase 6 should add a command-intelligence menu/shortcut here.
- `Sources/TerminalCore/TerminalCommandCenter.swift`: Narrow notification bridge for terminal actions; generated command insertion should use a similarly narrow TerminalCore API rather than reaching into SwiftTerm from the app shell.
- `Sources/TerminalCore/TerminalSurface.swift`: Current SwiftTerm-backed terminal surface, focus restoration, and startup-command smoke path. Any palette overlay must preserve this focus behavior.
- `Sources/GridOSApp/SettingsView.swift`: Existing grouped Settings surface and `@AppStorage` style for user preferences; provider/key setup can reuse the visual grammar while using Keychain for secrets.
- `Sources/GridOSKit/GridOSAppPreferences.swift`: Existing shared preference-helper style for non-secret settings; do not store provider API keys here.
- `Sources/GridOSApp/RootView.swift`: Current terminal-first app composition and right-side activity panel; command intelligence can present as an overlay/sheet without turning the panel into a chat app.

### Established Patterns
- `project.yml` is authoritative for targets and tests; regenerate `gridOS.xcodeproj` after adding CommandIntelligence sources/tests.
- Feature modules own focused APIs; `GridOSApp` composes them. `CommandIntelligence` may depend on `GridOSKit` but should not depend on `TerminalCore`, `RenderCore`, or `SystemMetrics` unless a later narrow protocol is explicitly introduced.
- Terminal correctness and focus beat app chrome, visuals, metrics, and LLM assistance.
- App-level shortcuts use explicit command-key combinations and must avoid fighting shell workflows.
- Repeatable app smoke uses the `--cmd` startup command path and LaunchServices cleanup.
- Sensitive data stays local by default. Phase 4 explicitly avoided metrics-to-LLM handoff; Phase 6 must preserve explicit user action before context leaves the machine.

### Integration Points
- Add public models/protocols in `CommandIntelligence` first: provider protocol, request/response models, context preview, redactor, risk classifier, and failure state models.
- Add `CommandIntelligenceTests` in `project.yml` for provider mocks, redaction, risk classification, and preview construction.
- Add `CommandIntelligenceCommands` or equivalent in `GridOSApp.swift` for `Command-K`, while preserving a non-conflicting Terminal Clear command.
- Add a palette/sheet composition point in `RootView` so the terminal remains visible and focus returns after dismissal.
- Add a TerminalCore insertion API only if needed, keeping generated command insertion explicit and testable.
- Add Keychain access through a small wrapper/abstraction so tests can use an in-memory credential store.

</code_context>

<specifics>
## Specific Ideas

- The product should feel like a careful assistant sitting next to the terminal, not a background agent driving the terminal.
- "Ask -> inspect context -> receive command/explanation -> insert or explicitly run" is the Phase 6 interaction loop.
- The no-key state should feel normal, not broken: gridOS is still a complete terminal without LLM configuration.
- The user should always be able to see why a command is risky before deciding what to do.
- Palette visuals should inherit the current aesthetic mode and stay compact; no giant chat pane in Phase 6.

</specifics>

<deferred>
## Deferred Ideas

- Conversational shell mode / REPL where the model executes multi-step tasks belongs to a later phase.
- Always-on command monitoring, shell-history indexing, and automatic failed-command detection are deferred unless planning proves a safe tiny path.
- Audit logging of prompts/context/generated commands is deferred until a user-controlled data model exists.
- Local model provider implementation is deferred unless research finds a trivial protocol adapter; the abstraction should leave room for it.
- Plugin providers, marketplace providers, public extension APIs, and user-authored command intelligence integrations are deferred.
- Menu bar/Notification Center LLM affordances belong to the macOS integrations phase.
- Full security threat modeling and hardened-runtime compatibility proof remain Phase 10 and later release-readiness work.

</deferred>

---

*Phase: 06-llm-command-palette*
*Context gathered: 2026-05-20*
