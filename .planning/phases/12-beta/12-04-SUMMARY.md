# Plan 12-04 Summary - First-run privacy, support, and feedback loop

**Status:** complete
**Completed:** 2026-05-21T21:11:31Z

## What changed

- Added `BetaPrivacyDisclosureView`.
- Added `betaPrivacyDisclosureAccepted` preference storage and tests.
- Wired first-run Beta privacy disclosure into `RootView`.
- Added a Settings section for Beta privacy review, support placeholder, and feedback-template reference.
- Added `.planning/phases/12-beta/BETA-FEEDBACK.md`.
- Added `.planning/phases/12-beta/KNOWN-ISSUES.md`.
- Updated `docs/security-privacy.md` and `docs/beta-distribution.md`.

## Verification

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test
rg 'betaPrivacyDisclosureAccepted|struct BetaPrivacyDisclosureView|Terminal sessions stay local to this Mac.|Command Intelligence is opt-in|API keys are stored in Keychain.|Risky commands are inserted|Diagnostics are local, sanitized, and user-reviewed.' Sources Tests docs
rg '## Report template|## Do not include|shell history|terminal transcripts' .planning/phases/12-beta/BETA-FEEDBACK.md
rg 'Beta blocker|Production blocker' .planning/phases/12-beta/KNOWN-ISSUES.md
rg 'BETA-FEEDBACK.md|No telemetry, crash upload, or automatic diagnostics upload is added in Phase 12.' docs/security-privacy.md docs/beta-distribution.md
git diff --check
```

All gates passed.

## Notes

The app still adds no telemetry, crash upload, automatic diagnostics upload, or diagnostics network path. The support address remains the placeholder `support@example.com` until the final Beta support address is chosen.
