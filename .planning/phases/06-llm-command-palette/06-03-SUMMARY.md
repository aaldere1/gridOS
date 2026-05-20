---
phase: 06-llm-command-palette
plan: 03
subsystem: command-intelligence-safety
tags: [swift, xctest, command-risk, run-policy, terminal-safety]

# Dependency graph
requires:
  - phase: 06-llm-command-palette
    provides: CommandIntelligence contracts, GeneratedCommand, and provider-neutral command models from Plan 01
provides:
  - Deterministic local command risk classifier
  - Command risk levels: low, medium, high, unknown
  - Command run policies: canRun, requiresConfirmation, insertOnly
  - Fixture coverage for Phase 6 smoke commands and high-risk command classes
affects: [06-llm-command-palette, CommandPaletteView, generated-command-actions, terminal-run-gates]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Pure Swift pattern-based command risk classifier
    - Fixture-driven XCTest policy coverage
    - Local run policy as authority over provider risk labels

key-files:
  created:
    - Sources/CommandIntelligence/CommandRiskClassifier.swift
    - Tests/CommandIntelligenceTests/CommandRiskClassifierTests.swift
  modified:
    - gridOS.xcodeproj/project.pbxproj

key-decisions:
  - "Use deterministic local pattern rules as the command execution authority; provider labels remain advisory."
  - "Map high-risk and unknown commands to insertOnly so they cannot silently run."
  - "Keep the Phase 6 insert smoke command low-risk because it writes only the deterministic /tmp fixture."
  - "Treat local project mutations such as git add/git commit as medium-risk and requiring confirmation."

patterns-established:
  - "CommandRiskClassifier.classify(_:) returns CommandRiskAssessment with level, reason, and policy for every command."
  - "High-risk checks run before unknown and low-risk checks to prevent destructive commands from downgrading."
  - "Risk fixture tests assert exact command, level, reason, and policy."

requirements-completed: [PHASE-06, LLM-07, LLM-09]

# Metrics
duration: 6min
completed: 2026-05-20
---

# Phase 06 Plan 03: Risk Classifier and Run Policy Summary

**Deterministic local command-risk authority with conservative insert-only policy for high and unknown generated shell commands**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-20T19:04:56Z
- **Completed:** 2026-05-20T19:10:52Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Added `CommandRiskClassifier`, `CommandRiskAssessment`, `CommandRiskLevel`, and `CommandRunPolicy`.
- Classified destructive filesystem, credential/keychain, privilege escalation, process killing, network pipe-to-shell, package install, and remote mutation commands as high risk.
- Classified empty and hard-to-review shell constructs as unknown with insert-only review.
- Added fixture-driven XCTest coverage for low, medium, high, unknown, and the required Phase 6 smoke commands.

## Task Commits

Each TDD step was committed atomically:

1. **RED: Add failing command risk classifier fixtures** - `e8b419c` (test)
2. **GREEN: Implement command risk classifier** - `f01a23e` (feat)

_Note: This was a TDD task, so the single plan task produced separate RED and GREEN commits._

## Files Created/Modified

- `Sources/CommandIntelligence/CommandRiskClassifier.swift` - Local command risk and run-policy classifier.
- `Tests/CommandIntelligenceTests/CommandRiskClassifierTests.swift` - Fixture coverage for every required risk class and smoke command.
- `gridOS.xcodeproj/project.pbxproj` - Generated Xcode project membership for the new source and test files.

## Decisions Made

- High-risk commands return `.high` with `.insertOnly`.
- Unknown commands return `.unknown` with `.insertOnly`.
- Local project mutation commands return `.medium` with `.requiresConfirmation`.
- Safe inspection commands and the deterministic Phase 6 insert smoke command return `.low` with `.canRun`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added generated Xcode project membership**
- **Found during:** Task 06-03-01 (Add conservative risk classifier and run policy)
- **Issue:** The generated `.xcodeproj` enumerates Swift source and test files, so the new classifier test and source would not compile through the plan's `xcodebuild` command without project membership updates.
- **Fix:** Regenerated the Xcode project and staged only the 06-03 classifier source/test references while leaving parallel 06-02 files untouched.
- **Files modified:** `gridOS.xcodeproj/project.pbxproj`
- **Verification:** `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/CommandRiskClassifierTests`
- **Committed in:** `e8b419c`, `f01a23e`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for the planned XCTest gate to compile and run. No behavior outside command-risk classification was changed.

## Issues Encountered

- Parallel Plan 06-02 edits were present in the shared worktree while this plan ran. Staging was restricted to 06-03 files and generated project references required for this plan.
- `gsd-tools state advance-plan` could not parse this repo's simple state wording, so STATE.md was updated manually after `state update-progress`, metric, decision, and roadmap commands ran.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/CommandRiskClassifierTests` - passed.
- `rg "CommandRiskClassifier|networkPipeToShell|sudo|rm -rf|git push|kubectl|docker|brew install|npm install|requiresConfirmation|insertOnly|PHASE6_INSERT" Sources/CommandIntelligence Tests/CommandIntelligenceTests` - passed.
- `git diff --check` - passed.
- `rg "full shell parser|ShellParser|AST" Sources/CommandIntelligence Tests/CommandIntelligenceTests` - no matches.

## Next Phase Readiness

The local `CommandRunPolicy` contract is ready for later palette controls to consume instead of trusting provider risk labels. The classifier gives deterministic policy output for every generated command, including conservative handling for unknown shell constructs.

## Self-Check: PASSED

- Found `Sources/CommandIntelligence/CommandRiskClassifier.swift`.
- Found `Tests/CommandIntelligenceTests/CommandRiskClassifierTests.swift`.
- Found `.planning/phases/06-llm-command-palette/06-03-SUMMARY.md`.
- Found commit `e8b419c`.
- Found commit `f01a23e`.

---
*Phase: 06-llm-command-palette*
*Completed: 2026-05-20*
