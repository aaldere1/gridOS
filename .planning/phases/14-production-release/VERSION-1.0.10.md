# gridOS 1.0.10 production direct release

Date: 2026-06-17
Channel: production-direct

## Version

- Version: 1.0.10
- Build: 18
- Source commit: 26f01e7
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.10
- DMG: build/release/production/gridOS-1.0.10-18-26f01e7.dmg
- DMG SHA-256: 5fc389fa655ae9793503bd554615ee067443856a30fb64c5700e459ecb5b56c1
- ZIP: build/release/production/gridOS-1.0.10-18-26f01e7.zip
- ZIP SHA-256: a5b6d670a7ab3949642a23c8c3305cb768dbbb916262f3557d271e04385e21c4
- Extracted app tree SHA-256: 0efb8b232885fff498c4bf6109cbea98aeeb6fc606a8278e8e323df13b80886c
- Release notes: docs/release-notes/v1.0.10.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- DMG notary submission ID: fada5925-970b-4562-9623-da68d19d592e
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App Gatekeeper execution assessment: PASS
- App stapler validation: PASS
- ZIP notarization submission ID: ada2c70d-c9db-419e-b088-9b3f92299d12
- ZIP extraction, strict codesign, stapler validation, and Gatekeeper execution assessment: PASS
- Bundle version/build check: 1.0.10 / 18
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Sparkle appcast XML validation: PASS
- Header update affordance and Settings update controls: PASS
- Terminal pane Command-T, Control-Tab, and drag layout tests: PASS
- Terminal jitter reduction, active-pane pasteboard shortcuts, and top-process baseline tests: PASS
- AI Command Helper screenshot drop zone with local OCR messaging: PASS
- Mounted DMG layout check: PASS

## Product Notes

1.0.10 is the update and long-session stability release. It keeps the 1.0.9
native pane workspace while adding a visible update badge when Sparkle finds a
newer signed release, clearer Settings update controls, and retained
top-process CPU baselines so the metrics rail does not churn during long-running
terminal sessions.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.9 to 1.0.10.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
