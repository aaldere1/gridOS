# gridOS production direct release

Status: version 1.0.9
Last updated: 2026-06-17

## Artifact

- Version: 1.0.9
- Build: 17
- Source commit: 2d2fe8d
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.9
- DMG: build/release/production/gridOS-1.0.9-17-2d2fe8d.dmg
- DMG SHA-256: e112a0d16c6e350579cee44c475bc9e0916ab2a4768f7c7b3fb48cc4a2048633
- ZIP: build/release/production/gridOS-1.0.9-17-2d2fe8d.zip
- ZIP SHA-256: f211ecef83d26f09b98258e1d40884c6dfb8382e928143464fe04e4d42e40f6e
- Extracted app tree SHA-256: 5215282e064aa3305a964bdc2acfa0da2568649c4bc0065c5210a07676acdb08

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, guarded Command
Intelligence, and automatic updates for the direct-download lane. The value is
not "AI terminal" as a gimmick. The value is a beautiful, private command
workspace that helps users think before they run.

Version 1.0.9 keeps the 1.0.8 terminal feel fixes and makes pane management
native: Command-T creates a new terminal to the right, Control-Tab and
Control-Shift-Tab move focus across panes without stealing shell Tab, and pane
headers can be dragged to rearrange the workspace. It preserves username-free
screenshots, Sparkle automatic updates, and signed/notarized proof for the
final artifact.

## First Launch

The first launch should present the local privacy and safety briefing, then move
the user straight into the terminal workspace. It should feel like a polished
tool opening its doors, not a pre-release disclaimer.

## Verification

| Check | Status |
| --- | --- |
| Xcode CI wrapper | PASS |
| Signed archive | PASS |
| Embedded Sparkle helpers Developer ID signed with secure timestamps | PASS |
| Signed DMG container | PASS |
| Notarization | PASS |
| Stapler validation | PASS |
| Gatekeeper assessment | PASS |
| Strict codesign verification | PASS |
| Sparkle appcast generation | PASS |
| New app icon installed in asset catalog | PASS |
| README hero and screenshots avoid terminal prompts/usernames | PASS |
| Software Updates settings screenshot captured | PASS |
| AI Command Helper settings/menu present | PASS |
| AI Command Helper screenshot drop zone with local OCR messaging | PASS |
| Terminal jitter reduction and pasteboard shortcut tests | PASS |
| Command-T pane creation, Control-Tab traversal, and drag layout tests | PASS |
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

gridOS 1.0.9 includes Sparkle automatic updates for the direct-download release
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
from 1.0.8 to 1.0.9.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Dropped screenshots are OCR-scanned locally and
provider preview context contains reviewed text and metadata only, not image
pixels or local file paths. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions. Sparkle update checks may
contact the signed appcast and GitHub release assets; system profiling is off.
