# Phase 14 production version 1.0.0

Status: production version prepared
Last updated: 2026-06-03

## Build

- Product: gridOS
- Version: 1.0.0
- Build: 8
- Source commit: b31bd2a
- Artifact: build/release/production/gridOS-1.0.0-8-b31bd2a.dmg
- ZIP: build/release/production/gridOS-1.0.0-8-b31bd2a.zip

## Release Decision

Version 1.0.0 is the first production direct-download version. The app bundle,
visible app header, release artifact, release notes, and release evidence now
agree on the same version. This is no longer framed as a candidate build.

## Verification

| Gate | Status | Evidence |
| --- | --- | --- |
| Build/archive | PASS | .planning/phases/12-beta/evidence/beta-artifact-manifest.md |
| Notarization | PASS | .planning/phases/12-beta/evidence/beta-notarization.md |
| Stapler/Gatekeeper/codesign | PASS | .planning/phases/12-beta/evidence/beta-artifact-verification.md |
| Launch from DMG | PASS | .planning/phases/14-production-release/evidence/production-launch-smoke.md |
| Visible version | PASS | .planning/phases/14-production-release/evidence/production-launch-smoke.md |
| Performance gate | PASS | .planning/phases/09-performance-hardening/evidence/phase9-results.json |
| Product desirability pass | PASS | docs/product-desirability.md |

## Remaining Validation

The version is locally signed, notarized, Gatekeeper-accepted, launch-smoked,
visually inspected, and performance-gated. The remaining validation is external:
run Finder install/update proof on a clean Mac and record the result.
