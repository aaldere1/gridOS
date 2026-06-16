# Production launch-readiness smoke

- Timestamp UTC: 2026-06-16T19:13:38Z
- Artifact: build/release/production/gridOS-1.0.7-15-8a1d12e.dmg
- Artifact SHA-256: 415e2da75bcffdae254db65b9948e4953f8e1ab84a5587aff456d0694e8f3e6e
- Source commit: 8a1d12e
- Version: 1.0.7
- Build: 15
- Bundle ID: com.aaldere1.gridos
- Mounted proof path: /tmp/gridos-1.0.7-proof.KzUsLS/gridOS.app
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.7-15-8a1d12e.dmg: accepted
source=Notarized Developer ID
stapler=PASS
```

## Gatekeeper

```text
/tmp/gridos-1.0.7-proof.KzUsLS/gridOS.app: accepted
source=Notarized Developer ID
```

## Strict Code Signature

```text
CODESIGN=PASS
codesign --verify --deep --strict --verbose=2 /tmp/gridos-1.0.7-proof.KzUsLS/gridOS.app
```

## Version And Settings Sample

```text
VERSION=1.0.7
BUILD=15
BUNDLE_ID=com.aaldere1.gridos
DMG_SHA256=415e2da75bcffdae254db65b9948e4953f8e1ab84a5587aff456d0694e8f3e6e
SUFeedURL=https://raw.githubusercontent.com/aaldere1/gridOS/main/appcast.xml
SUPublicEDKey=nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=
SUEnableAutomaticChecks=true
SUAutomaticallyUpdate=true
SUEnableSystemProfiling=false
```

## DMG Layout

```text
/tmp/gridos-1.0.7-proof.KzUsLS/.DS_Store
/tmp/gridos-1.0.7-proof.KzUsLS/gridOS.app
/tmp/gridos-1.0.7-proof.KzUsLS/Applications
/tmp/gridos-1.0.7-proof.KzUsLS/.background
```

## Public Screenshots

The committed public README screenshots were inspected for the 1.0.7 release:

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

## Cleanup

- DMG detach status: PASS

## Notes

This smoke mounts and assesses the final notarized DMG on the current Mac. It is
not clean-Mac evidence and does not replace the remaining external Finder and
Sparkle update validation. It does not commit shell history, terminal output,
environment variables, screenshots with user prompts, API keys, private file
contents, generated commands, provider responses, or raw terminal transcripts.
