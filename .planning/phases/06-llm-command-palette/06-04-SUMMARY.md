---
phase: 06-llm-command-palette
plan: 04
subsystem: command-intelligence
tags: [swift, macos, anthropic, keychain, settings, xctest]

requires:
  - phase: 06-01
    provides: CommandIntelligence provider, request, response, failure, preview, and credential-store contracts
  - phase: 06-02
    provides: redacted approved-preview payload construction
  - phase: 06-03
    provides: local command risk and run-policy contracts for later palette use
provides:
  - Anthropic Messages API adapter over Foundation URLSession
  - Security.framework Keychain credential storage with injectable SecItem tests
  - Command Intelligence Settings section for provider/model and key setup
affects: [06-05, command-palette, provider-setup, keychain, settings]

tech-stack:
  added: [Security.framework Keychain Services, Anthropic Messages REST API]
  patterns: [injectable HTTP transport, injectable SecItem client, Keychain-only API key storage, non-secret AppStorage preferences]

key-files:
  created:
    - Sources/CommandIntelligence/AnthropicCommandProvider.swift
    - Sources/CommandIntelligence/KeychainCommandCredentialStore.swift
    - Sources/GridOSApp/CommandIntelligenceSettingsView.swift
    - Tests/CommandIntelligenceTests/AnthropicCommandProviderTests.swift
  modified:
    - gridOS.xcodeproj/project.pbxproj
    - Sources/GridOSKit/GridOSAppPreferences.swift
    - Sources/GridOSApp/SettingsView.swift
    - Tests/CommandIntelligenceTests/CommandCredentialStoreTests.swift
    - Tests/GridOSKitTests/GridOSAppPreferencesTests.swift

key-decisions:
  - "Use direct Anthropic Messages API calls with Foundation URLSession and no provider SDK dependency."
  - "Store provider API keys only in Keychain generic-password items under com.aaldere1.gridos.command-intelligence."
  - "Persist only provider and model IDs through GridOSKit/AppStorage; API keys, prompts, generated commands, and responses are not preference data."

patterns-established:
  - "Anthropic provider requests are built only from LLMCommandRequest.approvedPreview."
  - "SecItem calls route through KeychainSecItemClient so tests can validate queries without touching the real user Keychain."
  - "Settings exposes configured/no-key state without echoing saved provider keys."

requirements-completed: [PHASE-06, LLM-03, LLM-04, LLM-08, LLM-11]

duration: 9min
completed: 2026-05-20
---

# Phase 06 Plan 04: Anthropic Provider and Keychain Setup Summary

**Anthropic command intelligence now has a direct Messages API adapter, Keychain-only credential storage, and a Settings setup surface for the normal no-key and configured states.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-20T19:16:52Z
- **Completed:** 2026-05-20T19:25:35Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added `AnthropicCommandProvider` with `POST /v1/messages`, `x-api-key`, `anthropic-version: 2023-06-01`, `claude-sonnet-4-6`, approved-preview-only request construction, request ID preservation, and provider/network/decode failure mapping.
- Added `KeychainCommandCredentialStore` using generic-password SecItem queries, the required service name, account-by-provider ID, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, update-on-duplicate behavior, and a testable SecItem client.
- Added `CommandIntelligenceSettingsView` inside Settings with provider/model persistence, Keychain-backed save/remove actions, configured/no-key copy, and no saved key echo.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Anthropic provider tests** - `29f04b9` (test)
2. **Task 1 GREEN: Anthropic provider adapter** - `565c46c` (feat)
3. **Task 2 RED: Keychain and preference tests** - `18c36a9` (test)
4. **Task 2 GREEN: Keychain credential store and preferences** - `679ebf5` (feat)
5. **Task 3: Command Intelligence Settings UI** - `a52cb21` (feat)

## Files Created/Modified

- `Sources/CommandIntelligence/AnthropicCommandProvider.swift` - Direct Anthropic Messages API adapter and injectable HTTP transport.
- `Tests/CommandIntelligenceTests/AnthropicCommandProviderTests.swift` - Mocked request, response, failure, refusal, truncation, and API-key non-leak tests.
- `Sources/CommandIntelligence/KeychainCommandCredentialStore.swift` - Security.framework credential store and injectable SecItem client.
- `Tests/CommandIntelligenceTests/CommandCredentialStoreTests.swift` - In-memory and Keychain query behavior coverage.
- `Sources/GridOSKit/GridOSAppPreferences.swift` - Non-secret provider/model preference keys and normalization helpers.
- `Tests/GridOSKitTests/GridOSAppPreferencesTests.swift` - Provider/model preference storage and normalization tests.
- `Sources/GridOSApp/CommandIntelligenceSettingsView.swift` - Settings provider setup UI with Keychain save/delete.
- `Sources/GridOSApp/SettingsView.swift` - Embeds the Command Intelligence settings section.
- `gridOS.xcodeproj/project.pbxproj` - Regenerated with new source/test files.

## Decisions Made

- Kept Anthropic integration as direct REST/JSON rather than adding a Swift SDK dependency.
- Used an injectable transport and injectable SecItem client so provider and Keychain behavior are covered without live network or real Keychain access.
- Kept Settings storage to provider/model IDs only; credential material stays in Keychain.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first red test run did not include the new test file until `xcodegen generate --use-cache` regenerated `gridOS.xcodeproj`; after regeneration the intended missing-provider compile failure was confirmed and committed.
- Swift 6 actor isolation required test helpers to expose recorded requests/operations through async accessor methods before the new provider and Keychain tests could pass.

## Verification

Passed:

```bash
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
rg "AnthropicCommandProvider|POST|/v1/messages|x-api-key|anthropic-version|2023-06-01|claude-sonnet-4-6" Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg "CommandCredentialStore|KeychainCommandCredentialStore|kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly|com\\.aaldere1\\.gridos\\.command-intelligence" Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg "Command Intelligence|Provider not configured|Provider configured|Anthropic API key|Save Provider Key|Remove Provider Key" Sources/GridOSApp
! rg "apiKey.*AppStorage|UserDefaults.*api|anthropic.*AppStorage|commandIntelligence\\.apiKey|prompt.*UserDefaults|generated.*UserDefaults" Sources Tests
git diff --check
```

## Known Stubs

None. Stub-pattern scan found only intentional empty test arrays, an existing empty install-seed default, and transient empty UI state for clearing provider-key input after save/delete.

## Auth Gates

None. Automated tests use mocked provider and SecItem clients. A live Anthropic API key is optional for later manual/live provider testing.

## User Setup Required

Optional only: create an Anthropic API key in the Anthropic Console if live provider testing is desired. No key is required for the verified mocked test suite.

## Next Phase Readiness

Plan 06-05 can wire palette no-key handling and provider calls to `KeychainCommandCredentialStore`, `AnthropicCommandProvider`, and the existing approved-preview/risk contracts.

## Self-Check: PASSED

- Verified created files exist: `AnthropicCommandProvider.swift`, `KeychainCommandCredentialStore.swift`, `CommandIntelligenceSettingsView.swift`, `AnthropicCommandProviderTests.swift`, and this summary.
- Verified task commits exist: `29f04b9`, `565c46c`, `18c36a9`, `679ebf5`, and `a52cb21`.

---
*Phase: 06-llm-command-palette*
*Completed: 2026-05-20*
