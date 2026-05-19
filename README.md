# gridOS

A native macOS app for Apple Silicon that reimagines [eDEX-UI](https://github.com/GitSquared/edex-ui) — the Tron-esque sci-fi terminal UI — as a real Mac-first application. Where eDEX-UI was an Electron remake of the look, gridOS aims to be the tool you'd actually reach for.

## Status

Early implementation. Vision and design notes live in [`docs/vision.md`](docs/vision.md), the production roadmap lives in [`docs/production-roadmap.md`](docs/production-roadmap.md), and execution state lives in [`.planning/`](.planning/). The repo now has a reproducible XcodeGen scaffold and blank macOS app.

## What makes it different

- **Native, not Electron.** Swift + Metal. Targets: <100MB resident RAM, <500ms cold start, 120fps on ProMotion (vs ~500MB / ~5s for eDEX-UI).
- **Per-machine procedural visual signature.** Every install has a unique aesthetic mathematically derived from machine ID — your gridOS looks different from anyone else's.
- **LLM-integrated terminal.** Command palette with Claude baked in.
- **Real macOS integration.** Menu bar widget, Notification Center, Quick Look, Stage Manager — first-class citizen, not a port.
- **Aesthetic modes**, not one style: Tron, Severance, Cyberpunk, Matrix, Apple-native. Hotkey to switch.

## Planned stack

- Swift / SwiftUI with AppKit interop where needed
- Metal shaders for the visual identity layer
- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) as a starting point for the terminal backend (TBD whether to keep or replace with a GPU-accelerated custom renderer)
- Xcode 16+, macOS 14+ minimum target

## Development

Requires a Mac with Apple Silicon, Xcode, and XcodeGen.

```sh
xcodegen generate
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build test
```

Open `gridOS.xcodeproj` in Xcode after generating it.

## Relationship to eDEX-UI

gridOS is a from-scratch native rewrite *inspired by* eDEX-UI, not a fork of its code. Credit and inspiration to [@GitSquared](https://github.com/GitSquared) and the eDEX-UI project. License for this project is TBD.
