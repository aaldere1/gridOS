# gridOS production direct release

Status: version 1.0.4
Last updated: 2026-06-04

## Artifact

- Version: 1.0.4
- Build: 12
- Source commit: fe73021
- DMG: build/release/production/gridOS-1.0.4-12-fe73021.dmg
- DMG SHA-256: ca9ace5da768270d8fe81261c36b3e53239bcf6576e9727d9d728685d2c60640
- ZIP: build/release/production/gridOS-1.0.4-12-fe73021.zip
- ZIP SHA-256: ad403753dabf21439c62f0db8dbea7e3b2e46fcf242a2d0557914907a63c9a02
- App bundle SHA-256: 800fa6a05b318c0319b8387fe0997f8b548f27c0f7bdac7422e849cef924be09

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, and guarded Command
Intelligence. The value is not "AI terminal" as a gimmick. The value is a
beautiful, private command workspace that helps users think before they run.

Version 1.0.4 presents Command Intelligence as AI Command Helper, supports
OpenAI and Anthropic key setup, refreshes the model defaults, adds a project
folder entry point, protects live shells from accidental close/quit, clips tight
multi-pane layouts cleanly, and ships a polished drag-to-Applications DMG with
a signed/notarized installer container.

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
| Visible app version v1.0.4 | PASS |
| AI Command Helper settings/menu present | PASS |
| Pane controls visible in packaged app | PASS |
| DMG drag-to-Applications layout | PASS |
| Computer Use visual app check | PASS |
| Computer Use DMG layout check | PASS |
| Local 1.0.2 to 1.0.4 replacement proof | PASS |
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

Local replacement proof has passed from 1.0.2 build 10 to 1.0.4 build 12 in a
temporary install root. Clean-Mac Finder install/update proof remains the final
external install validation.

This development Mac initially had a stale `/Applications/gridOS.app` at
version 1.0.0 from an earlier test. The 1.0.4 mounted DMG app itself was
separately inspected through Computer Use and reported the correct visible
version; the local Applications copy was later replaced from the 1.0.4 DMG and
Computer Use verified visible `v1.0.4` there too.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions.
