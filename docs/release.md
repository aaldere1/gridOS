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
