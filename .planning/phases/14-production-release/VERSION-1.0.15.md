# gridOS 1.0.15 production direct release

Date: 2026-06-19
Channel: production-direct

## Version

- Version: 1.0.15
- Build: 23
- Source commit: f7b51bc
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.15
- DMG: build/release/production/gridOS-1.0.15-23-f7b51bc.dmg
- DMG SHA-256: 92f6a0fd0f74b5fdae70b1cdb390e3846dd3020555ebe01a312ea459252b1593
- ZIP: build/release/production/gridOS-1.0.15-23-f7b51bc.zip
- ZIP SHA-256: 395df75adbc9f8487cb59a6e24aba0ae1467ea5eb30d56817679e1c14fe4843b
- DMG app tree SHA-256: eb5a56c3f0d56eb5c39388955218a752c60cae275c567ef1ce7c2c148885a77d
- ZIP extracted app tree SHA-256: eb5a56c3f0d56eb5c39388955218a752c60cae275c567ef1ce7c2c148885a77d
- Release notes: docs/release-notes/v1.0.15.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- GitHub Actions CI run 27842904901 for PR #8 merge: PASS
- GitHub Actions CI run 27842978804 for version bump commit f7b51bc: PASS
- PR #8 merged cleanly: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- DMG notary submission ID: 7a74f95d-e087-4b0b-a3f0-e5dfebf790e9
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- Mounted DMG app stapler validation: PASS
- App strict code signature: PASS
- App stapler validation: PASS
- App Gatekeeper execution assessment: PASS
- ZIP notarization submission ID: 0de75ff3-db77-4fe7-b6ae-475e8decf586
- ZIP extraction, strict codesign, stapler validation, and Gatekeeper execution assessment: PASS
- Bundle version/build check: 1.0.15 / 23
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Terminal source-pane paste, source-pane Select All, source-pane copy, and cross-pane paste tests: PASS
- Terminal pane Command-T and layout publication tests: PASS
- Mounted DMG layout check: PASS

## Product Notes

1.0.15 is a focused multi-pane paste-routing follow-up. It keeps the 1.0.14
Select All and 1.0.13 copy fixes while routing terminal-originated Command-V to
the pane that emitted the shortcut, even after pane switching, repeated paste
events, and drag-to-rearrange layout changes.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.14 to 1.0.15.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
