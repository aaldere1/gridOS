---
phase: 10-security-and-privacy-hardening
status: complete
created: 2026-05-21
research_question: "What do we need to know to plan Phase 10 well?"
---

# Phase 10: Security and Privacy Hardening Research

## Research Summary

Phase 10 should harden the current app by making the trust boundaries explicit, proving sensitive data stays out of unsafe storage/output surfaces, and expanding tests around the existing security seams. The codebase already has useful foundations: Keychain-backed credential stores, redacted LLM context previews, a local command-risk classifier, metadata-only Spotlight indexing, sanitized notifications, and privacy-safe benchmark evidence. The plan should therefore avoid inventing a new security framework and instead turn those foundations into release-readable proof.

## Current Security Surfaces

### LLM Context And Provider Requests

- `CommandContextBuilder` is the current boundary for transforming user prompt, working directory, selected/pasted output, failed command, and failed output into redacted preview blocks.
- `ApprovedCommandContextPayload` is the only provider-facing payload the current service should send.
- `CommandIntelligenceService` refuses blocked previews, fetches API keys only through `CommandCredentialStore`, invokes the provider, then reclassifies every generated command locally.
- `AnthropicCommandProvider` sends the approved payload and explicitly tells the provider not to infer unapproved terminal data, hidden history, environment variables, keys, metrics, or scrollback.

Planning implication: Expand tests around the existing request boundary. Do not add background shell capture or direct provider access to raw terminal assistance input.

### Secret Redaction

- `SecretRedactor` already covers API keys, bearer/basic headers, private key blocks, password assignments, env-style secrets, and credential URLs.
- Private key blocks produce blocked reasons, which prevents sending until the user edits context.
- Current fixtures are strong but narrow; Phase 10 should add realistic terminal-output variants and false-positive-sensitive cases.

Planning implication: Add tests before code changes, then extend rules only where fixtures expose gaps.

### Command Risk Policy

- `CommandRiskClassifier` is deterministic and local.
- High-risk examples already include destructive filesystem operations, Keychain/credential access, privilege escalation, process termination, network transfers piped to shell, package installs, and remote mutations.
- Unknown/chained/substituted shell constructs already map to insert-only.

Planning implication: Strengthen the classifier with additional fixtures and prove app action controls consume local policy, not provider labels.

### Keychain And Preferences

- `GridOSKit.KeychainCredentialStore` provides injectable SecItem clients and query models.
- It defaults to generic-password items, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, and the data-protection keychain.
- `CommandIntelligence.KeychainCommandCredentialStore` adapts provider API keys to the shared store.
- `GridOSAppPreferences` stores provider/model IDs and integration toggles, not API key values.

Planning implication: Add tests for query invariants, failure mapping, delete behavior, preference-key hygiene, and source gates against secret persistence in `@AppStorage` or `UserDefaults`.

### Workspace Persistence, Spotlight, Notifications, And Evidence

- `TerminalWorkspaceSnapshotStore` persists session layout and recent directories under Application Support.
- Phase 7 context says live processes, output, history, environment, and process IDs are not restored or persisted.
- `WorkspaceMetadataIndexer` indexes only workspace identifier, display label, and directory basename.
- Local notifications use sanitized product copy by default.
- Phase 9 benchmark evidence is synthetic and explicitly privacy-safe.

Planning implication: Consolidate these guarantees into a data inventory and add negative tests/source scans so the claims stay true.

### Dependencies, License, And Hardened Runtime

- `project.yml` declares SwiftTerm as the only external Swift package and enables `ENABLE_HARDENED_RUNTIME: YES` on the app target.
- The repo currently uses a proprietary private-alpha license posture and explicitly avoids copying eDEX-UI code/assets/themes.
- The Xcode project is generated from XcodeGen, so dependency/runtime changes should be made in `project.yml`.

Planning implication: Produce a small dependency/license/security review doc from local metadata first, then run build/test with hardened runtime enabled. Production signing/notarization remains later.

## Recommended Plan Architecture

1. **Threat model and privacy inventory first.** These documents become the source of truth for the rest of the phase.
2. **LLM/redaction hardening.** Expand redaction and provider-boundary tests while preserving visible preview approval.
3. **Command-risk hardening.** Expand classifier fixtures and prove app controls honor local policy.
4. **Secret/persistence/integration proof.** Keychain, preferences, workspace snapshots, Spotlight, notifications, menu bar, and evidence get negative tests/source gates.
5. **Dependency/runtime/final signoff.** Dependency license/vulnerability posture, hardened-runtime compatibility, final evidence, roadmap/state handoff.

## Validation Architecture

Phase 10 validation should combine unit tests, source scans, docs/evidence checks, and the full app build/test gate.

Recommended gates:

- `xcodegen generate --use-cache`
- `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- `git diff --check`
- `rg 'Threat Model|Privacy Data Inventory|Dependency and License Review|Hardened Runtime' docs .planning/phases/10-security-and-privacy-hardening`
- `rg 'SecretRedactor|RedactionFinding|privateKey|credentialURL|AWS|Authorization: Bearer' Tests/CommandIntelligenceTests Sources/CommandIntelligence`
- `rg 'CommandRiskClassifier|insertOnly|requiresConfirmation|security dump-keychain|curl .*\\|.*sh|sudo|rm -rf' Tests/CommandIntelligenceTests Sources/CommandIntelligence`
- `rg 'kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly|kSecUseDataProtectionKeychain' Sources/GridOSKit Tests/GridOSKitTests Sources/CommandIntelligence Tests/CommandIntelligenceTests`
- `! rg 'apiKey.*AppStorage|UserDefaults.*api|shellHistory|terminalTranscript|environmentVariables|commandOutput|selectedOutput.*write|prompt.*write|\\.png|\\.trace' Sources Tests docs .planning/phases/10-security-and-privacy-hardening/evidence`

Manual/RC gates:

- Review threat model and data inventory for completeness.
- Run a local debug app smoke for Command Intelligence preview/send only if Phase 10 changes UI action policy.
- Confirm hardened runtime remains enabled in `project.yml` and the unsigned build/test still passes.

## Risks And Planning Notes

- Too much scope could turn Phase 10 into release distribution. Keep signing/notarization/updater work deferred.
- Redaction rules can create false positives. Add benign fixtures alongside secret fixtures.
- Source gates can overmatch test fixtures. Keep forbidden scans pointed at source, docs, and evidence where appropriate, and use exact positive test fixtures where secrets are intentionally synthetic.
- Dependency vulnerability review may require live lookup later. Plans should start from local primary files and document any live lookup dates if performed.

## Research Outcome

Research complete. Phase 10 should be planned as a five-plan hardening pass with concrete docs, tests, gates, and final verification evidence.
