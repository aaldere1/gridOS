# gridOS production direct release

Status: version 1.0.11
Last updated: 2026-06-18

## Artifact

- Version: 1.0.11
- Build: 19
- Source commit: a3fb5ec
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.11
- DMG: build/release/production/gridOS-1.0.11-19-a3fb5ec.dmg
- DMG SHA-256: 1712d5b34d9b6edf233214a2b927bb7c0cb55838dfe4e9d42c95dcfcee80c9d6
- ZIP: build/release/production/gridOS-1.0.11-19-a3fb5ec.zip
- ZIP SHA-256: c956322ff601d6538d748cae1a8025a646d488d079df8703cc5e99b0cb0ebf4d
- DMG app tree SHA-256: d03ad0b435427dd7b084f285d68f61c7ca3ab75487463d6ea2475b480a3fa29b
- ZIP extracted app tree SHA-256: 78bc7a7749805c64043bce21bf1fea922bcdc3c5164bfe95b6bb3f5ae8cc816c

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, guarded Command
Intelligence, and automatic updates for the direct-download lane. The value is
not "AI terminal" as a gimmick. The value is a beautiful, private command
workspace that helps users think before they run.

Version 1.0.11 keeps the 1.0.10 update and long-session stability work, then
polishes the native pane workflow: terminal copy/paste now works naturally
between panes, clicked panes become the active target for Terminal menu
commands, and pasted text still goes through SwiftTerm's native paste path. It
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
| GitHub Actions CI run 27761563976 | PASS |
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

gridOS 1.0.11 includes Sparkle automatic updates for the direct-download release
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
from 1.0.10 to 1.0.11.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Dropped screenshots are OCR-scanned locally and
provider preview context contains reviewed text and metadata only, not image
pixels or local file paths. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions. Sparkle update checks may
contact the signed appcast and GitHub release assets; system profiling is off.
