# Phase 12: Beta - Research

## Research Goal

Answer: what do we need to know to plan external Beta installability and feedback well?

Phase 12 is the bridge from signed internal Alpha to external Beta. The work should preserve Alpha terminal correctness and privacy guarantees while adding notarization, stapling or ticket validation, clean-Mac Gatekeeper proof, release metadata, update proof, first-run privacy copy, and a support/feedback loop.

## Current App Baseline

- Phase 11 Alpha passed with signed artifact `build/alpha/gridOS-0.1.0-1-69e8518.zip`.
- `project.yml` already sets `ENABLE_HARDENED_RUNTIME: YES` on the app target.
- `scripts/build-alpha.sh` can archive a signed Release app when `GRIDOS_DEVELOPMENT_TEAM` and `GRIDOS_SIGNING_IDENTITY` are present.
- `scripts/verify-alpha-artifact.sh` verifies code signature, app metadata, and checksums, but records `Notarization: deferred to Phase 12`.
- Alpha diagnostics and UAT evidence are sanitized text only.
- There is no Beta notary preflight, notarization submission script, Gatekeeper UAT checklist, Beta release manifest, public feedback/support template, or first-run Beta privacy surface yet.

## Apple Distribution Findings

Official Apple guidance supports these planning assumptions:

- Developer ID is the direct-distribution signing path for apps distributed outside the Mac App Store.
- Apple recommends notarization for Developer ID-signed software so Gatekeeper can tell users the software was checked by Apple.
- `notarytool` is the current command-line submission path; `altool` and Xcode 13-or-earlier upload paths are obsolete.
- Apple states notarization requires the Hardened Runtime for macOS apps.
- `xcrun stapler` supports stapling tickets to app bundles, UDIF disk images, and signed flat installer packages. Local tool help confirms this on the current machine.
- ZIP uploads can be accepted by the notary service, but ZIP is not itself a stapled distributable. For ZIP distribution, the extracted app bundle can be stapled/validated or Gatekeeper can find the online ticket. DMG distribution gives a better Beta verification target because a stapled DMG is closer to a normal external download flow.

## Recommended Beta Distribution Strategy

Use a credential-aware, privacy-safe lane:

1. Keep unsigned `xcodebuild ... CODE_SIGNING_ALLOWED=NO test` as the always-runnable baseline.
2. Add Beta preflight that checks tools, signing identity, hardened runtime, notary credential input shape, and artifact output path policy without printing secrets.
3. Build a signed Release archive under `build/beta`.
4. Package as a DMG for the default external Beta artifact, with ZIP still supported for local archive continuity.
5. Submit the DMG or ZIP to Apple notarization with `xcrun notarytool submit --wait`.
6. Staple the DMG or app bundle where supported.
7. Verify `codesign`, `stapler validate`, `spctl --assess`, Info.plist version/build, and SHA-256.
8. Produce sanitized evidence and a release manifest.

## Notary Credential Inputs

Support two credential modes without storing secrets in the repo:

- Preferred: `GRIDOS_NOTARY_PROFILE` naming a notarytool Keychain profile created outside the repo.
- Fallback: documented Apple ID/App Specific Password or App Store Connect API key inputs, but do not commit values or echo them in output.

Preflight should record only:

- `GRIDOS_NOTARY_PROFILE=present|missing`
- `GRIDOS_NOTARY_APPLE_ID=present|missing_optional`
- `GRIDOS_NOTARY_PASSWORD=present|missing_optional`
- `GRIDOS_NOTARY_TEAM_ID=present|missing_optional`
- `GRIDOS_NOTARY_KEY_ID=present|missing_optional`
- `GRIDOS_NOTARY_ISSUER_ID=present|missing_optional`
- `GRIDOS_NOTARY_KEY_PATH=present|missing_optional`

## Update Flow Strategy

For Phase 12, a manual Beta update mechanism is acceptable if it is explicit and tested:

- `docs/beta-distribution.md` describes download, checksum verification, install, launch, update, rollback, and feedback.
- `.planning/phases/12-beta/beta-release-manifest.json` records the current Beta artifact metadata.
- `.planning/phases/12-beta/BETA-UAT.md` includes a Beta N to Beta N+1 update row.
- `scripts/write-beta-release-manifest.sh` can create or refresh sanitized manifest metadata from a verified local artifact.

This keeps a clean migration path to Sparkle or another automatic updater later. If Sparkle is introduced in Phase 12, it must be treated as a separate signed-update project with appcast signing keys, hosting, downgrade/rollback policy, and additional Gatekeeper UAT.

## First-Run And Feedback Strategy

Beta users need product-visible trust cues:

- A first-run privacy disclosure that explains local terminal sessions, local preferences, Keychain-only API keys, opt-in provider requests, preview-before-send, insert-first risky commands, opt-in notifications, and metadata-only indexing.
- A support/feedback surface with support email/site placeholder and a template for sanitized diagnostics.
- No telemetry, crash upload, command transcript upload, shell history upload, screenshot collection, environment dump, or automatic diagnostics upload.

## Validation Architecture

Use Xcode/XCTest, shell release gates, and manual clean-Mac UAT:

- Fast source gate: `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test`
- Full source gate: `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- Beta preflight: `scripts/beta-notarization-preflight.sh --dry-run`
- Beta build: `GRIDOS_DEVELOPMENT_TEAM=... GRIDOS_SIGNING_IDENTITY=... scripts/build-beta.sh`
- Notarization: `GRIDOS_NOTARY_PROFILE=... scripts/notarize-beta-artifact.sh build/beta/gridOS-...dmg`
- Artifact verification: `scripts/verify-beta-artifact.sh build/beta/gridOS-...dmg`
- Manifest generation: `scripts/write-beta-release-manifest.sh build/beta/gridOS-...dmg`
- Privacy scan: `! rg 'BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]|xox[baprs]-|ghp_[A-Za-z0-9]|-----BEGIN|HOME=|SHELL=|PATH=|terminalTranscript|shellHistory|environmentVariables' .planning/phases/12-beta/evidence docs/beta-distribution.md`

## Planning Implications

- Plans should separate preflight/policy, build/notarize/verify scripts, update/distribution manifest, first-run/support/feedback UI, and final clean-Mac UAT signoff.
- Credential-dependent work must fail as `BETA_NOTARIZATION_BLOCKED`, not as vague build failure.
- The Beta signoff report must not claim 1.0 readiness.
- Clean-Mac Gatekeeper proof is manual and must be recorded as explicit UAT.

## Open Risks

- Notary credentials may be absent locally.
- The signed Alpha artifact may use a source commit different from HEAD; Beta should rebuild from clean current source.
- DMG packaging can expose signing/stapling differences that a ZIP does not.
- Clean-Mac proof requires a separate machine or user profile with Gatekeeper enabled.
- Public hosting and automatic update decisions may become blockers if the user wants a wider Beta than manual distribution.
