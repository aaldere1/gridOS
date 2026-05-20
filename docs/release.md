# gridOS release process

This document starts as a release checklist and should become the operational source of truth before alpha.

## Versioning

Initial version:

- Marketing version: `0.1.0`
- Build number: `1`

Before alpha, decide whether the version source of truth lives in `project.yml`, a generated config file, or CI.

## Local build

```sh
xcodegen generate
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' build
```

For unsigned CI builds:

```sh
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build test
```

The project currently depends on SwiftTerm pinned through XcodeGen/SwiftPM. Regenerate the project after changing `project.yml` so package resolution stays in sync.

## Terminal smoke

Debug builds support a startup command for verification:

```sh
open -n path/to/gridOS.app --args --cmd 'echo ok; exit'
```

This is intended for local smoke tests of the shell bridge, not as a user-facing automation contract yet.

## Visual identity smoke

Phase 2 adds a Metal-backed background through `RenderCore.MetalBackgroundView`. The current smoke bar is:

- app launches without shader setup crashes
- startup command still reaches the shell
- shell child exits after command completion
- app quits cleanly
- app CPU returns to idle after the startup render burst

Recent local Phase 2 evidence:

```text
GRIDOS_PHASE2_SMOKE
APP_SAMPLE=0.0 106496 SN .../gridOS.app/Contents/MacOS/gridOS
```

This is not a substitute for Phase 9 performance hardening; it is only the Phase 2 guardrail that the first renderer does not obviously spin while idle.

## Production distribution target

The likely 1.0 path is direct Mac distribution:

- archive from clean checkout
- sign with Developer ID Application certificate
- enable hardened runtime
- notarize with Apple
- staple the notarization ticket where applicable
- package as DMG or ZIP
- publish checksum
- verify launch on a clean Gatekeeper-enabled Mac

## Release candidate checklist

- Clean working tree.
- Version and build number incremented.
- Tests passing.
- Performance report captured.
- Dependency licenses reviewed.
- Privacy/security checklist reviewed.
- App archived from clean checkout.
- Code signature verified.
- Notarization accepted.
- Gatekeeper launch tested from downloaded artifact.
- Update flow tested, if updater has shipped.
- Release notes written.
- Rollback/hotfix path documented.

## CI responsibilities

The initial CI skeleton should:

- install XcodeGen
- generate the Xcode project
- build the app with signing disabled
- run unit tests

Release signing and notarization should remain manual or protected until credentials and branch protections are ready.
