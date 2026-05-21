# Phase 11: Alpha - Research

## Research Goal

Answer: what do we need to know to plan internal alpha validation well?

Phase 11 is a release-readiness bridge. It should produce a signed internal build path, daily-driver validation evidence, and a known-issues loop without prematurely taking on public beta distribution.

## Current App Baseline

- Phase 10 verification passed with 11/11 security/privacy must-haves verified.
- `project.yml` is the authoritative build configuration and already sets `ENABLE_HARDENED_RUNTIME: YES` on the app target.
- `DEVELOPMENT_TEAM` is currently an empty string in `project.yml`, so signing must be parameterized through local environment or documented as a blocker.
- Full unsigned local verification works with:
  - `xcodegen generate --use-cache`
  - `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- There is no committed release script, alpha artifact manifest, known-issues tracker, or alpha UAT checklist yet.

## Apple Distribution Findings

Official Apple documentation supports these planning assumptions:

- Developer ID is the intended signing path for Mac software distributed outside the Mac App Store.
- Notarization gives users confidence that Developer ID-signed software has been checked by Apple for malicious content.
- Apple’s notary service requires hardened runtime for notarized macOS software.
- Apple documentation also notes `notarytool` is the current CLI path; `altool` uploads are no longer accepted.
- For Phase 11, this means: preserve hardened-runtime compatibility and record signing preflight evidence, but defer notarization, stapling, and Gatekeeper clean-install proof to Phase 12 unless the user wants public beta work pulled forward.

## Alpha Build Strategy

Recommended Alpha build lane:

1. Keep unsigned build/test as the always-runnable baseline.
2. Add a signing preflight that checks for signing identities, `DEVELOPMENT_TEAM`, bundle ID, hardened runtime, and Xcode version without echoing secrets.
3. Add a script that can produce an internal alpha archive/package when `GRIDOS_DEVELOPMENT_TEAM` and `GRIDOS_SIGNING_IDENTITY` are present.
4. Add a verification script that records `codesign` verification, Info.plist version/build metadata, artifact SHA-256, and whether notarization was intentionally skipped.
5. Store build products outside git; commit sanitized manifests/evidence only.

## Daily-Driver UAT Strategy

Alpha acceptance is mostly behavior and evidence, not new feature breadth.

Core workflows to test:

- Launch and use the default shell for a real work session.
- Type, paste, select, copy, clear, reset, split panes, close panes, quit, and relaunch.
- Validate common terminal tools: `vim`, `less`, `top`, `tmux`, `ssh -V`, and fast output.
- Confirm session restore restores layout/directories only, not running processes.
- Confirm Command Intelligence works without a provider key, redacts context, and keeps high/unknown risk insert-only.
- Confirm menu bar and notifications remain opt-in/local and do not expose private terminal output.
- Confirm Spotlight metadata indexing remains off by default and basename-only when enabled.

## Evidence Strategy

Commit:

- Text logs with timestamps, command names, pass/fail, and sanitized paths.
- Artifact manifests and checksums.
- Known issues with severity, owner, blocker status, and target phase.
- UAT signoff report with explicit residual risks.

Do not commit:

- `.app`, `.xcarchive`, `.dmg`, `.zip`, `.pkg`, `.trace`, screenshots, raw terminal output, shell history, environment dumps, API keys, prompts, generated commands, or user-specific paths.

## Validation Architecture

Use Xcode/XCTest plus shell verification:

- Fast gate: `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test`
- Full baseline: `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- Signing preflight: `scripts/alpha-signing-preflight.sh`
- Artifact verification: `scripts/verify-alpha-artifact.sh <path-to-app-or-archive>`
- UAT evidence scan: `rg 'Alpha UAT|Terminal correctness|Known issues|codesign --verify|Phase 11 alpha' .planning/phases/11-alpha docs scripts Sources Tests`
- Privacy scan: `! rg 'shellHistory|terminalTranscript|environmentVariables|apiKey.*AppStorage|UserDefaults.*api|commandOutput|selectedOutput.*write|prompt.*write|\\.app|\\.xcarchive|\\.dmg|\\.zip|\\.trace|\\.png' .planning/phases/11-alpha/evidence docs scripts Sources Tests`

## Planning Implications

- Plans should separate preflight, build pipeline, UAT execution, feedback/diagnostics, and final signoff.
- Signing absence should be a first-class blocker with evidence, not a vague failure.
- Alpha signoff should not claim beta readiness or public distribution.
- Every plan needs a clean automated gate plus manual UAT where interaction is genuinely required.

## Open Risks

- Local machine may not have an Apple Developer signing identity or team configured.
- A signed internal app may expose hardened-runtime issues that unsigned build/test does not.
- Terminal daily-driver UAT can reveal interactive issues not covered by unit tests.
- Phase 9 performance misses remain known risks; Alpha can proceed only if they do not block daily internal use.
