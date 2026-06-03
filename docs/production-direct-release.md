# gridOS production direct release

Status: version 1.0.1
Last updated: 2026-06-03

## Artifact

- Version: 1.0.1
- Build: 9
- Source commit: 3f74ed7
- DMG: build/release/production/gridOS-1.0.1-9-3f74ed7.dmg
- DMG SHA-256: 39a64bb9a8d605bcac8089f3a410e67f44a4d87042949880c79ab7c34205824a
- ZIP: build/release/production/gridOS-1.0.1-9-3f74ed7.zip
- ZIP SHA-256: d917d6073e557e75409a92907f2611359aad5ce4b6444766e8faa7d85b825f5e

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, and guarded Command
Intelligence. The value is not "AI terminal" as a gimmick. The value is a
beautiful, private command workspace that helps users think before they run.

Version 1.0.1 adds Anthropic/OpenAI provider selection, current curated model
choices, custom model IDs, and visible pane controls so multi-pane work is more
discoverable.

## First Launch

The first launch should present the local privacy and safety briefing, then move
the user straight into the terminal workspace. It should feel like a polished
tool opening its doors, not a pre-release disclaimer.

## Verification

| Check | Status |
| --- | --- |
| Signed archive | PASS |
| Notarization | PASS |
| Stapler validation | PASS |
| Gatekeeper assessment | PASS |
| Strict codesign verification | PASS |
| Launch from mounted DMG | PASS |
| Visible app version v1.0.1 | PASS |
| Provider settings expose Anthropic and OpenAI | PASS |
| Pane controls visible in packaged app | PASS |
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
