# gridOS production direct release

Status: version 1.0.5
Last updated: 2026-06-04

## Artifact

- Version: 1.0.5
- Build: 13
- Source commit: 379289a
- DMG: build/release/production/gridOS-1.0.5-13-379289a.dmg
- DMG SHA-256: b3f94f03ca5db2f1c3fa9fb1df0fa0cdcacd6998927a878fc6b312768e0c5a05
- ZIP: build/release/production/gridOS-1.0.5-13-379289a.zip
- ZIP SHA-256: b34e83b27ea4f17d9e6076d46686bee7f6330f3eb5357459b5085b1f5ed3e54f
- App bundle SHA-256: 05cc09d1b6fcd010bef4505b63eea99ba0e4185b364eecfb95191fae331acbf7

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, and guarded Command
Intelligence. The value is not "AI terminal" as a gimmick. The value is a
beautiful, private command workspace that helps users think before they run.

Version 1.0.5 keeps the 1.0.4 production base and sharpens the AI Command
Helper experience. Command-K now explains each helper mode in context, provider
setup is clearer, Settings is a resizable macOS window, and the visible app
version derives from the signed bundle metadata.

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
| Visible app version v1.0.5 | PASS |
| AI Command Helper settings/menu present | PASS |
| AI Command Helper mode guidance visible | PASS |
| AI Command Helper provider setup copy visible | PASS |
| Settings opens to AI Helper from Command-K | PASS |
| Settings window resizes from 700x640 to 980x780 | PASS |
| Pane controls visible in packaged app | PASS |
| DMG drag-to-Applications layout | PASS |
| Computer Use visual app check | PASS |
| Computer Use DMG layout check | PASS |
| Installed `/Applications` copy replaced from 1.0.5 DMG | PASS |
| Local 1.0.4 to 1.0.5 replacement proof | PASS |
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

Local replacement proof has passed from 1.0.4 build 12 to 1.0.5 build 13 in a
temporary install root. Clean-Mac Finder install/update proof remains the final
external install validation.

This development Mac had an existing `/Applications/gridOS.app` from earlier
testing. For 1.0.5, the mounted DMG app and the replaced Applications copy were
both inspected through Computer Use and reported visible `v1.0.5`.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions.
