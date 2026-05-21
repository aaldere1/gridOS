# Plan 12-03 Summary - Beta update channel and distribution manifest

**Status:** complete
**Completed:** 2026-05-21T21:08:43Z

## What changed

- Added `scripts/write-beta-release-manifest.sh`.
- Added placeholder `.planning/phases/12-beta/beta-release-manifest.json`.
- Added `docs/beta-distribution.md`.
- Added `.planning/phases/12-beta/BETA-UAT.md`.
- Updated `docs/release.md` with distribution, UAT, and manifest links.

## Verification

```sh
bash -n scripts/write-beta-release-manifest.sh
rg 'beta-release-manifest.json|shasum -a 256|CFBundleShortVersionString|notarization' scripts/write-beta-release-manifest.sh
rg '"channel": "beta"|pending-local-artifact' .planning/phases/12-beta/beta-release-manifest.json
rg '# Beta distribution|## Update from Beta N to Beta N\+1|## Rollback|manual Beta update flow' docs/beta-distribution.md
rg 'Clean Mac Gatekeeper UAT|Update from Beta N to Beta N\+1|spctl --assess' .planning/phases/12-beta/BETA-UAT.md
rg 'docs/beta-distribution.md|beta-release-manifest.json|BETA-UAT.md' docs/release.md
git diff --check
```

All gates passed.

## Notes

The manifest is intentionally a placeholder until a notarized local artifact exists. It contains no absolute local paths, credentials, terminal transcripts, or raw logs.
