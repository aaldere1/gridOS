---
phase: 11-alpha
plan: 01
subsystem: release
tags: [alpha, signing, evidence, release, privacy]

requires:
  - phase: 10-security-and-privacy-hardening
    provides: Security/privacy baseline, dependency review, hardened-runtime posture, and evidence privacy boundaries.
provides:
  - Sanitized signing preflight script for Phase 11 Alpha.
  - Text-only Alpha evidence policy with blocker and privacy boundaries.
  - Release documentation links for the Phase 11 Alpha evidence lane.
affects: [alpha, release, signing, evidence, phase-12-beta]

tech-stack:
  added: [bash]
  patterns: [presence-only signing evidence, sanitized text-only release evidence]

key-files:
  created:
    - scripts/alpha-signing-preflight.sh
    - .planning/phases/11-alpha/evidence/README.md
  modified:
    - docs/release.md

key-decisions:
  - "Signing readiness evidence is presence-only: missing local Apple configuration is recorded as SIGNING_BLOCKED without printing private values."
  - "Alpha evidence remains text-only and sanitized; build artifacts, traces, screenshots, terminal transcripts, raw output, prompts, generated commands, API keys, environment variables, and user-specific paths stay out of source control."
  - "High-severity terminal correctness blockers prevent Alpha completion."

patterns-established:
  - "Alpha signing preflight reports tool/settings/env/identity presence without persisting raw command output."
  - "Release docs link each Phase 11 evidence lane before future build, verification, UAT, and known-issues plans add their artifacts."

requirements-completed: ["PHASE-11"]

duration: 2 min
completed: 2026-05-21
---

# Phase 11 Plan 01: Signing Preflight and Alpha Evidence Policy Summary

**Presence-only Alpha signing preflight with sanitized evidence rules and release-doc links for Phase 11 internal builds.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-21T12:56:04Z
- **Completed:** 2026-05-21T12:58:55Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `scripts/alpha-signing-preflight.sh` with `--dry-run`, Xcode/tool checks, project signing-setting checks, signing env presence checks, and presence-only Keychain identity summary.
- Created `.planning/phases/11-alpha/evidence/README.md` with text-only evidence rules, blocker policy, artifact exclusion policy, UAT boundaries, and privacy boundaries.
- Updated `docs/release.md` with the Phase 11 Alpha lane and links to the preflight script, evidence README, future build/verify scripts, future UAT, and future known-issues workflow.

## Task Commits

Each task was committed atomically:

1. **Task 11-01-01: Add signing preflight script** - `c90f90c` (feat)
2. **Task 11-01-02: Create alpha evidence policy** - `47d110d` (docs)

## Files Created/Modified

- `scripts/alpha-signing-preflight.sh` - Dry-run-safe signing preflight that writes sanitized evidence outside dry-run mode and reports missing signing inputs as `SIGNING_BLOCKED`.
- `.planning/phases/11-alpha/evidence/README.md` - Phase 11 Alpha evidence policy with signing, artifact verification, UAT, known issues, blocker, and privacy sections.
- `docs/release.md` - Adds the Phase 11 Alpha release lane and evidence references.

## Decisions Made

- Missing `GRIDOS_DEVELOPMENT_TEAM` and `GRIDOS_SIGNING_IDENTITY` are reported as `SIGNING_BLOCKED` by name only.
- `security find-identity -v -p codesigning` is summarized as candidate identity presence only; raw certificate names, hashes, and Keychain output are not persisted.
- Alpha evidence explicitly excludes `.app`, `.xcarchive`, `.dmg`, `.zip`, `.pkg`, `.trace`, screenshots, shell history, terminal transcripts, environment variables, API keys, prompts, generated commands, raw terminal output, and user-specific paths.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The preflight dry-run correctly reported local signing configuration as blocked because `GRIDOS_DEVELOPMENT_TEAM` and `GRIDOS_SIGNING_IDENTITY` were not present.

## Authentication Gates

None.

## Known Stubs

None.

## Verification

Final plan verification passed:

```sh
bash -n scripts/alpha-signing-preflight.sh
scripts/alpha-signing-preflight.sh --dry-run
rg 'GRIDOS_ALPHA_PREFLIGHT|GRIDOS_DEVELOPMENT_TEAM|GRIDOS_SIGNING_IDENTITY|ENABLE_HARDENED_RUNTIME' scripts/alpha-signing-preflight.sh
rg 'Phase 11 alpha evidence|Signing preflight|Blocker policy|No artifacts committed' .planning/phases/11-alpha/evidence/README.md docs/release.md
git diff --check
```

Observed dry-run status: `SIGNING_BLOCKED GRIDOS_DEVELOPMENT_TEAM GRIDOS_SIGNING_IDENTITY`.

## User Setup Required

None for this plan. Future signed Alpha artifact generation requires local Apple signing configuration.

## Next Phase Readiness

Ready for Plan 11-02: internal Alpha artifact build and verification can consume the preflight script and evidence policy.

## Self-Check: PASSED

- Created files exist: `scripts/alpha-signing-preflight.sh`, `.planning/phases/11-alpha/evidence/README.md`, `.planning/phases/11-alpha/11-01-SUMMARY.md`.
- Modified file exists: `docs/release.md`.
- Task commits exist: `c90f90c`, `47d110d`.

---
*Phase: 11-alpha*
*Completed: 2026-05-21*
