# gridOS 1.0.13 production direct release

Date: 2026-06-19
Channel: production-direct

## Version

- Version: 1.0.13
- Build: 21
- Source commit: 00e2893
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.13
- DMG: build/release/production/gridOS-1.0.13-21-00e2893.dmg
- DMG SHA-256: 0c68b1115377dfd4675304ae022f5e40ebf090c237c2192dfd3eb79ada688041
- ZIP: build/release/production/gridOS-1.0.13-21-00e2893.zip
- ZIP SHA-256: ca58ce5da13f035934872c9c19880f185271f6fbd932c6a7a1bbaa1b4b926d7e
- DMG app tree SHA-256: 74d77fda1c2fc9989202e0c20624e97e1d4a996da28b717b1f597ea0e9c4ada7
- ZIP extracted app tree SHA-256: 0dfba7130c5eeaa87ae06caba26edec79f10c205002bbe59b16fcac02fad93f6
- Release notes: docs/release-notes/v1.0.13.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- GitHub Actions CI run 27839793210: PASS
- PR #6 merged cleanly: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- DMG notary submission ID: 5d1d38d0-e436-4869-971b-8975aedb733a
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App stapler validation: PASS
- App Gatekeeper execution assessment: PASS
- App ticket source submission ID: 484d9586-6c60-4271-b043-c893bf355d03
- ZIP notarization submission ID: b90706b2-15e5-4d7c-a5ca-2b307b1f92bd
- ZIP extraction, strict codesign, stapler validation, and Gatekeeper execution assessment: PASS
- Bundle version/build check: 1.0.13 / 21
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Local pane-to-pane selected-text copy/paste smoke: PASS
- Terminal source-pane copy and cross-pane paste tests: PASS
- Terminal pane Command-T and layout publication tests: PASS
- Mounted DMG layout check: PASS

## Product Notes

1.0.13 is a focused source-pane terminal copy fix. It keeps the 1.0.12
cross-pane clipboard routing while making the exact user flow reliable: select
text in one terminal pane/session, copy it, move to another terminal
pane/session, and paste it there.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.12 to 1.0.13.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
