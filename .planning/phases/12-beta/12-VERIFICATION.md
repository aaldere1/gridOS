# Phase 12: Beta Verification Report

**Direct artifact status: PASS**
**External Beta signoff: SUPERSEDED BY PRODUCTION-DIRECT 1.0.5**

Phase 12 produced a signed, notarized, stapled, locally Gatekeeper-verified
Beta DMG. This report is historical: production-direct 1.0.5 now carries the
current release posture. Separate clean-Mac Finder/Gatekeeper UAT and clean-Mac
update proof remain external validation tasks, but the public GitHub source
visibility gate is tracked by `docs/production-direct-release.md` and
`.planning/phases/14-production-release/VERSION-1.0.5.md`.

## Final commands

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
scripts/beta-notarization-preflight.sh --dry-run
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/check-beta-notary-profile.sh
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/beta-notarization-preflight.sh
GRIDOS_NOTARY_PROFILE=gridOS-beta CURRENT_PROJECT_VERSION=6 GRIDOS_BETA_OUTPUT_DIR=build/beta/ship-today scripts/build-beta.sh
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/notarize-beta-artifact.sh build/beta/ship-today/gridOS-0.1.0-6-e1c7005.dmg
scripts/verify-beta-artifact.sh build/beta/ship-today/gridOS-0.1.0-6-e1c7005.dmg
scripts/write-beta-release-manifest.sh build/beta/ship-today/gridOS-0.1.0-6-e1c7005.dmg
rg 'Phase 12: Beta Verification Report|Direct artifact status|External Beta signoff|Notarization|Clean Mac Gatekeeper UAT|Update flow|Phase 13' .planning/phases/12-beta/12-VERIFICATION.md
rg '12-VERIFICATION.md' .planning/STATE.md docs/release.md
git diff --check
```

The current notarized Beta artifact is
`build/beta/ship-today/gridOS-0.1.0-6-e1c7005.dmg`.
Its final distribution SHA-256 is
`fc4e353604f7b5195678fc86320633a4918955146db7429146133f8be495879d`.

## Must-have checklist

| Gate | Status | Evidence |
| --- | --- | --- |
| Source build/test | PASS | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` exited 0 on 2026-06-03. |
| Beta preflight | PASS | `.planning/phases/12-beta/evidence/beta-notarization-preflight.txt` records `BETA_NOTARIZATION_READY`. |
| Notary profile | PASS | `.planning/phases/12-beta/evidence/beta-notary-profile-check.txt` records `RESULT=PASS`. |
| Notarization | PASS | `.planning/phases/12-beta/evidence/beta-notarization.md` records Apple `Submission status: Accepted` and `Result: PASS`. |
| Stapling | PASS | `.planning/phases/12-beta/evidence/beta-notarization.md` records stapler staple and validate as PASS. |
| Artifact verification | PASS | `.planning/phases/12-beta/evidence/beta-artifact-verification.md` records codesign, stapler, and local Gatekeeper assessment as PASS. |
| Local notarized launch smoke | PASS | `.planning/phases/12-beta/evidence/local-notarized-launch-smoke.md` records build 6 marker launch, process launch, quit cleanup, and DMG detach cleanup as PASS. |
| Clean Mac Gatekeeper UAT | BLOCKED | `.planning/phases/12-beta/evidence/clean-mac-gatekeeper.md` records clean-Mac Finder/Gatekeeper UAT pending external clean-Mac run. |
| Update flow | BLOCKED | Manual update docs and manifest exist, but no clean-Mac Beta N to N+1 update-flow record is available. |
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

`BETA-001` is resolved. `BETA-002` and `BETA-003` remain open and block broad
external Beta signoff:

- `BETA_CLEAN_MAC_BLOCKED clean_mac_finder_gatekeeper_uat`
- `BETA_UPDATE_FLOW_BLOCKED update_flow_record_not_available_clean_mac`

## Residual risks

- Clean-Mac Gatekeeper launch is still untested on a separate clean Mac.
- Manual Beta N to Beta N+1 update is still untested on a clean-Mac environment despite signed notarized Beta artifacts existing.
- Support contact is configured as `operations@cineconcerts.com`.

## Phase 13

Do not treat broad release-candidate hardening as complete yet. First run
clean-Mac Finder/Gatekeeper UAT and produce a clean-Mac Beta N+1 update-flow
record, then update external Beta signoff from `BLOCKED` to `PASS`.
