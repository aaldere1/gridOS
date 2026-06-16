# gridOS production direct release

Status: version 1.0.8
Last updated: 2026-06-16

## Artifact

- Version: 1.0.8
- Build: 16
- Source commit: c60fecb
- GitHub release: https://github.com/aaldere1/gridOS/releases/tag/v1.0.8
- DMG: build/release/production/gridOS-1.0.8-16-c60fecb.dmg
- DMG SHA-256: 6884374556bb43ed2895ab9ae2a0486309d52042e069deb28b9d49e88a08e346
- ZIP: build/release/production/gridOS-1.0.8-16-c60fecb.zip
- ZIP SHA-256: 34e02e501362e0fcd797987f85663b980827300238eb9801e05123e9f0d7c1e2
- Extracted app tree SHA-256: 6ddef1c6e063ca7c4abe143f658f459e9b72793ae99f9b9df0c8d95af469b513

## Release Positioning

gridOS is a local-first Mac terminal with a distinctive procedural visual
signature, multi-pane workspaces, calmer host metrics, guarded Command
Intelligence, and automatic updates for the direct-download lane. The value is
not "AI terminal" as a gimmick. The value is a beautiful, private command
workspace that helps users think before they run.

Version 1.0.8 keeps the 1.0.7 HUD and provider expansion base and focuses on
terminal feel: reduced typing and resize jitter, terminal-aware Command-A and
Command-C, restored Command-V paste in focused terminal panes, username-free
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

gridOS 1.0.8 includes Sparkle automatic updates for the direct-download release
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
from 1.0.7 to 1.0.8.

## Privacy Boundaries

gridOS should not ask users to send shell history, terminal transcripts,
environment variables, API keys, generated commands, provider responses, or
screenshots containing secrets. Dropped screenshots are OCR-scanned locally and
provider preview context contains reviewed text and metadata only, not image
pixels or local file paths. Command Intelligence remains preview-first and
provider-backed features remain explicit user actions. Sparkle update checks may
contact the signed appcast and GitHub release assets; system profiling is off.
