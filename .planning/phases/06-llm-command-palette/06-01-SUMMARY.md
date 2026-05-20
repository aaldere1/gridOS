---
phase: 06-llm-command-palette
plan: 01
subsystem: llm-command-intelligence
tags: [swift, xcodegen, xctest, command-intelligence, provider-contracts]

requires:
  - phase: 05-aesthetic-modes
    provides: terminal-first app frame and active module structure
provides:
  - Provider-neutral CommandIntelligence model contracts
  - Approved preview payload contract for provider requests
  - Async credential-store protocol with in-memory test actor
  - Human-readable command-intelligence failure copy
  - CommandIntelligenceTests target in the gridOS scheme
affects: [06-llm-command-palette, command-intelligence, provider-adapters, command-palette-ui]

tech-stack:
  added: [XCTest target CommandIntelligenceTests]
  patterns: [approved-payload provider request boundary, async credential store abstraction, product-level failure mapping]

key-files:
  created:
    - Sources/CommandIntelligence/CommandIntelligenceModels.swift
    - Sources/CommandIntelligence/CommandContextPreview.swift
    - Sources/CommandIntelligence/CommandCredentialStore.swift
    - Sources/CommandIntelligence/LLMCommandProvider.swift
    - Sources/CommandIntelligence/CommandIntelligenceFailure.swift
    - Tests/CommandIntelligenceTests/CommandIntelligenceModelTests.swift
    - Tests/CommandIntelligenceTests/CommandCredentialStoreTests.swift
    - Tests/CommandIntelligenceTests/CommandIntelligenceFailureTests.swift
  modified:
    - project.yml
    - gridOS.xcodeproj/project.pbxproj
    - gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme
    - Sources/CommandIntelligence/CommandIntelligenceStatus.swift

key-decisions:
  - "Keep provider requests typed around ApprovedCommandContextPayload so providers cannot receive raw CommandAssistanceInput."
  - "Keep credential access async from the first contract slice so Keychain-backed storage can be added without blocking SwiftUI."
  - "Map all provider/network/parser failures to product-level copy before UI rendering."

patterns-established:
  - "Pattern 1: LLMCommandRequest carries providerID, modelID, flow, and approvedPreview only."
  - "Pattern 2: CommandCredentialStore is the only contract for provider API key read/save/delete."
  - "Pattern 3: CommandIntelligenceFailure owns title, message, recoveryAction, and requestID display fields."

requirements-completed: ["PHASE-06", "LLM-02", "LLM-03", "LLM-04", "LLM-11"]

duration: 5min
completed: 2026-05-20
---

# Phase 06 Plan 01: CommandIntelligence Contracts and Test Target Summary

**Provider-neutral command intelligence contracts with approved preview payloads, credential abstraction, failure copy, and XCTest coverage.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-20T18:55:39Z
- **Completed:** 2026-05-20T19:00:54Z
- **Tasks:** 1
- **Files modified:** 12

## Accomplishments

- Added the `CommandIntelligenceTests` target to `project.yml` and the generated `gridOS` test scheme.
- Added provider-neutral flow, provider/model ID, assistance input, generated command, provider request, and provider response contracts.
- Added `ApprovedCommandContextPayload` so provider requests are built from approved redacted preview payloads instead of raw terminal input.
- Added async `CommandCredentialStore` plus `InMemoryCommandCredentialStore` for test and future Keychain wiring.
- Added human-readable failure copy for no-key, cancellation, offline, rate-limit, provider, refusal, invalid, truncated, redaction, and unsupported-selection states.

## Task Commits

1. **RED: failing contract tests** - `c57bda8` (test)
2. **GREEN: command intelligence contracts** - `f532aaf` (feat)
3. **Coverage tighten: all failure copy states** - `2abb74e` (test)

_Note: This task was marked `tdd="true"`, so it intentionally produced multiple commits._

## Files Created/Modified

- `Sources/CommandIntelligence/CommandIntelligenceModels.swift` - Flow, provider/model ID, assistance input, generated command, and response contracts.
- `Sources/CommandIntelligence/CommandContextPreview.swift` - Approved preview payload, redacted context blocks, redaction summaries, and blocked reasons.
- `Sources/CommandIntelligence/LLMCommandProvider.swift` - Provider protocol and request contract carrying `approvedPreview`.
- `Sources/CommandIntelligence/CommandCredentialStore.swift` - Async credential-store protocol and in-memory actor.
- `Sources/CommandIntelligence/CommandIntelligenceFailure.swift` - Product-level failure copy and request ID mapping.
- `Sources/CommandIntelligence/CommandIntelligenceStatus.swift` - Module status updated from scaffolded to active contracts.
- `Tests/CommandIntelligenceTests/*.swift` - Model, credential store, and failure-copy tests.
- `project.yml`, `gridOS.xcodeproj/project.pbxproj`, `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` - XcodeGen test target and generated scheme updates.

## Decisions Made

- Provider requests accept only `ApprovedCommandContextPayload` via `approvedPreview`; raw `CommandAssistanceInput` remains outside the provider boundary.
- `LLMProviderID` and `LLMModelID` are raw string wrappers so future providers/models can be added without enum churn.
- Failure cases accept optional technical provider details for mapping, but display only stable product copy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed async XCTest assertion shape**
- **Found during:** Task 06-01-01 (GREEN verification)
- **Issue:** The RED credential-store test placed `await` calls inside XCTest autoclosures, which Swift does not allow.
- **Fix:** Awaited credential reads into local values before `XCTAssertEqual` and `XCTAssertNil`.
- **Files modified:** `Tests/CommandIntelligenceTests/CommandCredentialStoreTests.swift`
- **Verification:** `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- **Committed in:** `f532aaf`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Test-only correction needed for Swift concurrency correctness; no scope expansion.

## Issues Encountered

- RED step failed as intended with missing `InMemoryCommandCredentialStore`, `LLMProviderID`, and `CommandIntelligenceFailure` symbols.
- No authentication gates or blockers occurred.

## Verification

- `xcodegen generate --use-cache` passed.
- `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` passed.
- Required `rg` checks for flows, approved payloads, provider protocol, credential store, and failure copy passed.
- `git diff --check` passed.

## Known Stubs

None. Stub-pattern scan found only intentional optional defaults and generated Xcode empty build settings, not UI/data-source stubs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 06-02 can build redaction and context-preview construction against `ApprovedCommandContextPayload`. Plan 06-04 can add Keychain-backed storage behind `CommandCredentialStore` without changing the test actor contract.

## Self-Check: PASSED

- Created files exist on disk.
- Task commits `c57bda8`, `f532aaf`, and `2abb74e` exist in git history.

---
*Phase: 06-llm-command-palette*
*Completed: 2026-05-20*
