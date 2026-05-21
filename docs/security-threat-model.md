# gridOS Threat Model

## Scope

This model covers the current gridOS app: a local macOS terminal, system cockpit, and optional one-shot LLM command assistance surface. It focuses on current code and release-readiness risks before alpha.

In scope:

- `TerminalCore` shell lifecycle, pane routing, input, output activity, and workspace persistence.
- `CommandIntelligence` context preview, redaction, provider requests, generated command display, and local run policy.
- `GridOSKit.KeychainCredentialStore` and `CommandIntelligence.KeychainCommandCredentialStore`.
- `TerminalWorkspaceSnapshotStore` Application Support persistence.
- `WorkspaceMetadataIndexer` Core Spotlight metadata indexing.
- `LocalNotificationClient` local notification delivery.
- `MenuBarExtra` companion surface.
- `SystemMetrics` local host metrics.
- `RenderCore` visual identity and install seed behavior.
- `project.yml`, hardened runtime setting, generated Xcode project, and `SwiftTerm` dependency.

Out of scope for this phase: updater signing, notarization submission, crash reporting, support bundle export, telemetry, plugin sandboxing, enterprise policy, App Store sandbox migration, and new provider integrations.

## Assets

| Asset | Why it matters | Current owner |
| --- | --- | --- |
| Provider API keys | Hosted LLM credentials must not leak or persist outside Keychain. | `CommandIntelligence`, `GridOSKit.KeychainCredentialStore` |
| Terminal input/output | Terminal text can contain source code, credentials, infrastructure names, private errors, and user intent. | `TerminalCore`, `GridOSApp` |
| Approved LLM context | This is the only data allowed to leave the device for hosted command assistance. | `CommandIntelligence` |
| Generated commands | Commands can mutate files, credentials, remote services, or the local machine. | `CommandIntelligence`, `GridOSApp` |
| Workspace snapshots | Layout and recent directories are useful, but must not become a transcript store. | `TerminalWorkspaceSnapshotStore` |
| Spotlight metadata | Indexed data can surface outside the app. | `WorkspaceMetadataIndexer` |
| Notification content | Notification copy can appear on lock screens or in system history. | `LocalNotificationClient` |
| Menu bar status | Compact status must not reveal private terminal data. | `MenuBarExtra`, `MacIntegrationsController` |
| System metrics | Metrics are local utility data, not telemetry. | `SystemMetrics` |
| Visual install seed | Procedural identity should not expose raw machine identifiers. | `RenderCore`, `GridOSKit` |
| Dependencies and runtime settings | Dependency or runtime mistakes can affect execution, signing, or trust. | `project.yml`, release docs |

## Trust Boundaries

| Boundary | Trusted side | Untrusted or lower-trust side | Required control |
| --- | --- | --- | --- |
| Terminal to LLM context | User-visible redacted preview | Raw shell content and selected output | Explicit user action, redaction, cancel path |
| App to hosted provider | `ApprovedCommandContextPayload` | Network/API boundary | Provider request contains only approved payload |
| Provider response to shell | Local UI review and classifier | Model-proposed commands | Local risk classification before insert/run |
| App to Keychain | Keychain descriptor/query boundary | Preference and UI state | Secrets use Keychain only |
| Workspace persistence | Layout/recent-directory metadata | Shell output, history, environment, process state | Codable snapshot tests and source gates |
| App to Spotlight | Sanitized metadata | System-wide search index | Opt-in, basename-only metadata |
| App to notifications | Sanitized local copy | macOS notification surfaces | No full command, output, secrets, prompts, or full paths by default |
| App to menu bar | Compact host/workspace status | Always-visible system UI | No private terminal text or secret values |
| Build config to runtime | `project.yml` source of truth | Generated project drift | XcodeGen regeneration and hardened runtime check |

## Entry Points

