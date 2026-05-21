# Phase 10: Security and privacy hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-21
**Phase:** 10-security-and-privacy-hardening
**Mode:** Auto-selected defaults from existing YOLO/skip-discuss project settings
**Areas discussed:** Threat model scope, Privacy inventory, LLM context/redaction, Command risk policy, Keychain and secret storage, Persistence/indexing/notifications, Dependency/license/hardened runtime

---

## Threat Model Scope

| Option | Description | Selected |
| --- | --- | --- |
| Current-app trust boundaries | Cover terminal, LLM, Keychain, persistence, integrations, and runtime settings that exist now. | yes |
| Future-platform security program | Include plugins, updater, telemetry, crash reporting, enterprise policy, and App Store sandbox strategy now. | |
| Minimal checklist only | Write a short checklist without abuse cases or trust boundaries. | |

**User's choice:** Auto-selected current-app trust boundaries.
**Notes:** This keeps Phase 10 practical and avoids eating future release/distribution phases.

---

## Privacy Inventory

| Option | Description | Selected |
| --- | --- | --- |
| Full local data map | List stored, sent, indexed, notified, displayed, and evidence-captured data with sensitivity, retention, and user control. | yes |
| Only LLM data | Focus on prompts/API keys/provider requests only. | |
| Legal-policy draft first | Start from public privacy-policy prose before engineering inventory. | |

**User's choice:** Auto-selected full local data map.
**Notes:** A terminal app needs engineering truth before legal copy. The inventory should separate current implementation from future/deferred behavior.

---

## LLM Context And Redaction

| Option | Description | Selected |
| --- | --- | --- |
| Visible approved payload only | Preserve preview-before-send and expand redaction/provider tests around `ApprovedCommandContextPayload`. | yes |
| Add background shell hooks | Capture richer context automatically to improve model answers. | |
| Trust provider prompts | Rely primarily on provider system instructions to avoid secrets. | |

**User's choice:** Auto-selected visible approved payload only.
**Notes:** This carries forward Phase 6's strongest safety choice: redacted preview first, provider send second, no hidden shell context.

---

## Command Risk Policy

| Option | Description | Selected |
| --- | --- | --- |
| Conservative local authority | Expand local classifier tests; high/unknown stay insert-only, medium requires confirmation. | yes |
| Provider-led risk | Trust provider risk labels when deciding run controls. | |
| Disable direct run entirely | Force all generated commands to insert-only forever. | |

**User's choice:** Auto-selected conservative local authority.
**Notes:** This preserves helpful low-risk direct run after explicit user action while keeping provider labels advisory.

---

## Keychain And Secret Storage

| Option | Description | Selected |
| --- | --- | --- |
| Audit existing Keychain seams | Verify SecItem queries, accessibility, data-protection keychain use, duplicate update, delete, and no preference leakage. | yes |
| Build a new secret subsystem | Replace existing stores with a broader vault abstraction now. | |
| Add SSH key import | Start managing/importing SSH secrets in Phase 10. | |

**User's choice:** Auto-selected audit existing Keychain seams.
**Notes:** Existing `GridOSKit.KeychainCredentialStore` and `CommandIntelligence.KeychainCommandCredentialStore` are the right hardening targets.

---

## Persistence, Indexing, Notifications, And Evidence

| Option | Description | Selected |
| --- | --- | --- |
| Negative-proof audit | Prove persisted/indexed/notified/evidence data excludes private terminal/LLM/secrets by tests and source gates. | yes |
| Add richer history/search | Persist more shell context for future search and support flows. | |
| Trust docs only | Document privacy intent without source/test gates. | |

**User's choice:** Auto-selected negative-proof audit.
**Notes:** Phase 7/8/9 already established sanitized persistence, indexing, notifications, and benchmark evidence; Phase 10 should make that proof systematic.

---

## Dependency, License, And Hardened Runtime

| Option | Description | Selected |
| --- | --- | --- |
| Lightweight release-readiness review | Document current dependencies/licenses, no-copy inspiration boundary, and hardened-runtime build/test compatibility. | yes |
| Full production distribution | Sign, notarize, package, and Gatekeeper-test release artifacts now. | |
| Skip until beta | Defer dependency/license/runtime review to Phase 12. | |

**User's choice:** Auto-selected lightweight release-readiness review.
**Notes:** Production signing belongs later, but Phase 10 should surface license/security/runtime blockers before alpha.

---

## the agent's Discretion

- Exact threat model format.
- Exact Phase 10 evidence file layout.
- Exact expanded redaction/risk fixture list beyond required categories.
- Exact dependency review command path, constrained by primary-source evidence.

## Deferred Ideas

- Production signing/notarization/updater/Gatekeeper proof.
- Crash reporting, diagnostics export, support bundles, telemetry, audit logs, and user-enabled shell history.
- Plugin sandboxing and extension trust model.
- Automatic SSH key import or Keychain scanning.
- Public privacy-policy website/legal copy.
