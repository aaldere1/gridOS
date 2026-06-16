# Production launch-readiness smoke

- Timestamp UTC: 2026-06-16T22:25:50Z
- Artifact: build/release/production/gridOS-1.0.8-16-c60fecb.dmg
- Artifact SHA-256: 6884374556bb43ed2895ab9ae2a0486309d52042e069deb28b9d49e88a08e346
- Artifact size: 8913473 bytes
- Source commit: c60fecb
- Version: 1.0.8
- Build: 16
- Bundle ID: com.aaldere1.gridos
- Mounted proof path: /var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.8-proof.dybWm3/gridOS.app
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.8-16-c60fecb.dmg: accepted
source=Notarized Developer ID
stapler=PASS
```

## Gatekeeper

```text
/var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.8-proof.dybWm3/gridOS.app: accepted
source=Notarized Developer ID
```

## Strict Code Signature

```text
CODESIGN=PASS
codesign --verify --deep --strict --verbose=2 /var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.8-proof.dybWm3/gridOS.app
```

## Version And Settings Sample

```text
VERSION=1.0.8
BUILD=16
BUNDLE_ID=com.aaldere1.gridos
DMG_SHA256=6884374556bb43ed2895ab9ae2a0486309d52042e069deb28b9d49e88a08e346
SUFeedURL=https://raw.githubusercontent.com/aaldere1/gridOS/main/appcast.xml
SUPublicEDKey=nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=
SUEnableAutomaticChecks=true
SUAutomaticallyUpdate=true
SUEnableSystemProfiling=false
```

## DMG Layout

```text
/var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.8-proof.dybWm3/.background
/var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.8-proof.dybWm3/Applications
/var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.8-proof.dybWm3/gridOS.app
```

## Public Screenshots

The committed public README screenshots were inspected for the 1.0.8 release:

- `docs/assets/readme/screenshots/gridos-hud-signal.png`: shows the Redline HUD Signal rail without terminal prompt, username, path, or private content.
- `docs/assets/readme/screenshots/gridos-command-helper.png`: shows the AI Command Helper screenshot drop zone and local OCR messaging without terminal prompt, username, path, or private content.
- `docs/assets/readme/screenshots/gridos-settings-updates.png`: shows Software Updates controls, automatic checks, automatic install, signed GitHub release asset copy, and system profiling off copy without terminal prompt, username, path, or private content.

The main terminal surface correctly shows a live local shell prompt, including
the machine/user prompt. Because of that, terminal screenshots are intentionally
not used in public README imagery.

## Embedded Sparkle Helpers

Strict code signature verification traversed the embedded Sparkle helpers.
Sparkle appcast generation also verified the Ed25519 feed signature and the DMG
enclosure signature against the public key embedded in the app.

## Terminal Polish

The 1.0.8 source changes were covered by the local
`xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination
'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` gate. The test
suite includes active-pane terminal paste, copy, select-all, font-size, and
surface-update coverage.

## Cleanup

- DMG detach status: PASS

## Notes

This smoke mounts and assesses the final notarized DMG on the current Mac. It is
not clean-Mac evidence and does not replace the remaining external Finder and
Sparkle update validation. It does not commit shell history, terminal output,
environment variables, screenshots with user prompts, API keys, private file
contents, generated commands, provider responses, or raw terminal transcripts.
