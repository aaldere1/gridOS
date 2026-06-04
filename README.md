# gridOS

gridOS is a native macOS terminal cockpit for Apple Silicon: real shell first,
local system signal around it, and a distinctive procedural visual identity that
feels like a Mac app instead of an Electron skin.

It is inspired by the cinematic idea of eDEX-UI, but it is a from-scratch Swift,
SwiftUI, AppKit, Metal, and SwiftTerm application. The goal is not nostalgia. The
goal is a terminal that is beautiful enough to want open all day and careful
enough to trust with real work.

## Current Release

- Version: `1.0.4`
- Platform: macOS 14 or newer on Apple Silicon
- Distribution lane: Developer ID signed, notarized direct-download DMG
- Release notes and verification: [`docs/production-direct-release.md`](docs/production-direct-release.md)
- Operational release checklist: [`docs/release.md`](docs/release.md)

## What Ships

- Native multi-pane terminal workspace with saved layout and recent directories.
- Open Folder command for starting work in a chosen project directory.
- Live local CPU, memory, network, battery, thermal, and process signal.
- Procedural visual modes for Tron, Severance, and Apple-native looks.
- Local launch briefing that explains privacy and command-safety defaults.
- AI Command Helper with optional Anthropic or OpenAI provider keys.
- Keychain-backed provider key storage.
- Preview-first provider requests: gridOS shows the redacted context before a request leaves the app.
- Local generated-command risk labels with insert-first behavior and explicit run confirmation.
- Polished drag-to-Applications DMG layout.

## What Does Not Ship Yet

- No telemetry.
- No automatic command execution from provider responses.
- No persisted shell history, terminal transcripts, raw prompts, provider responses, or generated commands.
- No live Spotlight indexing or notification workflow in this release surface.
- No App Store sandboxed build yet; App Store readiness is tracked separately in [`docs/app-store-readiness.md`](docs/app-store-readiness.md).

## Development

Requires Xcode and XcodeGen.

```sh
xcodegen generate --use-cache
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
```

Open `gridOS.xcodeproj` in Xcode after generating it.

## Release Build

The signed direct-download lane is driven by the release scripts under
[`scripts/`](scripts/). The release artifact must be built from a committed
source revision so the DMG, ZIP, and manifest point at a stable source commit.

```sh
GRIDOS_BETA_OUTPUT_DIR=build/release/production scripts/build-beta.sh
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/notarize-beta-artifact.sh build/release/production/gridOS-version-build-commit.dmg
scripts/verify-beta-artifact.sh build/release/production/gridOS-version-build-commit.dmg
scripts/write-beta-release-manifest.sh build/release/production/gridOS-version-build-commit.dmg
```

## License

Proprietary. See [`LICENSE`](LICENSE).
