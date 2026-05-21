# Phase 10: Security and privacy hardening - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 10 makes a terminal-plus-LLM app trustworthy before alpha/beta release work. The phase delivers a written threat model, local data/privacy inventory, expanded redaction tests, Keychain access tests, command-risk policy tests, dependency license/vulnerability review, and a hardened-runtime compatibility pass.

This phase does not add telemetry, support-bundle export, autonomous agents, new providers, plugin architecture, signed distribution, notarization, updater infrastructure, App Store sandbox work, or a public privacy-policy website. Those can use the Phase 10 outputs later, but Phase 10 is the hardening and proof layer for the current app.

Note: `gsd-tools init phase-op 10` did not resolve this phase because the Phase 10 directory did not exist yet, even though `.planning/ROADMAP.md` and `.planning/STATE.md` identify Phase 10 as next. The phase directory was created from the roadmap source of truth.

</domain>

<decisions>
## Implementation Decisions

### Threat Model Scope
- **D-01:** Create a repo-local threat model covering terminal execution, LLM context submission, provider responses, Keychain credential storage, workspace/session persistence, Spotlight indexing, notifications, menu bar surfaces, metrics, visual identity seed, and release/runtime configuration.
- **D-02:** Prioritize realistic desktop threats: accidental private data capture, malicious terminal output pasted into LLM context, model prompt/command injection, provider response suggesting dangerous commands, local preference/persistence leaks, secrets mishandled outside Keychain, dependency/license risk, and hardened-runtime incompatibility.
- **D-03:** Treat cloud/provider compromise, enterprise policy management, plugin sandboxing, crash-report pipelines, and updater signing as adjacent future phases unless the current code already creates a concrete risk.
- **D-04:** The output should be practical and plan-driving: assets, trust boundaries, entry points, abuse cases, current mitigations, remaining gaps, and verification gates. Avoid a generic security essay that downstream agents cannot execute.

### Privacy And Local Data Inventory
- **D-05:** Build a local data inventory that lists every category the app can persist, send, index, display in notifications/menu bar, or include in evidence: preferences, install seed, provider/model IDs, API keys, redacted prompt/context payloads, generated commands, workspace/session layout, recent directories, metrics snapshots, Spotlight metadata, notification content, benchmark markers, and release evidence.
- **D-06:** Classify each item by sensitivity, storage location, default behavior, retention/delete path, user control, and whether it can leave the device. The default stance remains no telemetry and no private shell output/history/prompts/API keys in logs, preferences, notifications, Spotlight, or benchmark evidence.
- **D-07:** The inventory must distinguish current implementation from deferred/future behavior. If a data category is not persisted today, say so explicitly instead of designing a speculative storage system.
- **D-08:** Add source/evidence gates for forbidden persistence and disclosure patterns rather than relying only on written claims.

### LLM Context, Redaction, And Provider Requests
- **D-09:** Preserve the Phase 6 rule that hosted provider requests can only use `ApprovedCommandContextPayload` created from a visible redacted preview. Raw `CommandAssistanceInput`, hidden scrollback, shell history, environment variables, metrics, Keychain data, and unrequested process data must not bypass preview approval.
- **D-10:** Expand `SecretRedactor` coverage with realistic shell-output fixtures: AWS-style keys, GitHub/Slack/OpenAI/Anthropic tokens, bearer/basic headers, private key blocks, password/env assignments, credential URLs, JSON/YAML dotenv-like values, multiline command output, and false-positive-sensitive benign strings.
- **D-11:** Private key blocks and other high-confidence dangerous findings should keep blocking send until the user edits context. Redacted-but-sendable findings should remain visible in the preview summary.
- **D-12:** Provider failures, request IDs, and error states must not include API keys, raw prompts, raw selected output, generated commands, or unredacted context in thrown errors, UI copy, test failure strings, or evidence files.

### Command Risk And Execution Safety
- **D-13:** Treat `CommandRiskClassifier` as the local execution-policy authority. Provider risk labels remain advisory, and every generated command is reclassified locally before the app renders insert/run controls.
- **D-14:** Expand command-risk fixtures for destructive filesystem operations, credential/Keychain access, SSH/private-key reads, clipboard reads, privilege escalation, process termination, package installs, network-to-shell pipelines, remote-service mutations, chained/substituted shell constructs, encoded/obfuscated variants, and local project mutations.
- **D-15:** High-risk and unknown commands remain `insertOnly`; medium-risk commands require confirmation; low-risk commands may run only after explicit user action. No model response may execute shell text automatically.
- **D-16:** Verification should prove UI/action policy and service policy agree. The same classifier result that tests assert should be what app controls use to enable/disable direct run affordances.

