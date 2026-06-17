# Production launch-readiness smoke

- Timestamp UTC: 2026-06-17T17:15:00Z
- Artifact: build/release/production/gridOS-1.0.9-17-2d2fe8d.dmg
- Artifact SHA-256: e112a0d16c6e350579cee44c475bc9e0916ab2a4768f7c7b3fb48cc4a2048633
- Artifact size: 9051257 bytes
- Source commit: 2d2fe8d
- Version: 1.0.9
- Build: 17
- Bundle ID: com.aaldere1.gridos
- Mounted proof path: /var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.9-proof.ph4rtU/gridOS.app
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.9-17-2d2fe8d.dmg: accepted
source=Notarized Developer ID
stapler=PASS
```

## Gatekeeper

```text
/var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.9-proof.ph4rtU/gridOS.app: accepted
source=Notarized Developer ID
```

## Strict Code Signature

```text
CODESIGN=PASS
codesign --verify --deep --strict --verbose=2 /var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.9-proof.ph4rtU/gridOS.app
```

## Version And Settings Sample

```text
VERSION=1.0.9
BUILD=17
BUNDLE_ID=com.aaldere1.gridos
DMG_SHA256=e112a0d16c6e350579cee44c475bc9e0916ab2a4768f7c7b3fb48cc4a2048633
APP_BUNDLE_SHA256=5215282e064aa3305a964bdc2acfa0da2568649c4bc0065c5210a07676acdb08
SUFeedURL=https://raw.githubusercontent.com/aaldere1/gridOS/main/appcast.xml
SUPublicEDKey=nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=
SUEnableAutomaticChecks=true
SUAutomaticallyUpdate=true
SUEnableSystemProfiling=false
```

## DMG Layout

```text
/var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.9-proof.ph4rtU/.background
/var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.9-proof.ph4rtU/Applications
/var/folders/_y/z6x0d7px3tv7z8q2cwclc33m0000gn/T//gridos-1.0.9-proof.ph4rtU/gridOS.app
```

## Public Screenshots

The committed public README screenshots were inspected for the 1.0.9 release:

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

## Terminal Pane Polish

The 1.0.9 source changes were covered by `scripts/ci-build-test.sh`. The test
suite includes Command-T pane creation, Control-Tab and Control-Shift-Tab pane
traversal, drag-to-rearrange pane headers, active-pane paste/copy/select-all,
font-size propagation, and surface-update coverage.

## Cleanup

- DMG detach status: PASS

## Notes

This smoke mounts and assesses the final notarized DMG on the current Mac. It is
not clean-Mac evidence and does not replace the remaining external Finder and
Sparkle update validation. It does not commit shell history, terminal output,
environment variables, screenshots with user prompts, API keys, private file
contents, generated commands, provider responses, or raw terminal transcripts.
