# gridOS Dependency and License Review

## Direct Dependencies

- `SwiftTerm` is the only external Swift package declared in `project.yml`, sourced from `https://github.com/migueldeicaza/SwiftTerm.git` with a minimum version of `1.13.0`.
- Apple SDK frameworks are platform dependencies used through the macOS SDK, including SwiftUI, AppKit, Metal, Security, Core Spotlight, and User Notifications.
- XcodeGen is project-generation tooling. `project.yml` remains the source of truth for package, target, build-setting, and test-target structure.
- No provider SDK is currently vendored for command intelligence. The Anthropic adapter uses Foundation networking directly.

## License Posture

The current `LICENSE` is proprietary private-alpha only. It grants no public copying, modification, distribution, sublicense, or use rights without written permission from the copyright holder.

Before public source release, external beta distribution, or any marketplace packaging, the license posture needs an explicit legal/product decision and a dependency attribution bundle.

## Vulnerability Review

Current Phase 10 review is based on local project metadata:

- `project.yml` declares one external Swift package, `SwiftTerm`.
- SwiftPM resolves Apple-hosted package metadata through the generated Xcode project.
- The app does not vendor downloaded binaries, provider SDKs, plugins, Electron assets, or custom updater frameworks.
- Security-sensitive app paths are covered by focused tests for Keychain storage, LLM redaction, approved provider payloads, command-risk policy, workspace persistence, Spotlight metadata, and notifications.

Follow-up before beta should include a fresh upstream review of `SwiftTerm`, package-resolution lock/evidence, and a documented response path for future dependency advisories.

## eDEX-UI Inspiration Boundary

gridOS is a from-scratch native macOS app inspired by eDEX-UI. The project does not copy eDEX-UI code, assets, exact themes, sounds, layouts, or implementation details.

The boundary is intentionally conservative because eDEX-UI is GPL-3.0 licensed and archived. Inspiration and credit are acceptable; copied implementation material is not part of the current codebase or release posture.

## Hardened Runtime

`project.yml` sets `ENABLE_HARDENED_RUNTIME: YES` on the `gridOS` app target.

Phase 10 build/test verification keeps this setting in the generated Xcode project while running with `CODE_SIGNING_ALLOWED=NO` for local automation. No hardened-runtime entitlement exceptions are currently declared or required by the checked-in app configuration.

Production signing, notarization, stapling, Gatekeeper clean-install testing, and any entitlement exception review remain Phase 11/12 release-candidate work.

## Follow-Up Before Beta

- Pin and record resolved external package revisions in release evidence.
- Review `SwiftTerm` upstream license and security posture at beta branch cut.
- Add dependency attribution/notice material to packaged builds if distribution scope requires it.
- Re-run hardened-runtime checks on a signed Developer ID build.
- Keep eDEX-UI references as attribution and inspiration only; do not import GPL-licensed code/assets/themes unless the product license strategy changes.
