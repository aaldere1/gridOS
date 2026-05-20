---
phase: 06
slug: llm-command-palette
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-20
---

# Phase 06 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest via Xcode scheme |
| **Config file** | `project.yml` and `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` |
| **Quick run command** | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| **Full suite command** | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` |
| **Estimated runtime** | ~90-180 seconds |

## Sampling Rate

- **After every task commit:** Run `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`.
- **After every plan wave:** Run `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check`.
- **Before `$gsd-verify-work`:** Full suite, source checks, and manual smoke evidence must be green.
- **Max feedback latency:** 180 seconds for automated build/test feedback.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-W0-01 | 01 | 0 | `CommandIntelligence` exposes flow, request, response, failure, provider, preview, redaction, risk, and credential-store models | unit/source | `rg 'CommandIntelligenceFlow|LLMCommandProvider|CommandContextPreview|SecretRedactor|CommandRiskClassifier|CommandCredentialStore' Sources/CommandIntelligence Tests/CommandIntelligenceTests` plus quick run command | no, add sources and tests | pending |
| 06-W0-02 | 01 | 0 | Redaction masks API keys, bearer/basic tokens, private key blocks, password assignments, `.env` values, and credential URLs before preview/send | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/SecretRedactorTests` | no, add test file | pending |
| 06-W0-03 | 01 | 0 | Risk classifier conservatively flags destructive filesystem commands, credential/keychain access, privilege escalation, process killing, network pipe-to-shell, package-manager install scripts, and remote mutations | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/CommandRiskClassifierTests` | no, add test file | pending |
| 06-W0-04 | 01 | 0 | Context preview is the provider payload source and includes prompt, cwd, selected or pasted output, failed-command context, redaction labels, and blocked reasons | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/CommandContextPreviewTests` | no, add test file | pending |
| 06-W0-05 | 01 | 0 | No-key and credential storage states use `CommandCredentialStore`; production key storage uses Keychain, not `@AppStorage` or `UserDefaults` | unit/source | `rg 'CommandCredentialStore|KeychainCommandCredentialStore|kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly' Sources/CommandIntelligence Tests/CommandIntelligenceTests` and `! rg 'apiKey.*AppStorage|UserDefaults.*api|anthropic.*AppStorage' Sources` | no, add source/test files | pending |
| 06-W0-06 | 01 | 0 | Anthropic provider request shaping uses `POST /v1/messages`, `x-api-key`, `anthropic-version: 2023-06-01`, structured response decoding, and mapped 401/429/5xx/network/invalid-response failures | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/AnthropicCommandProviderTests` | no, add test file | pending |
| 06-UI-01 | 02 | 1 | `Command-K` opens the command palette and Terminal Clear remains visible on a non-conflicting shortcut | source/smoke | `rg 'keyboardShortcut\\(\"k\", modifiers: \\[\\.command\\]\\)|CommandIntelligenceCommands|Clear|Option' Sources/GridOSApp` plus app smoke | no, add palette/commands | pending |
| 06-UI-02 | 02 | 1 | Palette exposes `Suggest Command`, `Explain Output`, and `Fix Failed Command` flows without persistent chat or autonomous shell mode | unit/source | `rg 'suggestCommand|explainOutput|failedCommandHelp|Suggest Command|Explain Output|Fix Failed Command' Sources/CommandIntelligence Sources/GridOSApp Tests/CommandIntelligenceTests` | no, add source/tests | pending |
| 06-UI-03 | 02 | 1 | Context preview appears before every provider send and can cancel before network request creation | unit/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/CommandContextPreviewTests` plus `rg 'approvedPreview|cancel|canSend' Sources/CommandIntelligence Sources/GridOSApp` | no, add source/tests | pending |
| 06-TERM-01 | 03 | 2 | Terminal selection, insertion, run, and focus restoration are exposed through `TerminalCore.TerminalInteractionController` without importing SwiftTerm into `GridOSApp` | unit/source | `rg 'TerminalInteractionController|getSelection|sendText|focusTerminal' Sources/TerminalCore Sources/GridOSApp` and `! rg 'import SwiftTerm' Sources/GridOSApp` | no, add controller | pending |
| 06-SAFE-01 | 03 | 2 | Insert adds generated command text without executing; Run appends newline only after explicit user action and risk policy gate | source/smoke | `rg 'insert\\(|run\\(|requiresConfirmation|insertOnly' Sources/TerminalCore Sources/GridOSApp Sources/CommandIntelligence` plus manual insert/run smoke | no, add controller/UI | pending |
| 06-FAIL-01 | 04 | 3 | Human-readable failures exist for no key, cancelled, offline/network failure, provider rate limit, provider error, invalid provider response, redaction blocked request, and unsupported selection | unit/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/CommandIntelligenceFailureTests` plus `rg 'No provider key|Cancelled|Offline|Rate limit|redaction|selection' Sources/CommandIntelligence Sources/GridOSApp` | no, add source/tests | pending |

## Wave 0 Requirements

- [ ] `project.yml` includes `CommandIntelligenceTests` as an XCTest target and adds it to the `gridOS` scheme.
- [ ] `Tests/CommandIntelligenceTests/SecretRedactorTests.swift` covers API-key, bearer/basic token, private-key, password assignment, `.env`, and credential-URL redaction.
- [ ] `Tests/CommandIntelligenceTests/CommandRiskClassifierTests.swift` covers low, medium, high, and unknown risk, including the explicitly listed high-risk command classes.
- [ ] `Tests/CommandIntelligenceTests/CommandContextPreviewTests.swift` proves preview construction redacts before send and exposes the exact approved payload.
- [ ] `Tests/CommandIntelligenceTests/CommandCredentialStoreTests.swift` covers in-memory store behavior and no-key state without real Keychain access.
- [ ] `Tests/CommandIntelligenceTests/AnthropicCommandProviderTests.swift` covers mocked request headers/body, structured decode, refusals/truncation/invalid JSON, and HTTP/network failure mapping.
- [ ] `Tests/CommandIntelligenceTests/CommandIntelligenceFailureTests.swift` covers user-facing title/message/recovery copy for every required failure state.
- [ ] Source-check commands are copied into plan verification criteria so executor proof includes shortcut, storage, privacy, and no-SwiftTerm-leak checks.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `Command-K` palette focus restoration | LLM-01, LLM-12 | First responder behavior crosses SwiftUI, AppKit, and SwiftTerm | Launch Debug app, focus terminal, press `Command-K`, close palette with Escape or Cancel, type `printf 'PHASE6_FOCUS\n' > /tmp/gridos_phase6_focus.txt`, and verify the file exists. |
| Insert does not execute | LLM-09 | Requires observing the real shell after UI insertion | Use a mock/live suggested command `printf 'PHASE6_INSERT\n' > /tmp/gridos_phase6_insert.txt`; click Insert; verify `/tmp/gridos_phase6_insert.txt` does not exist until Return or explicit Run. |
| Run confirmation gate | LLM-07, LLM-09 | Exact visual confirmation and no-auto-run behavior need real UI review | Use a high-risk fixture such as `rm -rf ~/tmp/gridos-test`; verify high/unknown risk is insert-only or shows a distinct exact-command confirmation, and no execution happens on model response. |
| Selected-output explain fallback | LLM-02, LLM-10 | SwiftTerm selection behavior varies by terminal state and alternate-screen apps | Select visible output and open Explain Output; if selected text is unavailable, verify paste fallback and unsupported-selection copy are clear. |
| No-key state leaves terminal usable | LLM-03, LLM-12 | Needs live app flow through Settings/palette while no provider key exists | Remove configured provider key, open palette, trigger an LLM flow, verify setup copy appears, close palette, and type in the terminal successfully. |

## Recommended Source Checks

```bash
rg 'CommandIntelligenceFlow|suggestCommand|explainOutput|failedCommandHelp' Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'SecretRedactor|RedactionFinding|private key|Bearer|Basic|credential URL' Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'CommandRiskClassifier|network pipe|sudo|rm -rf|git push|kubectl|docker|brew install|npm install' Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'CommandCredentialStore|KeychainCommandCredentialStore|kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly' Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'keyboardShortcut\("k", modifiers: \[\.command\]\)|CommandIntelligenceCommands|Clear' Sources/GridOSApp
rg 'TerminalInteractionController|getSelection|sendText|focusTerminal' Sources/TerminalCore Sources/GridOSApp
! rg 'apiKey.*AppStorage|UserDefaults.*api|anthropic.*AppStorage|import SwiftTerm' Sources/GridOSApp Sources/CommandIntelligence
```

## Validation Sign-Off

- [x] All planned work has automated verification or explicit manual evidence.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers missing command-intelligence model, redaction, risk, preview, credential, provider, and failure coverage.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 180 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending Phase 6 execution evidence.
