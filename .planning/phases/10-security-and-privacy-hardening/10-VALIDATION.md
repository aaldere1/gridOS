---
phase: 10
slug: security-and-privacy-hardening
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-21
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest plus shell/source gates |
| **Config file** | `project.yml` |
| **Quick run command** | `git diff --check && rg 'Threat Model|Privacy Data Inventory|SecretRedactor|CommandRiskClassifier|Keychain|Hardened Runtime' .planning/phases/10-security-and-privacy-hardening docs Sources Tests` |
| **Full suite command** | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| **Estimated runtime** | ~60 seconds for full build/test |

---

## Sampling Rate

- **After every task commit:** Run `git diff --check` plus that task's focused `rg`/test command.
- **After every plan wave:** Run `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`.
- **Before `$gsd-verify-work`:** Full suite, docs/evidence source gates, privacy negative scans, and hardened-runtime checks must pass.
- **Max feedback latency:** 120 seconds for focused checks; 300 seconds for full build/test.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | Threat model | docs/source | `rg 'Assets|Trust Boundaries|Entry Points|Abuse Cases|Mitigations|Open Gaps' docs/security-threat-model.md` | ✅ | ✅ green |
| 10-01-02 | 01 | 1 | Privacy inventory and release links | docs/source | `rg 'Privacy Data Inventory|Stored|Sent|Indexed|Notifications|Evidence|User Control' docs/privacy-data-inventory.md docs/security-privacy.md docs/release.md` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | Redaction fixtures | XCTest/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/SecretRedactorTests && rg 'AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|"api_key"|access_token:|false-positive' Tests/CommandIntelligenceTests/SecretRedactorTests.swift` | ✅ | ✅ green |
| 10-02-02 | 02 | 2 | Provider/request boundary | XCTest/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests && rg 'approvedPreview|sk-ant-should-not-leak|redactionBlocked|approvedPayload|Use only the approvedPreview payload above' Sources/CommandIntelligence Tests/CommandIntelligenceTests` | ✅ | ✅ green |
| 10-03-01 | 03 | 2 | Command-risk fixtures | XCTest/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/CommandRiskClassifierTests && rg 'security dump-keychain|cat ~/.ssh/id_ed25519|sudo tee /etc/hosts|base64 -d \\| sh|Encoded shell payload' Tests/CommandIntelligenceTests/CommandRiskClassifierTests.swift` | ✅ | ✅ green |
| 10-03-02 | 03 | 2 | App action policy | source/XCTest | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests && rg 'riskClassifier.classify|localRisk.policy|Insert for Review|Run exactly this command\\?|providerRiskLabel' Sources/GridOSApp Sources/CommandIntelligence Tests/CommandIntelligenceTests` | ✅ | ✅ green |
| 10-04-01 | 04 | 3 | Keychain and preference hygiene | XCTest/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:GridOSKitTests/KeychainCredentialStoreTests -only-testing:CommandIntelligenceTests/CommandCredentialStoreTests && rg 'kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly|kSecUseDataProtectionKeychain' Sources/GridOSKit Tests/GridOSKitTests Sources/CommandIntelligence Tests/CommandIntelligenceTests` | ✅ | ⬜ pending |
| 10-04-02 | 04 | 3 | Persistence/indexing/notification privacy | XCTest/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:TerminalCoreTests/TerminalWorkspacePersistenceTests -only-testing:IntegrationsTests && ! rg 'shellHistory|terminalTranscript|environmentVariables|commandOutput|prompt.*write|selectedOutput.*write' Sources/TerminalCore Sources/Integrations Tests/TerminalCoreTests Tests/IntegrationsTests` | ✅ | ⬜ pending |
| 10-05-01 | 05 | 4 | Dependency/license/runtime review | docs/source | `rg 'SwiftTerm|LICENSE|eDEX|ENABLE_HARDENED_RUNTIME|Hardened Runtime|Dependency and License Review' docs .planning/phases/10-security-and-privacy-hardening project.yml LICENSE` | ❌ W0 | ⬜ pending |
| 10-05-02 | 05 | 4 | Final verification and handoff | full gate | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `docs/security-threat-model.md` — threat model output.
- [ ] `docs/privacy-data-inventory.md` — local data inventory.
- [ ] `.planning/phases/10-security-and-privacy-hardening/evidence/README.md` — final Phase 10 evidence log.
- [ ] `.planning/phases/10-security-and-privacy-hardening/10-VERIFICATION.md` — final verification report.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Threat model completeness | Phase 10 signoff | Human review is needed to confirm the abuse cases match real product risk | Read `docs/security-threat-model.md` and confirm terminal, LLM, Keychain, persistence, integrations, dependency, and runtime surfaces are covered. |
| Privacy inventory completeness | Phase 10 signoff | Source scans prove absences, but humans must confirm categories are not missing | Read `docs/privacy-data-inventory.md` and confirm every stored/sent/indexed/notified/evidence data class is represented. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-21
