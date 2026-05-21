---
phase: 11-alpha
plan: 04
subsystem: release-docs
tags: [alpha, diagnostics, known-issues, uat, privacy]

requires:
  - phase: 11-alpha
    provides: Alpha signing preflight, artifact verification, DEBUG smoke, and daily-driver UAT checklist
provides:
  - Alpha known-issues tracker with Alpha/Beta/Production blocker semantics
  - Alpha feedback intake log for dogfooding reports
  - Sanitized local diagnostics policy with explicit excluded data classes
  - Release and evidence links for issue triage and diagnostics policy
affects: [11-alpha-final-verification, phase-12-beta, release-process, privacy-boundaries]

tech-stack:
  added: []
  patterns:
    - Sanitized Markdown evidence and diagnostics policies
    - Source gates that exclude generated evidence artifacts

key-files:
  created:
    - .planning/phases/11-alpha/KNOWN-ISSUES.md
    - .planning/phases/11-alpha/ALPHA-FEEDBACK.md
    - .planning/phases/11-alpha/DIAGNOSTICS.md
  modified:
    - .planning/phases/11-alpha/ALPHA-UAT.md
    - .planning/phases/11-alpha/evidence/README.md
    - docs/release.md

key-decisions:
  - "Critical/high terminal correctness issues block Alpha signoff through the known-issues triage loop."
  - "Phase 11 diagnostics remain local and sanitized; telemetry, crash reporting, automatic diagnostics upload, and support portal functionality are deferred."
  - "Diagnostics source gating scans Phase 11 docs, evidence policy, and scripts while excluding generated artifacts."

patterns-established:
  - "Alpha feedback is captured first in ALPHA-FEEDBACK.md, then promoted to KNOWN-ISSUES.md when confirmed."
  - "Diagnostics evidence allows only sanitized app/build/signing/smoke/UAT/status metadata."

requirements-completed: [PHASE-11]

duration: 4 min
completed: 2026-05-21
---

# Phase 11 Plan 04: Feedback, Known Issues, And Diagnostics Policy Summary

**Alpha dogfooding now has a durable known-issues loop and a local-only diagnostics policy that excludes terminal, secret, prompt, and provider data.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-21T13:16:09Z
- **Completed:** 2026-05-21T13:19:48Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `KNOWN-ISSUES.md` with severity definitions, blocker status columns, status values, and the Alpha terminal-correctness signoff rule.
- Added `ALPHA-FEEDBACK.md` with a sanitized dogfooding intake template and decision states.
- Added `DIAGNOSTICS.md` with allowed metadata, excluded data classes, evidence storage, manual collection, future product-work boundaries, and a source gate.
- Linked the feedback, known-issues, and diagnostics policies from UAT, evidence, and release documentation.

## Task Commits

Each task was committed atomically:

1. **Task 11-04-01: Create known-issues and feedback trackers** - `a426256` (docs)
2. **Task 11-04-02: Document sanitized diagnostics policy** - `5c9763d` (docs)

## Files Created/Modified

- `.planning/phases/11-alpha/KNOWN-ISSUES.md` - Alpha known-issues tracker with severity and blocker semantics.
- `.planning/phases/11-alpha/ALPHA-FEEDBACK.md` - Sanitized Alpha feedback intake log.
- `.planning/phases/11-alpha/DIAGNOSTICS.md` - Local sanitized diagnostics policy and source gate.
- `.planning/phases/11-alpha/ALPHA-UAT.md` - Links UAT findings to feedback and known-issues docs.
- `.planning/phases/11-alpha/evidence/README.md` - Links the diagnostics policy from the evidence policy.
- `docs/release.md` - Adds Alpha triage and diagnostics policy references.

## Verification

Passed:

```sh
rg 'Phase 11 Alpha Known Issues|Alpha blocker|Beta blocker|Production blocker|Terminal correctness' .planning/phases/11-alpha/KNOWN-ISSUES.md
rg 'Phase 11 Alpha Feedback|privacy notes|linked known issue' .planning/phases/11-alpha/ALPHA-FEEDBACK.md
rg 'Phase 11 Alpha Diagnostics Policy|Data allowed|Data excluded|shell history|terminal transcript|environment variables|API keys|prompts|generated commands' .planning/phases/11-alpha/DIAGNOSTICS.md
rg 'KNOWN-ISSUES.md|ALPHA-FEEDBACK.md|DIAGNOSTICS.md|critical/high terminal correctness issues block Alpha signoff' .planning/phases/11-alpha docs/release.md
git diff --check
```

The diagnostics source-gate snippet in `DIAGNOSTICS.md` was also run after narrowing it to the live Phase 11 docs/evidence/scripts scope, and it passed.

## Decisions Made

- Critical/high terminal correctness issues block Alpha signoff through `KNOWN-ISSUES.md`.
- Phase 11 diagnostics remain local and sanitized; telemetry, crash reporting, automatic diagnostics upload, and support portal functionality are future product work.
- Source gating for diagnostics drift excludes generated evidence artifacts so committed summaries are not re-scanned as source.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first diagnostics source-gate draft was too broad and matched older planning/security policy text. It was narrowed before commit to the live Phase 11 release docs, evidence policy, tracker docs, and scripts, then verified.

## Known Stubs

None. The empty known-issues table and feedback intake fields are intentional tracker templates required by the plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 11 Plan 05 can use `KNOWN-ISSUES.md`, `ALPHA-FEEDBACK.md`, `DIAGNOSTICS.md`, `ALPHA-UAT.md`, and the evidence README as the final Alpha verification inputs.

## Self-Check: PASSED

- Created files exist: `KNOWN-ISSUES.md`, `ALPHA-FEEDBACK.md`, `DIAGNOSTICS.md`, and `11-04-SUMMARY.md`.
- Task commits exist: `a426256` and `5c9763d`.

---
*Phase: 11-alpha*
*Completed: 2026-05-21*
