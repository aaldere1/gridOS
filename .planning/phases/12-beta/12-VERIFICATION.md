# Phase 12: Beta Verification Report

**Beta status: BLOCKED**

Phase 12 is source-complete for the Beta release lane, but external Beta is not
ready. The blocker is notarization: no notary credential mode is configured, so
the repo cannot produce a notarized/stapled Beta artifact or run clean-Mac
Gatekeeper UAT.

## Final commands

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
scripts/beta-notarization-preflight.sh --dry-run
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/check-beta-notary-profile.sh
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/beta-notarization-preflight.sh --dry-run
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/build-beta.sh
rg 'Phase 12: Beta Verification Report|Beta status:|Notarization|Clean Mac Gatekeeper UAT|Update flow|Phase 13' .planning/phases/12-beta/12-VERIFICATION.md
rg '12-VERIFICATION.md' .planning/STATE.md docs/release.md
git diff --check
```

`scripts/build-beta.sh` correctly stops before archiving when notary credentials
are missing.

Notary credential setup is documented in `docs/notarization-setup.md`.
`scripts/setup-beta-notary-profile.sh` creates a Keychain profile, and
`scripts/check-beta-notary-profile.sh` verifies it with sanitized evidence.
Current profile-check evidence records
`BLOCKER=notarytool_keychain_profile_missing`.

Signing is locally available: `scripts/beta-notarization-preflight.sh --dry-run`
resolves `GRIDOS_DEVELOPMENT_TEAM_SOURCE=codesigning_identity` and
`GRIDOS_SIGNING_IDENTITY_SOURCE=keychain`.

## Must-have checklist

| Gate | Status | Evidence |
| --- | --- | --- |
| Source build/test | PASS | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` exited 0. |
| Beta preflight | BLOCKED | `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt` records signing auto-resolution and `BETA_NOTARIZATION_BLOCKED notarytool_keychain_profile_missing`. |
| Notarization | BLOCKED | `.planning/phases/12-beta/evidence/beta-notary-profile-check.txt` records `BLOCKER=notarytool_keychain_profile_missing`. |
| Stapling | BLOCKED | No accepted notarization ticket exists. |
| Artifact verification | BLOCKED | No notarized Beta artifact exists for `scripts/verify-beta-artifact.sh`. |
| Clean Mac Gatekeeper UAT | BLOCKED | `.planning/phases/12-beta/evidence/clean-mac-gatekeeper.md` records `BETA_CLEAN_MAC_BLOCKED notarized_beta_artifact`. |
| Update flow | BLOCKED | Manual update docs and manifest exist, but no notarized Beta N/N+1 artifact pair exists. |
| First-run privacy | PASS | `BetaPrivacyDisclosureView`, `RootView`, `SettingsView`, and `GridOSAppPreferencesTests` passed the unsigned test gate. |
| Feedback loop | PASS | `.planning/phases/12-beta/BETA-FEEDBACK.md` and `.planning/phases/12-beta/KNOWN-ISSUES.md` exist. |
| Privacy boundaries | PASS | Phase 12 docs state no telemetry, crash upload, or automatic diagnostics upload. |

## Evidence files

- `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt`
- `.planning/phases/12-beta/evidence/beta-notary-profile-check.txt`
- `.planning/phases/12-beta/evidence/clean-mac-gatekeeper.md`
- `.planning/phases/12-beta/BETA-UAT.md`
- `.planning/phases/12-beta/BETA-FEEDBACK.md`
- `.planning/phases/12-beta/KNOWN-ISSUES.md`
- `.planning/phases/12-beta/beta-release-manifest.json`
- `docs/notarization-setup.md`

## Known issues

`BETA-001` is open and blocks Beta and Production:

- `BETA_NOTARIZATION_BLOCKED`
- Missing `GRIDOS_NOTARY_PROFILE` or an equivalent Apple ID/API key credential mode.

## Residual risks

- Clean-Mac Gatekeeper launch is untested until a notarized artifact exists.
- Manual Beta N to Beta N+1 update is untested until two notarized Beta artifacts exist.
- The support address remains `support@example.com` until the final Beta support channel is chosen.

## Phase 13

Do not start Phase 13 release-candidate work as complete release hardening yet.
First provide a notary credential mode, rerun the Beta build/notarize/verify
lane, complete clean-Mac Gatekeeper UAT, and update this report from `BLOCKED`
to `PASS`.