### Keychain And Secret Storage
- **D-17:** Keep API keys and any future install identity secrets out of `@AppStorage`, `UserDefaults`, workspace snapshots, Spotlight, notifications, menu bar labels, benchmark evidence, and release docs.
- **D-18:** Reuse the shared `GridOSKit.KeychainCredentialStore` and `CommandIntelligence.KeychainCommandCredentialStore` seams for tests. Verify service/account naming, `kSecClassGenericPassword`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, data-protection keychain use, duplicate update behavior, delete behavior, empty secret handling, and failure mapping.
- **D-19:** Do not add automatic SSH import, hidden Keychain scanning, or broad credential discovery in Phase 10. If SSH-related risk is discussed, document it as a threat/deferred capability unless current code touches it.
- **D-20:** Settings may prove that secure fields clear entered secrets after save/delete and only provider/model identifiers persist as normal preferences; do not store API key values in preference-backed state.

### Persistence, Indexing, Notifications, And Evidence
- **D-21:** Audit workspace/session persistence to prove it stores layout, active pane, profile metadata, and recent directories only. It must not store shell output, command history, terminal transcript, environment variables, process IDs, prompts, generated commands, or secrets.
- **D-22:** Audit Spotlight indexing to prove it remains opt-in and metadata-only: workspace identifier, display label, and directory basename only. No full paths, command output, prompts, generated commands, environment, secrets, or process arguments.
- **D-23:** Audit notifications and menu bar surfaces to prove default copy is sanitized and local: no full command text, shell output, secrets, environment, prompts, generated commands, or full paths.
- **D-24:** Phase 9 benchmark evidence and future smoke evidence must stay synthetic and sanitized. Security gates should scan planning evidence as well as source code.

### Dependency, License, And Hardened Runtime
- **D-25:** Create a dependency/license posture document for the current direct dependencies and inspiration references. At minimum include SwiftTerm, Apple frameworks, XcodeGen/SwiftPM project generation, proprietary repo license posture, and eDEX-UI inspiration/no-copy boundary.
- **D-26:** Perform a lightweight vulnerability/update review using available local lockfiles/project metadata first. If live registry/GitHub lookup is needed, keep it focused on primary sources and record exact dates.
- **D-27:** Verify hardened runtime compatibility against the current XcodeGen setting `ENABLE_HARDENED_RUNTIME: YES`. Phase 10 should build/test with this setting and document any entitlements or runtime exceptions needed or intentionally absent.
- **D-28:** Do not attempt production signing/notarization in this phase unless it is needed to expose a hardened-runtime issue. Signed internal builds belong to Phase 11/12.

### Verification Direction
- **D-29:** Add focused unit tests where code behavior can prove security properties: redaction, Keychain queries, risk classification, context preview/request boundaries, preference key hygiene, persistence/indexing sanitization, and provider failure redaction.
- **D-30:** Add documentation/source gates where behavior is broader than one unit test: forbidden `AppStorage`/`UserDefaults` secret keys, forbidden persisted private data labels, no raw evidence artifacts, no broad `SwiftTerm` leakage into `GridOSApp`, and release/security docs containing the final threat/inventory outputs.
- **D-31:** Final Phase 10 signoff must include full `xcodegen generate --use-cache`, unsigned macOS `xcodebuild ... build test`, `git diff --check`, source/privacy scans, dependency/license review evidence, and hardened-runtime compatibility notes.

### the agent's Discretion
- Exact threat-model format is left to research/planning, but it must be concrete enough to drive tests and release gates.
- Exact filenames are left to planning, with a preference for docs under `docs/` and phase evidence under `.planning/phases/10-security-and-privacy-hardening/`.
- Exact redaction fixture list may be expanded during planning as long as it includes the current token/private-key/env/URL coverage and realistic terminal-output examples.
- Exact dependency review command path is left to research/planning, constrained by reproducibility and primary-source evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap, Product, And Security Scope
- `.planning/ROADMAP.md` — Phase 10 goal and exit criteria.
- `.planning/STATE.md` — Current Phase 09 verification state, carried-forward privacy/security decisions, and Phase 10 handoff.
- `.planning/PROJECT.md` — Product promise, non-negotiables, module boundaries, direct distribution posture, and privacy defaults.
- `docs/production-roadmap.md` — Phase 10 deliverables/acceptance criteria, dependency/license requirements, and release-readiness sequence.
- `docs/security-privacy.md` — Current security posture, LLM context policy, command safety examples, distribution posture, and open security tasks.
- `docs/vision.md` — Product-level terminal/LLM privacy intent and native rewrite target.
- `docs/release.md` — Existing release gates, privacy source scans, performance evidence, and future release checklist.
- `LICENSE` — Current proprietary private-alpha license posture.

