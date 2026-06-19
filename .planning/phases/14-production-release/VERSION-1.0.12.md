# gridOS 1.0.12 production direct release

Date: 2026-06-19
Channel: production-direct

## Version

- Version: 1.0.12
- Build: 20
- Source commit: 7b007d0
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.12
- DMG: build/release/production/gridOS-1.0.12-20-7b007d0.dmg
- DMG SHA-256: b0cf33cbd020c45dbd359bffd8e1b59421a12a8980f6ef428ec2cd6b5ed77ff4
- ZIP: build/release/production/gridOS-1.0.12-20-7b007d0.zip
- ZIP SHA-256: 3ef677d2d96de9655360b3b7a1dc63617dce0a32df78cb0e1bd3f8a93e4fe914
- DMG app tree SHA-256: bef75a3db4af2f16c17c6099cec9272fa4db1d0dadcbdc022c0f9f95a784e106
- ZIP extracted app tree SHA-256: 9db7babc3c89c2f267b1d03da707fbdbf6b5ddb62706b3ca4dcaf375c907604f
- Release notes: docs/release-notes/v1.0.12.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- GitHub Actions CI run 27838082157: PASS
- PR #5 merged cleanly: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- DMG notary submission ID: b0f593b0-95a3-4445-a8a8-03e974a13b3c
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App stapler validation: PASS
- App Gatekeeper execution assessment: PASS
- ZIP notarization submission ID: b9f464c9-985e-4b93-a8c4-2805a2c15457
- ZIP extraction, strict codesign, stapler validation, and Gatekeeper execution assessment: PASS
- Bundle version/build check: 1.0.12 / 20
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Local cross-pane app smoke: PASS
- Terminal cross-pane clipboard and clicked-pane active routing tests: PASS
- Terminal pane Command-T and layout publication tests: PASS
- Mounted DMG layout check: PASS

## Product Notes

1.0.12 is a focused cross-pane clipboard fix. It keeps the 1.0.11 terminal
workflow polish while making copy/paste reliable when multiple panes are open,
including the case where one pane is blocked and a new Command-T pane is the
intended paste target.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.11 to 1.0.12.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
