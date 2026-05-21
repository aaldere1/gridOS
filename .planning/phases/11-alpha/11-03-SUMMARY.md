---
phase: 11-alpha
plan: 03
subsystem: release
tags: [alpha, uat, terminal-correctness, debug-smoke, privacy]

requires:
  - phase: 11-alpha-02
    provides: Internal alpha artifact build and artifact verification scripts
  - phase: 10-security-and-privacy-hardening
    provides: Privacy, persistence, notification, Spotlight, and Command Intelligence guardrails
provides:
  - DEBUG Phase 11 alpha smoke markers for terminal, workspace, and privacy readiness
  - Daily-driver Alpha UAT checklist for terminal correctness and macOS integrations
  - Sanitized noninteractive Alpha UAT helper script
  - Release documentation for alpha smoke and UAT commands
affects: [11-alpha, release, phase-12-beta]

tech-stack:
  added: [swift-debug-smoke, bash-uat-helper]
  patterns: [sanitized-smoke-markers, terminal-workspace-controller-smoke, privacy-safe-uat-evidence]

key-files:
  created:
    - Sources/GridOSApp/Phase11AlphaSmokeCoordinator.swift
    - .planning/phases/11-alpha/ALPHA-UAT.md
    - .planning/phases/11-alpha/run-alpha-uat.sh
  modified:
    - Sources/GridOSApp/RootView.swift
    - docs/release.md
    - gridOS.xcodeproj/project.pbxproj

key-decisions:
  - "DEBUG alpha smoke uses deterministic /tmp marker files and never records terminal transcripts, selected output, prompts, generated commands, environment variables, or shell history."
  - "Daily-driver UAT separates manual interactive terminal checks from a sanitized noninteractive command-availability helper."
  - "The generated Xcode project was regenerated from project.yml so the new DEBUG coordinator is part of the GridOSApp target."

patterns-established:
  - "Phase smoke coordinators stay DEBUG-gated and route terminal/workspace checks through TerminalWorkspaceController."
  - "Alpha UAT evidence records command names, timestamps, source commit, and PASS/FAIL only."

requirements-completed: ["PHASE-11"]

duration: 3 min
completed: 2026-05-21
---

# Phase 11 Plan 03: Daily-driver Terminal Correctness UAT Summary

**Alpha daily-driver validation now has DEBUG terminal/workspace/privacy smoke markers plus a manual UAT checklist and sanitized helper evidence path.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-21T13:08:59Z
- **Completed:** 2026-05-21T13:12:21Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `Phase11AlphaSmokeCoordinator` with `--phase11-alpha-smoke` and deterministic `/tmp` marker files for terminal, workspace, and privacy readiness.
- Wired the DEBUG alpha smoke from `RootView` using the same startup pattern as prior phase smoke coordinators.
- Created `.planning/phases/11-alpha/ALPHA-UAT.md` covering shell launch, input, paste, select/copy, clear/reset, splits, close, restore, `vim`, `less`, `top`, `tmux`, `ssh`, fast output, Command Intelligence, notifications, menu bar, and Spotlight privacy.
- Added executable `.planning/phases/11-alpha/run-alpha-uat.sh` to write sanitized command-availability evidence to `.planning/phases/11-alpha/evidence/alpha-uat-summary.md`.
- Updated `docs/release.md` with the Debug alpha smoke command, marker readback, UAT helper, and manual checklist path.

## Task Commits

Each task was committed atomically:

1. **Task 11-03-01: Add DEBUG alpha smoke coordinator** - `832b812` (feat)
2. **Task 11-03-02: Create daily-driver Alpha UAT checklist** - `59e6fb6` (docs)

## Files Created/Modified

- `Sources/GridOSApp/Phase11AlphaSmokeCoordinator.swift` - DEBUG alpha smoke coordinator for terminal/workspace/privacy readiness markers.
- `Sources/GridOSApp/RootView.swift` - Starts the Phase 11 alpha smoke coordinator from the DEBUG startup path.
- `gridOS.xcodeproj/project.pbxproj` - Generated project membership for the new coordinator.
- `.planning/phases/11-alpha/ALPHA-UAT.md` - Manual daily-driver Alpha UAT checklist and signoff log.
- `.planning/phases/11-alpha/run-alpha-uat.sh` - Executable sanitized UAT helper for command availability and fast output checks.
- `docs/release.md` - Alpha smoke and UAT operating guidance.

## Verification

Final plan verification passed:

```sh
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test
bash -n .planning/phases/11-alpha/run-alpha-uat.sh
rg 'phase11-alpha-smoke|PHASE11_ALPHA_TERMINAL_READY|PHASE11_ALPHA_PRIVACY_READY' Sources/GridOSApp docs/release.md
rg 'Phase 11 Alpha UAT|Terminal correctness|vim --version|less --version|top -l 1 -n 0|tmux -V|ssh -V|Command Intelligence' .planning/phases/11-alpha/ALPHA-UAT.md .planning/phases/11-alpha/run-alpha-uat.sh
git diff --check
```

## Decisions Made

- The alpha smoke writes terminal and workspace markers through local terminal/workspace controller behavior, while the privacy marker remains a fixed direct marker with no private data.
- The UAT helper suppresses command output and writes only command names, PASS/FAIL status, timestamp, and source commit to committed evidence paths.
- Manual interactive UAT remains in the checklist; this plan does not claim signed-build dogfood signoff.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated Xcode project membership**
- **Found during:** Task 11-03-01 (Add DEBUG alpha smoke coordinator)
- **Issue:** A new Swift source file must be present in the generated Xcode project for `xcodebuild test` to compile the app target.
- **Fix:** Ran `xcodegen generate --use-cache` after adding `Phase11AlphaSmokeCoordinator.swift` and committed the resulting `gridOS.xcodeproj/project.pbxproj` change.
- **Files modified:** `gridOS.xcodeproj/project.pbxproj`
- **Verification:** `xcodebuild ... test`, required `rg` gates, and `git diff --check` passed.
- **Committed in:** `832b812`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required to keep tracked generated project output in sync with source files. No behavior outside the planned smoke/UAT lane was added.

## Issues Encountered

None.

## Authentication Gates

None.

## Known Stubs

None. Stub-pattern scanning matched only a Bash accumulator initialized to an empty string and generated Xcode signing placeholders already used by the project; neither is a UI/data-source stub.

## User Setup Required

None - no new external service configuration was added. Running the signed Alpha build still depends on the local Apple signing prerequisites documented by Phase 11 Plans 01 and 02.

## Next Phase Readiness

Ready for Phase 11 Plan 04 feedback, known-issues, and diagnostics policy. Daily-driver terminal UAT now has a checklist and a sanitized helper, while signed-build and manual dogfood signoff remain part of later Alpha verification.

## Self-Check: PASSED

- Found `Sources/GridOSApp/Phase11AlphaSmokeCoordinator.swift`.
- Found `.planning/phases/11-alpha/ALPHA-UAT.md`.
- Found `.planning/phases/11-alpha/run-alpha-uat.sh`.
- Found `.planning/phases/11-alpha/11-03-SUMMARY.md`.
- Found task commit `832b812`.
- Found task commit `59e6fb6`.

---
*Phase: 11-alpha*
*Completed: 2026-05-21*
