---
phase: 12
slug: beta
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
---

# Phase 12 - Validation Strategy

> Per-phase validation contract for Beta planning and execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Xcode/XCTest plus shell release gates |
| Config file | `project.yml` |
| Quick run command | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test` |
| Full suite command | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| Credential-dependent gates | `scripts/build-beta.sh`, `scripts/notarize-beta-artifact.sh`, `scripts/verify-beta-artifact.sh` |
| Estimated runtime | 30 seconds for source gates; notarization and clean-Mac UAT are manual/long-running |

## Sampling Rate

- After every task commit: run the task-specific quick gate.
- After every plan wave: run the full source gate or the closest script/source gate if credentials are unavailable.
- Before final Phase 12 verification: source gate, Beta preflight, artifact verification or explicit notary blocker, manifest check, clean-Mac UAT evidence, focused privacy scan, and docs scan must be green.
- Max feedback latency: 30 seconds for local source/doc gates; notarization and clean-Mac UAT may take longer and must be recorded as manual evidence.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | Beta notary preflight | shell/source | `bash -n scripts/beta-notarization-preflight.sh && scripts/beta-notarization-preflight.sh --dry-run && rg 'GRIDOS_BETA_PREFLIGHT|BETA_NOTARIZATION_BLOCKED|xcrun notarytool|xcrun stapler|ENABLE_HARDENED_RUNTIME' scripts/beta-notarization-preflight.sh` | yes | pending |
| 12-01-02 | 01 | 1 | Beta evidence policy | docs/source | `rg 'Phase 12 beta evidence|BETA_NOTARIZATION_BLOCKED|No artifacts committed|Gatekeeper' .planning/phases/12-beta/evidence/README.md docs/release.md` | yes | pending |
| 12-02-01 | 02 | 2 | Beta build/package | shell/source | `bash -n scripts/build-beta.sh && rg 'xcodebuild|archive|hdiutil create|GRIDOS_BETA_OUTPUT_DIR|beta-artifact-manifest.md' scripts/build-beta.sh docs/release.md` | yes | pending |
| 12-02-02 | 02 | 2 | Notarize/staple/verify | shell/source | `bash -n scripts/notarize-beta-artifact.sh && bash -n scripts/verify-beta-artifact.sh && rg 'notarytool submit|stapler staple|stapler validate|spctl --assess|BETA_ARTIFACT_VERIFICATION' scripts docs .planning/phases/12-beta` | yes | pending |
| 12-03-01 | 03 | 3 | Release manifest | shell/docs | `bash -n scripts/write-beta-release-manifest.sh && rg 'beta-release-manifest.json|SHA-256|Gatekeeper|manual Beta N to Beta N+1' scripts docs .planning/phases/12-beta` | yes | pending |
| 12-03-02 | 03 | 3 | Distribution/update docs | docs | `rg 'Download|Verify checksum|Install|Update from Beta N to Beta N+1|Rollback|Known issues' docs/beta-distribution.md .planning/phases/12-beta/BETA-UAT.md` | yes | pending |
| 12-04-01 | 04 | 4 | First-run privacy | XCTest/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test && rg 'BetaPrivacy|first-run privacy|Command Intelligence|Keychain|metadata-only' Sources Tests docs` | yes | pending |
| 12-04-02 | 04 | 4 | Feedback/support loop | docs/source | `rg 'BETA-FEEDBACK|support|sanitized diagnostics|No telemetry|No automatic upload' .planning/phases/12-beta docs Sources Tests` | yes | pending |
| 12-05-01 | 05 | 5 | Clean-Mac Gatekeeper UAT | manual/docs | `rg 'Clean Mac Gatekeeper UAT|spctl --assess|stapler validate|quarantine|Finder launch|PASS|BLOCKED' .planning/phases/12-beta/BETA-UAT.md .planning/phases/12-beta/12-VERIFICATION.md` | yes | pending |
| 12-05-02 | 05 | 5 | Final Beta signoff | full gate | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` | yes | pending |

## Wave 0 Requirements

Existing test infrastructure is sufficient. Phase 12 may add shell scripts, docs, app first-run UI, and tests. No new test framework is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Apple notarization submission | External trust | Requires Apple notary credentials and network access | Run `scripts/notarize-beta-artifact.sh` with a valid notary profile and record sanitized accepted/blocked evidence. |
| Clean Mac Gatekeeper launch | External installability | Requires quarantined download on a clean Mac or fresh user | Download/copy the notarized artifact as quarantined, validate ticket, assess with Gatekeeper, launch from Finder, complete first-run privacy, and record `PASS` or `BLOCKED` in `BETA-UAT.md`. |
| Manual Beta update flow | Update acceptance | Requires two signed/notarized Beta artifacts or a simulated N/N+1 pair | Verify checksum for Beta N+1, replace Beta N, launch, confirm version/build, and record rollback path. |

## Validation Sign-Off

- [x] All tasks have automated verify or manual evidence where unavoidable.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-21
