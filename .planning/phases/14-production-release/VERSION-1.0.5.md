# gridOS 1.0.5 production direct release

Status: released for direct-download distribution.
Date: 2026-06-04

## Build

- Version: 1.0.5
- Build: 13
- Source commit: 379289a
- DMG: build/release/production/gridOS-1.0.5-13-379289a.dmg
- DMG SHA-256: b3f94f03ca5db2f1c3fa9fb1df0fa0cdcacd6998927a878fc6b312768e0c5a05
- ZIP: build/release/production/gridOS-1.0.5-13-379289a.zip
- ZIP SHA-256: b34e83b27ea4f17d9e6076d46686bee7f6330f3eb5357459b5085b1f5ed3e54f
- App bundle SHA-256: 05cc09d1b6fcd010bef4505b63eea99ba0e4185b364eecfb95191fae331acbf7

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
- Computer Use AI Command Helper inspection: PASS
- Computer Use resizable Settings inspection: PASS
- Computer Use DMG drag-to-Applications inspection: PASS
- Installed Applications copy visible version: PASS
- Local replacement proof from 1.0.4 build 12 to 1.0.5 build 13: PASS

## Notes

1.0.5 is a polish release for AI Command Helper. The release makes the
Command-K panel self-explanatory, adds clearer provider setup states, gives
Settings a custom resizable macOS window, and fixes visible-version drift by
reading the version from bundle metadata.
