# Plan 12-01 Summary - Beta notarization preflight and evidence policy

**Status:** complete
**Completed:** 2026-05-21T21:02:16Z

## What changed

- Added `scripts/beta-notarization-preflight.sh`.
- Added `.planning/phases/12-beta/evidence/README.md`.
- Updated `docs/release.md` with the Phase 12 Beta release lane.
- Wrote sanitized blocker evidence to `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt`.

## Verification

```sh
bash -n scripts/beta-notarization-preflight.sh
scripts/beta-notarization-preflight.sh --dry-run
rg 'GRIDOS_BETA_PREFLIGHT|BETA_NOTARIZATION_BLOCKED|GRIDOS_NOTARY_PROFILE|GRIDOS_NOTARY_APPLE_ID|GRIDOS_NOTARY_KEY_ID|xcrun notarytool|xcrun stapler|ENABLE_HARDENED_RUNTIME' scripts/beta-notarization-preflight.sh
rg 'Phase 12 beta evidence|## Notarization preflight|## Gatekeeper UAT|## Blocker policy|BETA_NOTARIZATION_BLOCKED|No artifacts committed' .planning/phases/12-beta/evidence/README.md
rg '## Phase 12 beta|scripts/beta-notarization-preflight.sh|.planning/phases/12-beta/evidence/README.md' docs/release.md
git diff --check
```

All gates passed.

## Evidence

`scripts/beta-notarization-preflight.sh --dry-run` passed and reported local Xcode, notarytool, stapler, hardened runtime, and signing identity availability without requiring credentials.

The write-evidence run used present Developer ID signing inputs and recorded:

```text
BETA_NOTARIZATION_BLOCKED GRIDOS_NOTARY_PROFILE GRIDOS_NOTARY_APPLE_ID/GRIDOS_NOTARY_PASSWORD/GRIDOS_NOTARY_TEAM_ID GRIDOS_NOTARY_KEY_ID/GRIDOS_NOTARY_ISSUER_ID/GRIDOS_NOTARY_KEY_PATH
```

No notary credentials were printed or stored. This is the expected Phase 12 blocker until a notarytool Keychain profile or equivalent credential mode is provided.
