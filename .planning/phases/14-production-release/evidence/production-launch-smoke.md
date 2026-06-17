# Production launch-readiness smoke

- Timestamp UTC: 2026-06-17T21:58:00Z
- Artifact: build/release/production/gridOS-1.0.10-18-26f01e7.dmg
- Artifact SHA-256: 5fc389fa655ae9793503bd554615ee067443856a30fb64c5700e459ecb5b56c1
- Artifact size: 9086688 bytes
- Source commit: 26f01e7
- Version: 1.0.10
- Build: 18
- Bundle ID: com.aaldere1.gridos
- Mounted proof path: sanitized mounted DMG root/gridOS.app
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.10-18-26f01e7.dmg: accepted
source=Notarized Developer ID
stapler=PASS
```

## Gatekeeper

```text
mounted DMG root/gridOS.app: accepted
source=Notarized Developer ID
```

## Strict Code Signature

```text
CODESIGN=PASS
codesign --verify --deep --strict --verbose=2 mounted DMG root/gridOS.app
```

## Version And Settings Sample

```text
VERSION=1.0.10
BUILD=18
BUNDLE_ID=com.aaldere1.gridos
DMG_SHA256=5fc389fa655ae9793503bd554615ee067443856a30fb64c5700e459ecb5b56c1
APP_BUNDLE_SHA256=0efb8b232885fff498c4bf6109cbea98aeeb6fc606a8278e8e323df13b80886c
SUFeedURL=https://raw.githubusercontent.com/aaldere1/gridOS/main/appcast.xml
SUPublicEDKey=nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=
SUEnableAutomaticChecks=true
SUAutomaticallyUpdate=true
SUEnableSystemProfiling=false
```

## DMG Layout

```text
mounted DMG root/.background
mounted DMG root/Applications
mounted DMG root/gridOS.app
APPLICATIONS_LINK=present
BACKGROUND_FILE_COUNT=1
```

## Public Screenshots

The committed public README screenshots were inspected for the 1.0.10 release:

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

## Terminal And Update Polish

The 1.0.10 source changes were covered by `scripts/ci-build-test.sh`. The test
suite includes Command-T pane creation, Control-Tab and Control-Shift-Tab pane
traversal, drag-to-rearrange pane headers, active-pane paste/copy/select-all,
font-size propagation, surface-update coverage, and top-process baseline
retention.

## Cleanup

- DMG detach status: PASS

## Notes

This smoke mounts and assesses the final notarized DMG on the current Mac. It is
not clean-Mac evidence and does not replace the remaining external Finder and
Sparkle update validation. It does not commit shell history, terminal output,
environment variables, screenshots with user prompts, API keys, private file
contents, generated commands, provider responses, or raw terminal transcripts.
