# gridOS production direct release

Status: version 1.0.2
Last updated: 2026-06-03

## Artifact

- Version: 1.0.2
- Build: 10
- Source commit: 8f2865b
- DMG: build/release/production/gridOS-1.0.2-10-8f2865b.dmg
- DMG SHA-256: 52db1e21ee81df5b5f6e1bda5aec05888baf64277bbe13fe8d5703ad402f867c
- ZIP: build/release/production/gridOS-1.0.2-10-8f2865b.zip
- ZIP SHA-256: 21d04d90887662749817d4dae2df443d8774ce0707b43f684acda386b49c4ad4

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, and guarded Command
Intelligence. The value is not "AI terminal" as a gimmick. The value is a
beautiful, private command workspace that helps users think before they run.

Version 1.0.2 presents Command Intelligence as AI Command Helper, adds an
info button that explains the feature in plain language, and ships a polished
drag-to-Applications DMG with a signed/notarized installer container.

## First Launch

The first launch should present the local privacy and safety briefing, then move
the user straight into the terminal workspace. It should feel like a polished
tool opening its doors, not a pre-release disclaimer.

## Verification

| Check | Status |
| --- | --- |
| Signed archive | PASS |
| Signed DMG container | PASS |
| Notarization | PASS |
| Stapler validation | PASS |
| Gatekeeper assessment | PASS |
| Strict codesign verification | PASS |
| Launch from mounted DMG | PASS |
| Visible app version v1.0.2 | PASS |
| AI Command Helper settings present | PASS |
| Pane controls visible in packaged app | PASS |
| DMG drag-to-Applications layout | PASS |
| Local 1.0.1 to 1.0.2 replacement proof | PASS |
| Clean quit after launch | PASS |
| Performance quick gate | PASS |

## Install

1. Open the DMG.
2. Drag `gridOS.app` to `/Applications`.
3. Eject the DMG.
4. Launch `gridOS.app` from Finder.

If Gatekeeper blocks launch, do not advise bypassing it. Treat that as a
release blocker and rebuild or re-notarize.

## Update

For the direct-download release lane, update manually until Sparkle or a hosted
update feed is deliberately added:

1. Quit gridOS.
2. Download the newer signed/notarized DMG.
3. Verify the SHA-256 against the release manifest.
4. Replace the installed app.
5. Launch from Finder.
6. Confirm the app version/build matches the release manifest.

Local replacement proof has passed from 1.0.1 build 9 to 1.0.2 build 10 in a
temporary install root. Clean-Mac Finder install/update proof remains the final
external install validation.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions.
