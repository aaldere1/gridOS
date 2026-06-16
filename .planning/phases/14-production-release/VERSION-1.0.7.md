# gridOS 1.0.7 production direct release

Date: 2026-06-16
Channel: production-direct

## Version

- Version: 1.0.7
- Build: 15
- Source commit: 8a1d12e
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.7
- DMG: build/release/production/gridOS-1.0.7-15-8a1d12e.dmg
- DMG SHA-256: 415e2da75bcffdae254db65b9948e4953f8e1ab84a5587aff456d0694e8f3e6e
- ZIP: build/release/production/gridOS-1.0.7-15-8a1d12e.zip
- ZIP SHA-256: 75337900bf9ff24b0372585022886bcbbe0e978bb5bbd9cfcf14853fe9219fb7
- Extracted app tree SHA-256: 52cdb2086fe4ac29d430a2d5919912621e261afd3a1e9f803ed3c630a99ab8f6
- Release notes: docs/release-notes/v1.0.7.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- Notary submission ID: d02cd34e-4473-4123-80b8-1b4e9fd2bb52
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App Gatekeeper execution assessment: PASS
- Visible app version: v1.0.7
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Sparkle appcast XML validation: PASS
- ZIP extraction, strict codesign, and Gatekeeper execution assessment: PASS
- AI Command Helper screenshot drop zone with local OCR messaging: PASS
- Local replacement proof from 1.0.4 build 12 to 1.0.5 build 13: historical PASS

## Product Notes

1.0.7 is the HUD and Command-K refinement release. It adds Matrix, Amber CRT,
and Redline visual modes; a HUD Signal rail; live terminal font-size controls;
DeepSeek and xAI provider integrations; local screenshot OCR drops in AI
Command Helper; roomier helper spacing; and refreshed username-free README
screenshots.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.6 to 1.0.7.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
