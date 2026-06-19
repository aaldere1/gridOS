# gridOS production direct release

Status: version 1.0.12
Last updated: 2026-06-19

## Artifact

- Version: 1.0.12
- Build: 20
- Source commit: 7b007d0
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.12
- DMG: build/release/production/gridOS-1.0.12-20-7b007d0.dmg
- DMG SHA-256: b0cf33cbd020c45dbd359bffd8e1b59421a12a8980f6ef428ec2cd6b5ed77ff4
- ZIP: build/release/production/gridOS-1.0.12-20-7b007d0.zip
- ZIP SHA-256: 3ef677d2d96de9655360b3b7a1dc63617dce0a32df78cb0e1bd3f8a93e4fe914
- DMG app tree SHA-256: bef75a3db4af2f16c17c6099cec9272fa4db1d0dadcbdc022c0f9f95a784e106
- ZIP extracted app tree SHA-256: 9db7babc3c89c2f267b1d03da707fbdbf6b5ddb62706b3ca4dcaf375c907604f

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, guarded Command
Intelligence, and automatic updates for the direct-download lane. The value is
not "AI terminal" as a gimmick. The value is a beautiful, private command
workspace that helps users think before they run.

Version 1.0.12 keeps the 1.0.11 terminal workflow polish, then fixes the
cross-pane clipboard path more completely: terminal Copy, Paste, and Select All
route through the workspace controller, selected text can be copied from another
pane when the active pane has no selection, and app-driven paste sends clipboard
text into the active pane instead of depending on stale responder focus. It
preserves username-free screenshots, Command-T pane creation, Control-Tab
traversal, drag-to-rearrange panes, AI Command Helper screenshot OCR,
DeepSeek/xAI provider support, and signed/notarized proof for the final
artifact.

## First Launch

The first launch should present the local privacy and safety briefing, then move
the user straight into the terminal workspace. It should feel like a polished
tool opening its doors, not a pre-release disclaimer.

## Verification

| Check | Status |
| --- | --- |
| Xcode CI wrapper | PASS |
| GitHub Actions CI run 27838453986 | PASS |
| Signed archive | PASS |
| Embedded Sparkle helpers Developer ID signed with secure timestamps | PASS |
| Signed DMG container | PASS |
| Notarization | PASS |
| Stapler validation | PASS |
| Gatekeeper assessment | PASS |
| Strict codesign verification | PASS |
| Sparkle appcast generation | PASS |
| GitHub release asset readback | PASS |
| Raw `main` appcast readback | PASS |
| New app icon installed in asset catalog | PASS |
| README hero and screenshots avoid terminal prompts/usernames | PASS |
| Software Updates settings screenshot captured | PASS |
| AI Command Helper settings/menu present | PASS |
| AI Command Helper screenshot drop zone with local OCR messaging | PASS |
| Terminal jitter reduction and pasteboard shortcut tests | PASS |
| Command-T pane creation, Control-Tab traversal, and drag layout tests | PASS |
| Cross-pane terminal clipboard and clicked-pane menu routing tests | PASS |
| Live blocked-pane cross-pane clipboard smoke | PASS |
| Header update affordance and Settings update controls | PASS |
| ZIP extraction strict codesign and Gatekeeper execution assessment | PASS |
| Local 1.0.4 to 1.0.5 replacement proof | PASS |

## Install

1. Open the DMG.
2. Drag `gridOS.app` to `/Applications`.
3. Eject the DMG.
4. Launch `gridOS.app` from Finder.

If Gatekeeper blocks launch, do not advise bypassing it. Treat that as a
release blocker and rebuild or re-notarize.

## Updates

gridOS 1.0.12 includes Sparkle automatic updates for the direct-download release
lane. Automatic checks and automatic download/install are enabled by default,
Sparkle system profiling is disabled, and the manual DMG flow remains available
as a fallback.

Manual update fallback:

1. Quit gridOS.
2. Download the newer signed/notarized DMG.
3. Verify the SHA-256 against the release manifest.
4. Replace the installed app.
5. Launch from Finder.
6. Confirm the app version/build matches the release manifest.

Clean-Mac Finder install/update proof remains useful external validation when a
separate clean Mac is available. Future update proof should validate Sparkle
from 1.0.11 to 1.0.12.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Dropped screenshots are OCR-scanned locally and
provider preview context contains reviewed text and metadata only, not image
pixels or local file paths. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions. Sparkle update checks may
contact the signed appcast and GitHub release assets; system profiling is off.
