# Phase 11 Alpha Diagnostics Policy

## Purpose

Phase 11 diagnostics exist to support internal Alpha signoff with local, sanitized, text-only evidence. The policy keeps diagnostics aligned with `docs/security-threat-model.md`, `docs/privacy-data-inventory.md`, and the Phase 11 evidence rules before any public Beta support workflow exists.

## Data allowed

Phase 11 Alpha diagnostics may include only:

- Sanitized app version/build.
- Bundle ID.
- Signing presence.
- Codesign verification result.
- Synthetic smoke marker status.
- UAT pass/fail.
- Known-issue IDs.

Allowed diagnostics must be presence/status metadata, not user content. They must not include raw command output or private local details.

## Data excluded

Phase 11 Alpha diagnostics must exclude:

- Shell history.
- Terminal transcript.
- Environment variables.
- API keys.
- Prompts.
- Generated commands.
- Raw terminal output.
- Private file paths.
- Screenshots.
- Traces.
- Keychain contents.
- Provider responses.

These exclusions apply to committed evidence, release docs, helper scripts, UAT summaries, and any manually collected notes.

## Evidence storage

Committed diagnostics and evidence live under `.planning/phases/11-alpha/` as sanitized Markdown or script source only. Build products, archives, packages, traces, screenshots, transcripts, raw terminal output, private local paths, and secret-bearing files must stay outside source control.

Generated evidence files are limited to sanitized summaries such as `alpha-artifact-manifest.md`, `alpha-artifact-verification.md`, and `alpha-uat-summary.md`. If a generated evidence file cannot be sanitized, do not commit it.

Source gate for diagnostics policy drift:

```sh
FORBIDDEN_CAPTURE='(collect|capture|captured|persist|store|stored|write|writes|upload|export|record|records).*(shell history|terminal transcript|environment variables|API keys|prompts|generated commands|raw terminal output|private file paths|screenshots|traces|keychain contents|provider responses)'
! (rg -n -i "$FORBIDDEN_CAPTURE" docs/release.md scripts \
  .planning/phases/11-alpha/evidence \
  .planning/phases/11-alpha/DIAGNOSTICS.md \
  .planning/phases/11-alpha/ALPHA-UAT.md \
  .planning/phases/11-alpha/ALPHA-FEEDBACK.md \
  .planning/phases/11-alpha/KNOWN-ISSUES.md \
  --glob '!**/evidence/alpha-artifact-manifest.md' \
  --glob '!**/evidence/alpha-artifact-verification.md' \
  --glob '!**/evidence/alpha-uat-summary.md' \
  | rg -vi 'must not|does not|do not|exclude|excluded|without|never|not capture|not stored|out of source control|forbidden_capture|data excluded|privacy boundaries')
```

The gate scans Phase 11 docs, evidence policy, and scripts while excluding generated artifacts. It passes when no unapproved forbidden data-class collection/export matches remain after policy and prohibition language is filtered.

## Manual collection

Manual Alpha notes must use `ALPHA-FEEDBACK.md`, `KNOWN-ISSUES.md`, or `ALPHA-UAT.md` and should record only pass/fail status, severity, blocker classification, known-issue IDs, sanitized reproduction summaries, and decisions.

Do not paste terminal transcripts, shell history, raw command output, provider responses, prompts, generated commands, environment variables, API keys, screenshots, traces, Keychain contents, or private file paths into manual notes.

## Future product work

Phase 11 does not add telemetry, crash reporting, automatic diagnostics upload, or support portal functionality.

Any future diagnostics export, crash reporting, telemetry, or support portal must be planned as a separate phase with an explicit data contract, opt-in controls, retention policy, redaction strategy, and security/privacy verification.
