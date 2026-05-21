# Phase 11 alpha evidence

This directory records sanitized text evidence for the internal Alpha lane. It is not a build-output directory and must not contain private terminal data.

## Signing preflight

Run `scripts/alpha-signing-preflight.sh --dry-run` for local smoke, then run `scripts/alpha-signing-preflight.sh` when evidence should be written. The report is presence-only: it may state whether Xcode tools, hardened runtime, signing identities, `GRIDOS_DEVELOPMENT_TEAM`, `GRIDOS_SIGNING_IDENTITY`, and optional `GRIDOS_EXPORT_METHOD` are present, but it must not echo signing variable values or raw Keychain output.

If local Apple signing configuration is missing, record the blocker as `SIGNING_BLOCKED` with the missing variable names only. Missing signing inputs are an Alpha blocker for signed internal artifacts, not a generic build failure.

## Artifact verification

Future Alpha artifact verification must record sanitized codesign status, version/build metadata, checksum status, and whether notarization was intentionally deferred. Build products stay outside git.

No artifacts committed: .app, .xcarchive, .dmg, .zip, .pkg, .trace, and screenshots stay out of source control.

## Daily-driver UAT

Daily-driver evidence must summarize pass/fail status for terminal startup, keyboard input, paste, selection/copy, fast output, `vim`, `less`, `top`, `tmux`, `ssh -V`, multi-pane split/close/restore, Command Intelligence no-key behavior, risky-command insert-only behavior, menu bar behavior, notification opt-in behavior, and Spotlight privacy defaults.

Evidence should describe outcomes and blockers without terminal transcripts, screenshots, raw command output, shell history, prompts, generated commands, environment variables, API keys, traces, or user-specific paths.

## Known issues

Known issues must include severity, owner, target phase, blocker status, and current disposition. The issue list should distinguish Alpha blockers, Beta blockers, production blockers, and non-blocking follow-ups.

## Blocker policy

Alpha cannot be marked complete with a high-severity terminal correctness blocker. Terminal correctness includes shell startup, input, paste, output rendering, TUI usability, pane routing, close/quit process cleanup, and relaunch behavior.

Signing absence is recorded as `SIGNING_BLOCKED`. A signed artifact may remain blocked if local Apple signing prerequisites are unavailable, but that status must be explicit in Alpha evidence and follow-up planning.

## Privacy boundaries

Committed evidence must be text-only and sanitized. Build products stay outside git.

Diagnostics and evidence must exclude shell history, terminal transcripts, environment variables, API keys, prompts, generated commands, raw terminal output, screenshots, traces, user-specific paths, private certificates, private keys, raw Keychain output, and full local filesystem paths.
