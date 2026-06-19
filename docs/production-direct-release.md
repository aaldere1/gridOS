# gridOS production direct release

Status: version 1.0.13
Last updated: 2026-06-19

## Artifact

- Version: 1.0.13
- Build: 21
- Source commit: 00e2893
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.13
- DMG: build/release/production/gridOS-1.0.13-21-00e2893.dmg
- DMG SHA-256: 0c68b1115377dfd4675304ae022f5e40ebf090c237c2192dfd3eb79ada688041
- ZIP: build/release/production/gridOS-1.0.13-21-00e2893.zip
- ZIP SHA-256: ca58ce5da13f035934872c9c19880f185271f6fbd932c6a7a1bbaa1b4b926d7e
- DMG app tree SHA-256: 74d77fda1c2fc9989202e0c20624e97e1d4a996da28b717b1f597ea0e9c4ada7
- ZIP extracted app tree SHA-256: 0dfba7130c5eeaa87ae06caba26edec79f10c205002bbe59b16fcac02fad93f6

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, guarded Command
Intelligence, and automatic updates for the direct-download lane. The value is
not "AI terminal" as a gimmick. The value is a beautiful, private command
workspace that helps users think before they run.

Version 1.0.13 keeps the 1.0.12 cross-pane clipboard routing, then fixes the
more specific source-pane copy path: when Command-C is emitted from one terminal
pane/session, gridOS reads that pane's selection before falling back to active
or other panes. That makes selected text copied from one pane paste reliably
into another pane. It preserves username-free screenshots, Command-T pane
creation, Control-Tab traversal, drag-to-rearrange panes, AI Command Helper
screenshot OCR, DeepSeek/xAI provider support, and signed/notarized proof for
the final artifact.

## First Launch

The first launch should present the local privacy and safety briefing, then move
the user straight into the terminal workspace. It should feel like a polished
tool opening its doors, not a pre-release disclaimer.

## Verification

| Check | Status |
| --- | --- |
| Xcode CI wrapper | PASS |
| GitHub Actions CI run 27839793210 | PASS |
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
| Source-pane terminal copy and cross-pane paste tests | PASS |
| Live pane-to-pane selected-text copy/paste smoke | PASS |
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

gridOS 1.0.13 includes Sparkle automatic updates for the direct-download release
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
from 1.0.12 to 1.0.13.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Dropped screenshots are OCR-scanned locally and
provider preview context contains reviewed text and metadata only, not image
pixels or local file paths. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions. Sparkle update checks may
contact the signed appcast and GitHub release assets; system profiling is off.
