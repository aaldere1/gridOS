# Phase 12: Beta Verification Report

**Beta status: BLOCKED**

Phase 12 produced a signed, notarized, stapled, locally Gatekeeper-verified
Beta DMG. External Beta signoff remains blocked by clean-Mac Finder/Gatekeeper
UAT and a Beta N to Beta N+1 update-flow proof.

## Final commands

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
scripts/beta-notarization-preflight.sh --dry-run
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/check-beta-notary-profile.sh
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/beta-notarization-preflight.sh --dry-run
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/build-beta.sh
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/notarize-beta-artifact.sh build/beta/gridOS-0.1.0-1-20b35f0.dmg
scripts/verify-beta-artifact.sh build/beta/gridOS-0.1.0-1-20b35f0.dmg
scripts/write-beta-release-manifest.sh build/beta/gridOS-0.1.0-1-20b35f0.dmg
rg 'Phase 12: Beta Verification Report|Beta status:|Notarization|Clean Mac Gatekeeper UAT|Update flow|Phase 13' .planning/phases/12-beta/12-VERIFICATION.md
rg '12-VERIFICATION.md' .planning/STATE.md docs/release.md
git diff --check
```

The notarized Beta artifact is `build/beta/gridOS-0.1.0-1-20b35f0.dmg`.
Its final distribution SHA-256 is
`253467b61b934d633a4d3f703532e7fdf1f59a4ff2636df5fc79289384b7967a`.

## Must-have checklist

| Gate | Status | Evidence |
| --- | --- | --- |
| Source build/test | PASS | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` exited 0. |
| Beta preflight | PASS | `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt` records `BETA_NOTARIZATION_READY`. |
| Notary profile | PASS | `.planning/phases/12-beta/evidence/beta-notary-profile-check.txt` records `RESULT=PASS`. |
| Notarization | PASS | `.planning/phases/12-beta/evidence/beta-notarization.md` records Apple `Submission status: Accepted` and `Result: PASS`. |
| Stapling | PASS | `.planning/phases/12-beta/evidence/beta-notarization.md` records stapler staple and validate as PASS. |
| Artifact verification | PASS | `.planning/phases/12-beta/evidence/beta-artifact-verification.md` records codesign, stapler, and local Gatekeeper assessment as PASS. |
| Local notarized launch smoke | PASS | `.planning/phases/12-beta/evidence/local-notarized-launch-smoke.md` records a sanitized launch marker, process launch, quit cleanup, and DMG detach cleanup as PASS. |
| Clean Mac Gatekeeper UAT | BLOCKED | `.planning/phases/12-beta/evidence/clean-mac-gatekeeper.md` records clean-Mac Finder/Gatekeeper UAT pending external clean-Mac run. |
| Update flow | BLOCKED | Manual update docs and manifest exist, but no notarized Beta N/N+1 artifact pair exists. |
| First-run privacy | PASS | `BetaPrivacyDisclosureView`, `RootView`, `SettingsView`, and `GridOSAppPreferencesTests` passed the unsigned test gate. |
| Feedback loop | PASS | `.planning/phases/12-beta/BETA-FEEDBACK.md` and `.planning/phases/12-beta/KNOWN-ISSUES.md` exist. |
| Privacy boundaries | PASS | Phase 12 docs state no telemetry, crash upload, or automatic diagnostics upload. |

## Evidence files

- `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt`
- `.planning/phases/12-beta/evidence/beta-notary-profile-check.txt`
- `.planning/phases/12-beta/evidence/beta-artifact-manifest.md`
- `.planning/phases/12-beta/evidence/beta-notarization.md`
- `.planning/phases/12-beta/evidence/beta-artifact-verification.md`
- `.planning/phases/12-beta/evidence/local-notarized-launch-smoke.md`
- `.planning/phases/12-beta/evidence/clean-mac-gatekeeper.md`
- `.planning/phases/12-beta/BETA-UAT.md`
- `.planning/phases/12-beta/BETA-FEEDBACK.md`
- `.planning/phases/12-beta/KNOWN-ISSUES.md`
- `.planning/phases/12-beta/beta-release-manifest.json`
- `docs/notarization-setup.md`

## Known issues

`BETA-001` is resolved. `BETA-002` and `BETA-003` remain open and block Beta:

- `BETA_CLEAN_MAC_BLOCKED clean_mac_finder_gatekeeper_uat`
- `BETA_UPDATE_FLOW_BLOCKED notarized_beta_n_plus_one_artifact`

## Residual risks

- Clean-Mac Gatekeeper launch is still untested on a separate clean Mac.
- Manual Beta N to Beta N+1 update is still untested until two notarized Beta artifacts exist.
- The support address remains `support@example.com` until the final Beta support channel is chosen.

## Phase 13

Do not start Phase 13 release-candidate work as complete release hardening yet.
First run clean-Mac Finder/Gatekeeper UAT and produce a notarized Beta N+1
artifact pair for update-flow proof, then update this report from `BLOCKED` to
`PASS`.
