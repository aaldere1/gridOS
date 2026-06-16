# gridOS 1.0.8 production direct release

Date: 2026-06-16
Channel: production-direct

## Version

- Version: 1.0.8
- Build: 16
- Source commit: c60fecb
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.8
- DMG: build/release/production/gridOS-1.0.8-16-c60fecb.dmg
- DMG SHA-256: 6884374556bb43ed2895ab9ae2a0486309d52042e069deb28b9d49e88a08e346
- ZIP: build/release/production/gridOS-1.0.8-16-c60fecb.zip
- ZIP SHA-256: 34e02e501362e0fcd797987f85663b980827300238eb9801e05123e9f0d7c1e2
- Extracted app tree SHA-256: 6ddef1c6e063ca7c4abe143f658f459e9b72793ae99f9b9df0c8d95af469b513
- Release notes: docs/release-notes/v1.0.8.md
- Sparkle appcast: appcast.xml

## Proof

- Direct `xcodebuild build test`: PASS
- `scripts/ci-build-test.sh`: PASS
- GitHub Actions CI run 27652514707: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- Notary submission ID: 25ec9d47-d4ec-457e-896e-cfae309ffcd8
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App Gatekeeper execution assessment: PASS
- App stapler validation: PASS
- Bundle version/build check: 1.0.8 / 16
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Sparkle appcast XML validation: PASS
- GitHub release asset readback: PASS
- Raw `main` appcast matches local `appcast.xml`: PASS
- ZIP extraction, strict codesign, stapler validation, and Gatekeeper execution assessment: PASS
- Terminal jitter reduction and active-pane pasteboard shortcut tests: PASS
- AI Command Helper screenshot drop zone with local OCR messaging: PASS
- Local replacement proof from 1.0.4 build 12 to 1.0.5 build 13: historical PASS

## Product Notes

1.0.8 is the terminal polish release. It reduces terminal typing and resize
jitter, restores Command-V paste inside focused terminal panes, adds
terminal-aware Command-A/Command-C behavior, and preserves the 1.0.7 HUD,
font-size, screenshot OCR, DeepSeek, and xAI expansion.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.7 to 1.0.8.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