### Prior Phase Contracts
- `.planning/phases/03-production-app-frame/03-CONTEXT.md` — Terminal-first frame, settings, focus, recovery, and keyboard policy.
- `.planning/phases/04-real-system-metrics/04-CONTEXT.md` — Local-only metrics posture and no telemetry/LLM handoff.
- `.planning/phases/05-aesthetic-modes/05-CONTEXT.md` — Install seed, visual identity, terminal readability, and evidence constraints.
- `.planning/phases/06-llm-command-palette/06-CONTEXT.md` — Opt-in LLM context, redaction, Keychain API keys, local risk classifier, insert-first command policy, and no auto-execute rule.
- `.planning/phases/06-llm-command-palette/06-VERIFICATION.md` — Verified Command Intelligence safety gates and deterministic fixture evidence.
- `.planning/phases/07-multi-pane-session-management/07-CONTEXT.md` — Workspace persistence scope, active-pane routing, and no process/shell-history resurrection.
- `.planning/phases/07-multi-pane-session-management/07-VERIFICATION.md` — Verified multi-pane process cleanup and persistence behavior.
- `.planning/phases/08-macos-integrations/08-CONTEXT.md` — Keychain generalization, opt-in local notifications, metadata-only indexing, and no private data in integrations.
- `.planning/phases/08-macos-integrations/08-VERIFICATION.md` — Verified menu bar, notification, Keychain, Spotlight, and privacy gates.
- `.planning/phases/09-performance-hardening/09-CONTEXT.md` — Privacy-safe synthetic benchmark evidence and preservation rules.
- `.planning/phases/09-performance-hardening/09-VERIFICATION.md` — Latest benchmark evidence status and privacy proof that Phase 10 should preserve.
- `.planning/phases/09-performance-hardening/evidence/README.md` — Current sanitized performance evidence and misses carried forward.

