# gridOS production direct release

Status: version 1.0.14
Last updated: 2026-06-19

## Artifact

- Version: 1.0.14
- Build: 22
- Source commit: c245751
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.14
- DMG: build/release/production/gridOS-1.0.14-22-c245751.dmg
- DMG SHA-256: ff78c949c06bfaec170fd56b8d63c66d6a181622fb2c4966d6834ccad4e268f9
- ZIP: build/release/production/gridOS-1.0.14-22-c245751.zip
- ZIP SHA-256: 46be3c5c3ae9721ba59c195a16d94d8497e1857ec854599e7e7c6328aa8686ba
- DMG app tree SHA-256: 2b1ddc05c684ed91c3c7bbb7fe30e0182bab5cae1fe1bd498172741529b882f2
- ZIP extracted app tree SHA-256: be125ab5ea19ade4d87fd601239bde50b4e0d364640e8e729e0f1d47b3793659

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, guarded Command
Intelligence, and automatic updates for the direct-download lane. The value is
not "AI terminal" as a gimmick. The value is a beautiful, private command
workspace that helps users think before they run.

Version 1.0.14 keeps the 1.0.13 source-pane copy fix and closes the remaining
source-pane Select All path: when Command-A is emitted from one terminal
pane/session, gridOS selects that pane before falling back to the active pane.
That makes selected-all text copy from the pane the user is actually using and
paste reliably into another pane. It preserves username-free screenshots,
Command-T pane creation, Control-Tab traversal, drag-to-rearrange panes, AI
Command Helper screenshot OCR, DeepSeek/xAI provider support, and
signed/notarized proof for the final artifact.

## First Launch

The first launch should present the local privacy and safety briefing, then move
the user straight into the terminal workspace. It should feel like a polished
tool opening its doors, not a pre-release disclaimer.

## Verification

| Check | Status |
| --- | --- |
| Xcode CI wrapper | PASS |
| GitHub Actions CI run 27841066943 | PASS |
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
| Source-pane Select All, source-pane copy, and cross-pane paste tests | PASS |
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

gridOS 1.0.14 includes Sparkle automatic updates for the direct-download release
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
from 1.0.13 to 1.0.14.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Dropped screenshots are OCR-scanned locally and
provider preview context contains reviewed text and metadata only, not image
pixels or local file paths. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions. Sparkle update checks may
contact the signed appcast and GitHub release assets; system profiling is off.
