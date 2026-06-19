# gridOS 1.0.14 production direct release

Date: 2026-06-19
Channel: production-direct

## Version

- Version: 1.0.14
- Build: 22
- Source commit: c245751
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.14
- DMG: build/release/production/gridOS-1.0.14-22-c245751.dmg
- DMG SHA-256: ff78c949c06bfaec170fd56b8d63c66d6a181622fb2c4966d6834ccad4e268f9
- ZIP: build/release/production/gridOS-1.0.14-22-c245751.zip
- ZIP SHA-256: 46be3c5c3ae9721ba59c195a16d94d8497e1857ec854599e7e7c6328aa8686ba
- DMG app tree SHA-256: 2b1ddc05c684ed91c3c7bbb7fe30e0182bab5cae1fe1bd498172741529b882f2
- ZIP extracted app tree SHA-256: be125ab5ea19ade4d87fd601239bde50b4e0d364640e8e729e0f1d47b3793659
- Release notes: docs/release-notes/v1.0.14.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- GitHub Actions CI run 27841066943: PASS
- PR #6 and PR #7 merged cleanly: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- DMG notary submission ID: 0f629080-a7cd-4d3e-925b-712a21eba262
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App stapler validation: PASS
- App Gatekeeper execution assessment: PASS
- App ticket source submission ID: 5a817acf-292f-4581-a30b-1ea093b16a35
- ZIP notarization submission ID: a22c85bc-26ab-4db9-a4fb-a51ec852fc85
- ZIP extraction, strict codesign, stapler validation, and Gatekeeper execution assessment: PASS
- Bundle version/build check: 1.0.14 / 22
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Local pane-to-pane selected-text copy/paste smoke: PASS
- Terminal source-pane Select All, source-pane copy, and cross-pane paste tests: PASS
- Terminal pane Command-T and layout publication tests: PASS
- Mounted DMG layout check: PASS

## Product Notes

1.0.14 is a focused source-pane terminal Select All follow-up. It keeps the
1.0.13 source-pane copy fix while completing the exact user flow: Select All or
select text in one terminal pane/session, copy it, move to another terminal
pane/session, and paste it there.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.13 to 1.0.14.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
