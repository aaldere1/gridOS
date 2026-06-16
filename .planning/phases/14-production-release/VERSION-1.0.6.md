# gridOS 1.0.6 production direct release

Date: 2026-06-15
Channel: production-direct

## Version

- Version: 1.0.6
- Build: 14
- Source commit: edda1ee
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.6
- DMG: build/release/production/gridOS-1.0.6-14-edda1ee.dmg
- DMG SHA-256: cf6e01770e43b94783fefa25493da01f2471b961280334f63fe804568a1fe9c1
- ZIP: build/release/production/gridOS-1.0.6-14-edda1ee.zip
- ZIP SHA-256: 69e9187ef4af85f3428b76ded72eb2eb676ead3e690b5ec1c1cc9d5207c72e21
- App bundle SHA-256: 7e2c55c1c2a0e5f76ccf8a1b16a2795f729270c04eaa13547ac9b284a70c25c2
- Release notes: docs/release-notes/v1.0.6.md
- Sparkle appcast: appcast.xml

## Proof

- `scripts/ci-build-test.sh`: PASS
- DMG code signature: PASS
- DMG notarization: PASS
- Notary submission ID: 4b8195b6-e9bd-495f-8233-eccad1f793cb
- DMG stapling: PASS
- DMG Gatekeeper assessment: PASS
- App strict code signature: PASS
- App Gatekeeper execution assessment: PASS
- Visible app version: v1.0.6
- Embedded Sparkle helpers Developer ID signed with secure timestamps: PASS
- Sparkle appcast generation: PASS
- Sparkle appcast XML validation: PASS
- Sparkle feed Ed25519 signature verification: PASS
- Sparkle DMG enclosure Ed25519 signature verification: PASS
- Local replacement proof from 1.0.4 build 12 to 1.0.5 build 13: historical PASS

## Product Notes

1.0.6 is the public-polish release. The release adds the new app icon,
username-free README imagery, Sparkle automatic updates for direct distribution,
and signed Sparkle helper binaries inside the final artifact. It keeps the
1.0.5 AI Command Helper clarity, provider setup copy, resizable Settings window,
visible bundle metadata, and drag-to-Applications installer.

## Remaining Validation

- Run Finder/Gatekeeper install proof on a separate clean Mac.
- Prove Sparkle update flow from 1.0.6 to the next release.
- Keep the repository source-available proprietary unless a separate open-source
  licensing decision is made.
