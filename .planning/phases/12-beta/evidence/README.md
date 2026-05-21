# Phase 12 beta evidence

This directory stores sanitized text evidence for the external Beta release lane.
Build products and private diagnostics stay out of source control.

## Notarization preflight

`scripts/beta-notarization-preflight.sh` records local tool presence, hardened-runtime
settings, signing input presence, and notary credential mode presence without
printing private values.

Missing signing or notary inputs are recorded as `BETA_NOTARIZATION_BLOCKED`
with missing input names only.

## Artifact build

Beta build products must be written only to ignored local output directories,
normally `build/beta`.

Committed evidence may include artifact basenames, version/build, source commit,
checksums, code-signing status, hardened-runtime status, and command names.
Committed evidence must not include raw build logs or private local paths.

## Notarization and stapling

Beta notarization evidence should record the submitted artifact basename,
submission status, notary status, stapling status, validation command names, and
sanitized failure categories.

Notary credentials, app-specific passwords, API keys, private keys, profile
contents, and keychain item contents must never be committed.

## Gatekeeper UAT

Clean-Mac Gatekeeper UAT evidence must record a quarantined artifact install and
Finder launch result, plus `xcrun stapler validate` and `spctl --assess`
outcomes when applicable.

The evidence should use `PASS` or `BLOCKED`. If blocked by environment, record
`BETA_CLEAN_MAC_BLOCKED` with missing prerequisite names only.

## Update flow

Phase 12 uses a manual Beta update flow backed by
`.planning/phases/12-beta/beta-release-manifest.json`.

Evidence should record version/build before and after update, checksum
verification, replacement/install result, launch result, and rollback readiness.

## Feedback and diagnostics

Beta feedback evidence is text-only and sanitized. Diagnostics remain local and
user-reviewed. Phase 12 does not add telemetry, crash upload, or automatic
diagnostics upload.

## Blocker policy

Beta cannot be marked complete unless all of these are true:

- Developer ID signed artifact evidence exists.
- Notarization evidence is accepted or a user-approved blocker is recorded.
- Stapling or ticket validation evidence exists for the chosen artifact type.
- Clean-Mac Gatekeeper UAT is `PASS`.
- Update flow evidence is `PASS`.
- First-run privacy and feedback flow evidence is `PASS`.
- No critical or high-severity Beta blocker is open.

## Privacy boundaries

No artifacts committed: .app, .xcarchive, .dmg, .zip, .pkg, .trace, and screenshots stay out of source control.

Do not commit shell history, terminal transcripts, raw command output,
environment variables, API keys, prompts, generated commands, provider
responses, screenshots, traces, private file paths, private keys, notary
credentials, keychain contents, or raw logs.