- Keyboard and menu commands, especially Command Intelligence and generated command actions.
- Terminal text selection or pasted output used for explain/fix flows.
- Provider API-key entry and delete actions.
- Workspace restore and recent-directory persistence.
- Metadata indexing toggle and indexing calls.
- Notification permission and delivery calls.
- Menu bar open/status/recent-directory actions.
- Dependency updates in `project.yml`.
- Release build settings such as `ENABLE_HARDENED_RUNTIME`.

## Abuse Cases

| Abuse case | Attack or failure mode | Existing mitigations | Phase 10 gates |
| --- | --- | --- | --- |
| Accidental LLM context leak | Raw shell output, prompt text, or working directory is sent without user approval. | Preview-before-send, redaction, `ApprovedCommandContextPayload`. | Provider-boundary tests and source gates. |
| Prompt injection from terminal output | Terminal output instructs the model to exfiltrate secrets or ignore policy. | Provider prompt says to use only approved preview; local classifier controls execution. | Redaction fixtures, provider request tests, command-risk tests. |
| Dangerous provider command | Provider suggests destructive or credential-touching command and labels it low risk. | Local `CommandRiskClassifier` reclassifies provider commands. | Classifier fixtures and app action-policy checks. |
| API key stored outside Keychain | API key ends up in `@AppStorage`, `UserDefaults`, logs, snapshots, or docs. | Keychain credential stores and secure field clearing. | Keychain tests and preference/source scans. |
| Workspace persistence captures private shell data | Session files become shell history or output logs. | Snapshot model stores layout and recent directories only. | Persistence tests and forbidden-field scans. |
| Spotlight indexes private terminal data | Search index contains terminal output, prompts, secrets, or full paths. | `WorkspaceMetadataIndexer` uses display labels and directory basename only. | Indexer tests and opt-in/source gates. |
| Notification exposes command output | Notification body leaks full command, output, secret, prompt, or path. | Default `gridOS work finished` copy is sanitized. | Notification tests and release evidence. |
| Hardened runtime incompatibility | App builds but fails later when hardened runtime is enforced. | `ENABLE_HARDENED_RUNTIME: YES` in `project.yml`. | Build/test gate and runtime docs. |

## Existing Mitigations

- No telemetry by default.
- No hosted LLM request without explicit user action.
- `SecretRedactor` redacts common API keys, authorization headers, private key blocks, password assignments, env-style secrets, and credential URLs.
- Private key blocks block provider send until the user edits context.
- `CommandIntelligenceService` sends only `preview.approvedPayload` to providers.
- Provider API keys are stored through Keychain-backed stores.
- Provider/model IDs are normal preferences; API keys, prompts, generated commands, and responses are not preference data.
- `CommandRiskClassifier` is the local command execution authority.
- Workspace snapshots restore layout and recent directories as fresh shells, not live process state.
- Spotlight indexing is opt-in and metadata-only.
- Notifications are opt-in/local and use sanitized default copy.
- Phase 9 evidence uses synthetic markers instead of private terminal content.

## Open Gaps

- Threat model and data inventory must remain linked to final verification.
- Redaction fixtures need realistic terminal-output coverage and benign false-positive cases.
- Command-risk tests need additional obfuscated/chained/credential/privileged fixtures.
- App run controls need source/test proof that they consume local risk policy.
- Keychain and preference hygiene need stronger negative assertions.
- Persistence, Spotlight, notification, and evidence boundaries need consolidated source gates.
- Dependency/license/security review is not yet documented.
- Hardened runtime compatibility needs final Phase 10 build/test evidence.

## Verification Gates

```sh
rg '# gridOS Threat Model|## Trust Boundaries|Accidental LLM context leak|Hardened runtime incompatibility' docs/security-threat-model.md
rg 'SecretRedactor|CommandRiskClassifier|KeychainCredentialStore|WorkspaceMetadataIndexer|LocalNotificationClient' Sources Tests docs
git diff --check
```
