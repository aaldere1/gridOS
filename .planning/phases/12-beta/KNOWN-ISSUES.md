# Phase 12 Beta Known Issues

This tracker records issues found during external Beta installability, update,
Gatekeeper, first-run privacy, feedback, diagnostics, and terminal correctness
testing.

## Severity definitions

- `critical`: Install, launch, terminal correctness, data safety, signing, notarization, Gatekeeper, or update behavior is broken enough that Beta cannot proceed.
- `high`: A common Beta workflow is degraded and blocks Beta signoff until fixed or explicitly downgraded with evidence.
- `medium`: Important workflow, usability, performance, support, or polish issue that should be fixed before the release candidate unless accepted as a known limitation.
- `low`: Non-blocking polish, copy, documentation, or follow-up issue that does not affect Beta confidence.

Critical/high install, launch, terminal correctness, notarization, Gatekeeper,
update, or data-safety issues block Beta signoff.

## Issue table

| ID | Title | Severity | Beta blocker | Production blocker | Owner | Target phase | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BETA-001 | Notary credential mode is not configured | critical | yes | yes | release owner | Phase 12 | blocked | `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt` records `BETA_NOTARIZATION_BLOCKED`. |

## Status values

- `new`: Reported but not triaged.
- `accepted`: Confirmed and assigned a blocker status.
- `in progress`: Fix or mitigation is underway.
- `blocked`: Waiting on external setup, notary credentials, clean-Mac access, or an architectural decision.
- `resolved`: Fixed and verified with sanitized evidence.
- `deferred`: Accepted as non-blocking for the current gate with a target phase.
