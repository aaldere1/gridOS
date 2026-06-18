# Production launch-readiness smoke

- Timestamp UTC: 2026-06-18T13:02:00Z
- Artifact: build/release/production/gridOS-1.0.11-19-a3fb5ec.dmg
- Artifact SHA-256: 1712d5b34d9b6edf233214a2b927bb7c0cb55838dfe4e9d42c95dcfcee80c9d6
- Artifact size: 9014868 bytes
- Source commit: a3fb5ec
- Version: 1.0.11
- Build: 19
- Bundle ID: com.aaldere1.gridos
- Mounted proof path: sanitized mounted DMG root/gridOS.app
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.11-19-a3fb5ec.dmg: accepted
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
VERSION=1.0.11
BUILD=19
BUNDLE_ID=com.aaldere1.gridos
DMG_SHA256=1712d5b34d9b6edf233214a2b927bb7c0cb55838dfe4e9d42c95dcfcee80c9d6
DMG_APP_BUNDLE_SHA256=d03ad0b435427dd7b084f285d68f61c7ca3ab75487463d6ea2475b480a3fa29b
ZIP_EXTRACTED_APP_BUNDLE_SHA256=78bc7a7749805c64043bce21bf1fea922bcdc3c5164bfe95b6bb3f5ae8cc816c
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

## Launch Observation

The app process launched from the mounted notarized DMG on the current Mac. A
release one-shot `--cmd` marker was attempted for terminal smoke, but the marker
was not written before timeout; this is treated as out of scope because
`docs/release.md` identifies the `--cmd` terminal smoke as a Debug-build helper.
The release artifact proof therefore relies on Gatekeeper, strict codesign,
stapler validation, mounted-DMG layout, and unit coverage for terminal command
routing.

## Public Screenshots

The committed public README screenshots were inspected for the 1.0.11 release:

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

The 1.0.11 source changes were covered by `scripts/ci-build-test.sh`. The test
suite includes cross-pane terminal copy/paste, clicked-pane active routing,
Command-T pane creation, Control-Tab and Control-Shift-Tab pane traversal,
drag-to-rearrange pane headers, active-pane paste/copy/select-all, font-size
propagation, surface-update coverage, and top-process baseline retention.

## Cleanup

- Mounted gridOS process cleanup: PASS
- DMG detach status: PASS

## Notes

This smoke mounts and assesses the final notarized DMG on the current Mac. It is
not clean-Mac evidence and does not replace the remaining external Finder and
Sparkle update validation. It does not commit shell history, terminal output,
environment variables, screenshots with user prompts, API keys, private file
contents, generated commands, provider responses, or raw terminal transcripts.
