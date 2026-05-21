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

## Status values

- `new`: Reported but not triaged.
- `accepted`: Confirmed and assigned a blocker status.
- `in progress`: Fix or mitigation is underway.
- `blocked`: Waiting on external setup, signing prerequisites, or an architectural decision.
- `resolved`: Fixed and verified with sanitized evidence.
- `deferred`: Accepted as non-blocking for the current gate with a target phase.
