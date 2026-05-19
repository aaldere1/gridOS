# gridOS

A native macOS app for Apple Silicon that reimagines [eDEX-UI](https://github.com/GitSquared/edex-ui) — the Tron-esque sci-fi terminal UI — as a real Mac-first application. Where eDEX-UI was an Electron remake of the look, gridOS aims to be the tool you'd actually reach for.

## Status

Early planning. Vision and design notes in [`docs/vision.md`](docs/vision.md). No code yet — Xcode scaffolding will happen on the development Mac.

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

Requires a Mac with Apple Silicon and Xcode. Clone, open in Xcode, build. Scaffolding TBD.

## Relationship to eDEX-UI

gridOS is a from-scratch native rewrite *inspired by* eDEX-UI, not a fork of its code. Credit and inspiration to [@GitSquared](https://github.com/GitSquared) and the eDEX-UI project. License for this project is TBD.
