# Phase 14 production version 1.0.1

Status: production version prepared
Date: 2026-06-03

## Version

- Version: 1.0.1
- Build: 9
- Source commit: 3f74ed7
- Artifact: build/release/production/gridOS-1.0.1-9-3f74ed7.dmg
- ZIP: build/release/production/gridOS-1.0.1-9-3f74ed7.zip
- DMG SHA-256: 39a64bb9a8d605bcac8089f3a410e67f44a4d87042949880c79ab7c34205824a

## Release Delta

Version 1.0.1 adds the provider refresh requested after 1.0.0: Command
Intelligence now supports Anthropic and OpenAI keys, provider-specific Keychain
storage, current curated model choices, custom model IDs, and clearer settings
copy explaining what Command Intelligence does. The terminal workspace also now
shows direct pane controls and a pane count so users can discover that the app
is not capped at three terminals.

## Verification

| Check | Status | Evidence |
| --- | --- | --- |
| Full Xcode test suite | PASS | xcodebuild test, 2026-06-03T13:35Z |
| Signed archive | PASS | .planning/phases/12-beta/evidence/beta-artifact-manifest.md |
| Notarization | PASS | .planning/phases/12-beta/evidence/beta-notarization.md |
| Stapler validation | PASS | .planning/phases/12-beta/evidence/beta-notarization.md |
| Gatekeeper assessment | PASS | .planning/phases/12-beta/evidence/beta-artifact-verification.md |
| Strict codesign verification | PASS | .planning/phases/12-beta/evidence/beta-artifact-verification.md |
| Launch from mounted DMG | PASS | .planning/phases/14-production-release/evidence/production-launch-smoke.md |
| Visible version v1.0.1 | PASS | .planning/phases/14-production-release/evidence/production-launch-smoke.md |
| Provider settings from packaged app | PASS | .planning/phases/14-production-release/evidence/production-launch-smoke.md |
| Performance quick gate | PASS | .planning/phases/09-performance-hardening/evidence/phase9-results.json |

## Remaining External Validation

- Clean-Mac Finder/Gatekeeper install for build 9.
- Version-to-version replacement/update proof from 1.0.0 build 8 to 1.0.1 build 9.
- External tester feedback after download/install.
