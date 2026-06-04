# gridOS 1.0.4 production direct release

Status: release candidate promoted for direct-download distribution.
Date: 2026-06-04

## Build

- Version: 1.0.4
- Build: 12
- Source commit: fe73021
- DMG: build/release/production/gridOS-1.0.4-12-fe73021.dmg
- DMG SHA-256: ca9ace5da768270d8fe81261c36b3e53239bcf6576e9727d9d728685d2c60640
- ZIP: build/release/production/gridOS-1.0.4-12-fe73021.zip
- ZIP SHA-256: ad403753dabf21439c62f0db8dbea7e3b2e46fcf242a2d0557914907a63c9a02
- App bundle SHA-256: 800fa6a05b318c0319b8387fe0997f8b548f27c0f7bdac7422e849cef924be09

## Verification

- Xcode test suite: PASS
- DMG codesign: PASS
- DMG Gatekeeper assessment: PASS
- App strict codesign: PASS
- App Gatekeeper assessment: PASS
- Notarization: PASS
- Staple validation: PASS
- Launch from mounted DMG: PASS
- Computer Use app visual inspection: PASS
- Computer Use DMG drag-to-Applications inspection: PASS
- Local replacement proof from 1.0.2 build 10 to 1.0.4 build 12: PASS

## Notes

Computer Use initially attached to a stale `/Applications/gridOS.app` at
version 1.0.0 because this Mac still has an old installed copy. Directly
targeting the mounted 1.0.4 DMG app showed the correct visible version, toolbar,
AI Command Helper menu, and clipped four-pane workspace. Testers should replace
the installed app from the 1.0.4 DMG before launching from Applications.
