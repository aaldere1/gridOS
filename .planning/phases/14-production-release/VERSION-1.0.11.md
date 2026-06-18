# gridOS 1.0.11 production direct release

Date: 2026-06-18
Channel: production-direct

## Version

- Version: 1.0.11
- Build: 19
- Source commit: a3fb5ec
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.11
- DMG: build/release/production/gridOS-1.0.11-19-a3fb5ec.dmg
- DMG SHA-256: 1712d5b34d9b6edf233214a2b927bb7c0cb55838dfe4e9d42c95dcfcee80c9d6
- ZIP: build/release/production/gridOS-1.0.11-19-a3fb5ec.zip
- ZIP SHA-256: c956322ff601d6538d748cae1a8025a646d488d079df8703cc5e99b0cb0ebf4d
- DMG app tree SHA-256: d03ad0b435427dd7b084f285d68f61c7ca3ab75487463d6ea2475b480a3fa29b
- ZIP extracted app tree SHA-256: 78bc7a7749805c64043bce21bf1fea922bcdc3c5164bfe95b6bb3f5ae8cc816c
- Release notes: docs/release-notes/v1.0.11.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- GitHub Actions CI run 27760536472 for PR #4: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- DMG notary submission ID: b1a8ce38-31d4-462b-a923-c7f2f5a0f556
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App notarization submission ID: 4e00ca4f-9e5e-482f-9da0-ab1bf1690c4e
- App Gatekeeper execution assessment: PASS
- App stapler validation: PASS
- ZIP notarization submission ID: 59835506-07bb-437d-8e0f-e5911cee652c
- ZIP extraction, strict codesign, stapler validation, and Gatekeeper execution assessment: PASS
- Bundle version/build check: 1.0.11 / 19
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Sparkle appcast XML validation: PASS
- Terminal cross-pane clipboard and clicked-pane active routing tests: PASS
- Terminal pane Command-T, Control-Tab, and drag layout tests: PASS
- Terminal jitter reduction, active-pane pasteboard shortcuts, and top-process baseline tests: PASS
- AI Command Helper screenshot drop zone with local OCR messaging: PASS
- Mounted DMG layout check: PASS

## Product Notes

1.0.11 is the terminal workflow polish release. It keeps the 1.0.10 update and
long-session stability work while making copy/paste behave naturally between
terminal panes and keeping Terminal menu commands aligned to the pane the user
actually clicked.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.10 to 1.0.11.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
