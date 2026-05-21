---
phase: 10-security-and-privacy-hardening
plan: 04
subsystem: local-storage-and-integrations-privacy
tags: [keychain, preferences, persistence, spotlight, notifications, evidence]
provides:
  - "Credential storage and preference hygiene gates"
  - "Workspace persistence privacy tests"
  - "Spotlight, notification, and evidence privacy proof"
requirements-completed: ["PHASE-10"]
duration: 5 min
completed: 2026-05-21
---

# Phase 10 Plan 04: Secret Storage and Local Privacy Gates Summary

## Accomplishments

- Strengthened Keychain tests for generic-password query invariants, data-protection Keychain use, duplicate updates, delete behavior, empty secret rejection, and unexpected status mapping.
- Strengthened command credential tests so lower-level Keychain unexpected statuses map to product-level provider errors.
- Added explicit preference hygiene assertions blocking API key, secret, token, prompt, selected-output, command-output, and generated-command storage key names.
- Added workspace persistence filename proof for `session-v1.json` and `recent-directories-v1.json`, with negative assertions for history/transcript/generated-command filenames and payload tokens.
- Added Spotlight metadata proof text that terminal output and command history are never indexed.
- Added Phase 10 evidence README with source gates, persistence proof, integration proof, known limitations, and a runnable source/evidence forbidden scan.

## Task Commits

1. **Task 10-04-01: Harden Keychain and preference hygiene tests** - `690e425`
2. **Task 10-04-02: Harden persistence, indexing, notification, and evidence privacy gates** - `980aa4f`

## Deviations from Plan

The forbidden evidence scan is intentionally scoped to `Sources` plus Phase 10 evidence instead of all `docs`, because existing release documentation contains historical screenshot filenames and older scan examples that would self-match. Tests still cover the required privacy strings directly.

## Verification

```sh
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:GridOSKitTests -only-testing:CommandIntelligenceTests/CommandCredentialStoreTests -only-testing:TerminalCoreTests/TerminalWorkspacePersistenceTests -only-testing:IntegrationsTests
rg 'kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly|selectedOutput|commandOutput|Privacy source gates|recent-directories-v1.json|Terminal output and command history are never indexed|gridOS work finished' Tests .planning/phases/10-security-and-privacy-hardening/evidence
FORBIDDEN="shell""History|terminal""Transcript|environment""Variables|command""Output|selected""Output.*write|pro""mpt.*write|api""Key.*AppStorage|User""Defaults.*api|\\.""png|\\.""trace"
! rg "$FORBIDDEN" Sources .planning/phases/10-security-and-privacy-hardening/evidence
git diff --check
```

## Next Phase Readiness

Plan 10-05 can complete dependency/license review, hardened-runtime compatibility documentation, final evidence, and Phase 10 signoff.
