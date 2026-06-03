# gridOS production direct release

Status: release candidate
Last updated: 2026-06-03

## Artifact

- Version: 0.1.0
- Build: 7
- Source commit: ebbfd6f
- DMG: build/release/production/gridOS-0.1.0-7-ebbfd6f.dmg
- DMG SHA-256: 06dc58f8cc4d4f086aeb2b95b9dce6aa235ab839c4a948ea197204bbf74fa70a
- ZIP: build/release/production/gridOS-0.1.0-7-ebbfd6f.zip
- ZIP SHA-256: 77d6abf14d77952d168e454f1cc049a5e087f0e315019088a8720ff13c707cbb

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, and guarded Command
Intelligence. The value is not "AI terminal" as a gimmick. The value is a
beautiful, private command workspace that helps users think before they run.

## First Launch

The first launch should present the local privacy and safety briefing, then move
the user straight into the terminal workspace. It should feel like a polished
tool opening its doors, not a beta disclaimer.

## Verification

| Check | Status |
| --- | --- |
| Signed archive | PASS |
| Notarization | PASS |
| Stapler validation | PASS |
| Gatekeeper assessment | PASS |
| Strict codesign verification | PASS |
| Launch from mounted DMG | PASS |
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

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions.
