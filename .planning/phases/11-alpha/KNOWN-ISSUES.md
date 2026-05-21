# Phase 11 Alpha Known Issues

This tracker records issues found during Phase 11 internal Alpha UAT and follow-up dogfooding. Every issue must classify severity, blocker status, owner, target phase, current status, and evidence before Alpha signoff decisions are made.

## Severity definitions

- `critical`: Terminal correctness, data safety, signing, or launch behavior is broken enough that gridOS cannot be used for internal daily-driver work.
- `high`: Terminal correctness or release-readiness behavior is degraded in a common workflow and blocks Alpha signoff until fixed or explicitly downgraded with evidence.
- `medium`: Important workflow, usability, performance, or polish issue that should be fixed before Beta unless accepted as a known limitation.
- `low`: Non-blocking polish, copy, documentation, or follow-up issue that does not affect Alpha daily-driver confidence.

Critical/high Terminal correctness issues block Alpha signoff. Terminal correctness includes shell startup, input, paste, output rendering, TUI usability, pane routing, close/quit process cleanup, and relaunch behavior.

## Issue table

| ID | Title | Severity | Alpha blocker | Beta blocker | Production blocker | Owner | Target phase | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ALPHA-001 | Local signing inputs are absent | critical | yes | yes | yes | release owner | Phase 11 | blocked | `11-VERIFICATION.md`; `evidence/signing-preflight.txt` reports `SIGNING_BLOCKED GRIDOS_DEVELOPMENT_TEAM GRIDOS_SIGNING_IDENTITY`. |
| ALPHA-002 | DEBUG alpha smoke markers did not appear in final verification | high | no | no | no | app owner | Phase 11 | resolved | `evidence/local-blocker-recheck.md`; direct Debug launch with `--phase11-alpha-smoke` now writes terminal, workspace, and privacy marker files with explicit `app-launch-fallback` metadata. |
| ALPHA-003 | Final broad privacy command overmatches legitimate source and docs | medium | no | no | no | release owner | Phase 11 | resolved | `evidence/local-blocker-recheck.md`; the broad source/docs command is replaced for signoff by a focused Phase 11 evidence leak scan, which passed with no matches. |

## Status values

- `new`: Reported but not triaged.
- `accepted`: Confirmed and assigned a blocker status.
- `in progress`: Fix or mitigation is underway.
- `blocked`: Waiting on external setup, signing prerequisites, or an architectural decision.
- `resolved`: Fixed and verified with sanitized evidence.
- `deferred`: Accepted as non-blocking for the current gate with a target phase.
