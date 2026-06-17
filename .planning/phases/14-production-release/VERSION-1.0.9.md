# gridOS 1.0.9 production direct release

Date: 2026-06-17
Channel: production-direct

## Version

- Version: 1.0.9
- Build: 17
- Source commit: 2d2fe8d
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.9
- DMG: build/release/production/gridOS-1.0.9-17-2d2fe8d.dmg
- DMG SHA-256: e112a0d16c6e350579cee44c475bc9e0916ab2a4768f7c7b3fb48cc4a2048633
- ZIP: build/release/production/gridOS-1.0.9-17-2d2fe8d.zip
- ZIP SHA-256: f211ecef83d26f09b98258e1d40884c6dfb8382e928143464fe04e4d42e40f6e
- Extracted app tree SHA-256: 5215282e064aa3305a964bdc2acfa0da2568649c4bc0065c5210a07676acdb08
- Release notes: docs/release-notes/v1.0.9.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- GitHub Actions CI run 27707174758: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- DMG notary submission ID: 8ae9e408-6740-4d3c-8149-e4f76fb02fea
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App Gatekeeper execution assessment: PASS
- App stapler validation: PASS
- ZIP notarization submission ID: 7dfaaac2-24a3-4c0c-aa4c-1d33300a49e1
- ZIP extraction, strict codesign, stapler validation, and Gatekeeper execution assessment: PASS
- Bundle version/build check: 1.0.9 / 17
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Sparkle appcast XML validation: PASS
- GitHub release asset readback: PASS
- Raw `main` appcast matches local `appcast.xml`: PASS
- Terminal pane Command-T, Control-Tab, and drag layout tests: PASS
- Terminal jitter reduction and active-pane pasteboard shortcut tests: PASS
- AI Command Helper screenshot drop zone with local OCR messaging: PASS
- Mounted DMG layout check: PASS

## Product Notes

1.0.9 is the native pane workspace release. It adds Command-T terminal pane
creation to the right of the active pane, Control-Tab and Control-Shift-Tab pane
traversal without stealing shell Tab, and drag-to-rearrange pane headers. It
keeps the 1.0.8 terminal jitter and pasteboard polish plus the 1.0.7 HUD,
font-size, screenshot OCR, DeepSeek, and xAI expansion.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.8 to 1.0.9.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
