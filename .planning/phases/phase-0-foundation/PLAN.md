# Phase 0 plan - Product, legal, and repo foundation

## Goal

Make gridOS buildable, trackable, and safe to iterate on.

## Scope

This phase does not implement the terminal, Metal renderer, metrics panels, LLM features, or production updater. It creates the foundation those features need.

## Tasks

- [x] Create durable `.planning/` state.
- [x] Add explicit license posture.
- [x] Add XcodeGen project specification.
- [x] Add blank macOS SwiftUI app target.
- [x] Add initial shared module targets.
- [x] Generate Xcode project.
- [x] Verify local build.
- [x] Add architecture, security/privacy, and release docs.
- [x] Add CI skeleton.
- [x] Update progress state with verification evidence.

## Result

Completed on 2026-05-19.

Verification:

```sh
xcodegen generate
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build test
```

Result: passed with 2 unit tests.

## Acceptance criteria

- Fresh clone can regenerate the Xcode project.
- Blank app builds locally.
- Repo has a clear progress tracker.
- Docs explain architecture, security/privacy posture, and release expectations.
- CI has a first-pass build/test workflow ready for GitHub.

## Verification commands

```sh
xcodegen generate
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' build
git status --short
```

## Risks

- Xcode project churn if project files are hand-edited. Mitigation: keep `project.yml` authoritative.
- Signing/team settings may be environment-specific. Mitigation: use automatic signing placeholders and avoid committing local signing secrets.
- macOS app sandbox may not fit terminal behavior. Mitigation: start unsandboxed for direct distribution, document the tradeoff.