### Code And Architecture
- `docs/architecture.md` — Module dependency direction and current Phase 1-8 architecture targets.
- `project.yml` — XcodeGen source of truth, dependency list, test targets, and `ENABLE_HARDENED_RUNTIME: YES`.
- `Sources/CommandIntelligence/SecretRedactor.swift` — Existing redaction rules and blocked private-key behavior.
- `Tests/CommandIntelligenceTests/SecretRedactorTests.swift` — Current redaction fixtures to expand.
- `Sources/CommandIntelligence/CommandContextBuilder.swift` — Preview construction and included context sources.
- `Sources/CommandIntelligence/CommandContextPreview.swift` — Approved payload, can-send behavior, and preview model.
- `Sources/CommandIntelligence/CommandIntelligenceService.swift` — Provider-request boundary and local risk reclassification.
- `Sources/CommandIntelligence/AnthropicCommandProvider.swift` — Hosted provider request shaping and system instruction.
- `Tests/CommandIntelligenceTests/AnthropicCommandProviderTests.swift` — Provider failure and API-key non-leak tests.
- `Sources/CommandIntelligence/CommandRiskClassifier.swift` — Local command execution policy.
- `Tests/CommandIntelligenceTests/CommandRiskClassifierTests.swift` — Current risk fixtures to expand.
- `Sources/GridOSKit/KeychainCredentialStore.swift` — Shared Keychain query/client abstraction.
- `Sources/CommandIntelligence/KeychainCommandCredentialStore.swift` — Provider API-key storage adapter.
- `Tests/GridOSKitTests/KeychainCredentialStoreTests.swift` — Shared Keychain behavior tests.
- `Tests/CommandIntelligenceTests/CommandCredentialStoreTests.swift` — Command Intelligence credential-store tests.
- `Sources/GridOSKit/GridOSAppPreferences.swift` — Non-secret preference keys and defaults.
- `Tests/GridOSKitTests/GridOSAppPreferencesTests.swift` — Preference hygiene tests.
- `Sources/TerminalCore/TerminalWorkspacePersistence.swift` — Workspace/session and recent-directory persistence scope.
- `Tests/TerminalCoreTests/TerminalWorkspacePersistenceTests.swift` — Persistence sanitization and restore tests.
- `Sources/Integrations/WorkspaceMetadataIndexer.swift` — Metadata-only Spotlight indexing adapter.
- `Tests/IntegrationsTests/WorkspaceMetadataIndexerTests.swift` — Spotlight metadata privacy tests.
- `Sources/Integrations/LocalNotificationClient.swift` — Local notification delivery abstraction and sanitized copy.
- `Tests/IntegrationsTests/LocalNotificationClientTests.swift` — Notification authorization/result tests.
- `Sources/GridOSApp/CommandPaletteView.swift` — Preview-before-send UI and insert/run controls.
- `Sources/GridOSApp/CommandIntelligenceSettingsView.swift` — Secure API-key entry, save/delete, and preference-backed provider/model IDs.
- `Sources/GridOSApp/MacIntegrationsSettingsView.swift` — Explicit notification/indexing toggles.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SecretRedactor` already covers API key families, bearer/basic headers, private key blocks, password/env assignments, and credential URLs. Phase 10 should expand coverage and edge-case tests rather than replacing it.
- `CommandContextBuilder` already constructs preview blocks from prompt, working directory, selected output, failed command, and failed output, then redacts before building `ApprovedCommandContextPayload`.
- `CommandIntelligenceService` already refuses blocked previews, fetches API keys from `CommandCredentialStore`, and reclassifies every provider command locally before returning results.
- `AnthropicCommandProvider` already sends only the approved preview payload and instructs the provider not to infer hidden shell data, history, environment variables, keys, metrics, or scrollback.
- `CommandRiskClassifier` already has a deterministic local policy for destructive filesystem commands, credential/keychain access, privilege escalation, process termination, network pipes to shell, package installs, remote mutations, local project mutations, and unknown shell constructs.
- `GridOSKit.KeychainCredentialStore` already exposes injectable SecItem clients and uses generic-password queries, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, and data-protection keychain defaults.
- `TerminalWorkspaceSnapshotStore` persists session layout and recent directories under Application Support `gridOS`; it is the right place to prove what is and is not stored.
- `WorkspaceMetadataIndexer` already strips full paths down to directory basenames and isolates Spotlight indexing behind an injectable client.
- Existing tests in `CommandIntelligenceTests`, `GridOSKitTests`, `IntegrationsTests`, and `TerminalCoreTests` provide good targets for hardening additions.

### Established Patterns
- XcodeGen remains authoritative; any test target/source membership or hardened-runtime setting must be updated in `project.yml` and regenerated.
- Feature modules own behavior; `GridOSApp` composes UI and native surfaces but should not own security primitives.
- Secrets go to Keychain; non-secret preferences can use `GridOSAppPreferences` and `@AppStorage`.
- The app must remain usable without a hosted LLM key.
- Terminal correctness and active-pane focus remain protected. Security hardening cannot break shell input, process cleanup, workspace restore, or Command Intelligence insertion behavior.
- Prior phase evidence uses deterministic DEBUG fixtures and source gates; Phase 10 should keep that style for security/privacy proof.

### Integration Points
- Add threat model and data inventory docs under `docs/` or the Phase 10 directory, then link them from `docs/security-privacy.md` and `docs/release.md` if planning chooses.
- Expand `SecretRedactorTests`, `CommandContextPreviewTests`, `AnthropicCommandProviderTests`, `CommandRiskClassifierTests`, `KeychainCredentialStoreTests`, `GridOSAppPreferencesTests`, `WorkspaceMetadataIndexerTests`, and `TerminalWorkspacePersistenceTests`.
- Add or update source/privacy gates in Phase 10 evidence to scan `Sources`, `Tests`, `docs`, and phase evidence for forbidden private-data patterns.
- Add dependency/license review evidence using `project.yml`, `LICENSE`, `README.md`, and SwiftPM/Xcode package metadata.
- Add hardened-runtime compatibility evidence using the existing `ENABLE_HARDENED_RUNTIME: YES` project setting plus full build/test output.

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 10 as the release trust pass: fewer shiny features, more proofs that the app does not accidentally leak what a terminal user cares about.
- The security docs should be plain enough for a future alpha tester or reviewer to understand what gridOS stores, sends, indexes, notifies, and refuses to do.
- The LLM hardening bar is "visible, redacted, approved, then sent" for every provider request.
- Command Intelligence should feel helpful but never spooky: no hidden context, no surprise execution, no raw secret persistence.
- Dependency/license review should explicitly preserve the "from-scratch, no eDEX code/assets/themes copied" posture.

</specifics>

<deferred>
## Deferred Ideas

- Production signing, notarization, Gatekeeper clean-install proof, updater signing, checksums, and distribution packaging belong to Phase 11/12 unless planning finds a hardened-runtime issue that must be fixed now.
- Crash reporting, diagnostics export, support bundles, audit logs, telemetry, and user-enabled history logs require a separate data model and explicit consent flow.
- Plugin sandboxing, extension permissions, marketplace review, and third-party provider/plugin trust are out of scope.
- Automatic SSH key import, Keychain scanning, and credential discovery are out of scope.
- Public privacy-policy website/legal review can use Phase 10 inventory later, but Phase 10 should produce repo-local engineering truth first.
- App Store sandbox strategy remains a later distribution evaluation because terminal/system-monitor behavior may conflict with sandbox constraints.

</deferred>

---

*Phase: 10-security-and-privacy-hardening*
*Context gathered: 2026-05-21*
