# Plan 12-02 Summary - Notarized Beta artifact build, staple, and verification

**Status:** complete
**Completed:** 2026-05-21T21:06:27Z

## What changed

- Added `scripts/build-beta.sh`.
- Added `scripts/notarize-beta-artifact.sh`.
- Added `scripts/verify-beta-artifact.sh`.
- Updated `.planning/phases/12-beta/evidence/README.md` with build, notarization, stapling, and verification commands.
- Updated `docs/release.md` with Beta build/notarize/verify usage.

## Verification

```sh
bash -n scripts/build-beta.sh
bash -n scripts/notarize-beta-artifact.sh
bash -n scripts/verify-beta-artifact.sh
rg 'GRIDOS_BETA_OUTPUT_DIR|hdiutil create|beta-artifact-manifest.md' scripts/build-beta.sh docs/release.md .planning/phases/12-beta/evidence/README.md
rg 'notarytool submit|--wait|stapler staple|stapler validate|codesign --verify --deep --strict --verbose=2|spctl --assess|BETA_ARTIFACT_VERIFICATION' scripts/notarize-beta-artifact.sh scripts/verify-beta-artifact.sh docs/release.md .planning/phases/12-beta/evidence/README.md
git diff --check
```

All source gates passed.

## Credential-dependent status

`scripts/build-beta.sh` was invoked with present Developer ID signing inputs and stopped before archiving because no notary credential mode is configured. This is expected until one of these inputs is provided outside the repo:

```text
GRIDOS_NOTARY_PROFILE
GRIDOS_NOTARY_APPLE_ID/GRIDOS_NOTARY_PASSWORD/GRIDOS_NOTARY_TEAM_ID
GRIDOS_NOTARY_KEY_ID/GRIDOS_NOTARY_ISSUER_ID/GRIDOS_NOTARY_KEY_PATH
```

The current blocker evidence is `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt`.
