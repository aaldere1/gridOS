# gridOS security and privacy posture

gridOS is a terminal, system monitor, and optional LLM-assisted command surface. That combination requires conservative defaults.

## Current stance

- No telemetry by default.
- No LLM network request without explicit user action.
- No shell history, selected output, command context, or API key should be logged by default.
- Provider API keys use Keychain-backed generic-password items.
- The visual install seed is a local non-secret app preference in this release. It is not a machine identifier, is not transmitted, and should move to Keychain/HMAC before being described as an install identity secret.
- Generated command execution must be gated, with stronger confirmation for destructive commands.

Phase 10 source-of-truth documents:

- `docs/security-threat-model.md` — current-app assets, trust boundaries, abuse cases, mitigations, and verification gates.
- `docs/privacy-data-inventory.md` — stored, sent, indexed, notified, displayed, and evidence-captured data classes.

## Procedural identity

The visual identity system must not expose raw machine identifiers. Version 1.0.3 generates a local random install seed in app preferences for procedural appearance only; it does not read, store, or transmit a hardware identifier.

Recommended future implementation:

1. Generate an install secret at first launch.
2. Store it in Keychain or an app-container equivalent.
3. Derive visual seeds with HMAC using a versioned salt.
4. Provide a reset/regenerate identity action.
5. Never transmit the seed or raw machine traits.

## LLM context policy

LLM features are opt-in per action.

Before sending context, the app should show or summarize:

- working directory
- recent command text, if included
- selected terminal output, if included
- git state, if included
- redactions applied

The user must be able to cancel before any request is sent.

## Command safety

Generated commands should default to insert-only until the user chooses to run them.

High-risk examples:

- destructive filesystem operations
- credential or keychain operations
- package manager install scripts
- network transfer piped into shell
- privilege escalation
- process killing

High-risk commands require an explicit confirmation path that is visually distinct from normal run.

## Distribution posture

Direct distribution is the production path until App Store sandboxing is product-ready:

- Developer ID signed
- Hardened runtime enabled
- Notarized
- Gatekeeper-tested from a downloaded or quarantined artifact

Mac App Store readiness is now tracked separately in
`docs/app-store-readiness.md`. App Store sandbox and network-client entitlements
are staged, but they are not applied to the default direct Developer ID Beta
target. The remaining App Store product decision is whether gridOS stays a
sandbox-local command workspace or adds user-selected project folder access with
security-scoped bookmarks.

## Beta feedback and diagnostics

Phase 12 Beta feedback uses `.planning/phases/12-beta/BETA-FEEDBACK.md`.
Reports must be sanitized before sharing or committing. Do not include shell
history, terminal transcripts, raw command output, environment variables, API
keys, prompts, generated commands, provider responses, screenshots with secrets,
or private file paths.

No telemetry, crash upload, or automatic diagnostics upload is added in Phase 12.

## Open security tasks

- Keep the Phase 10 threat model and privacy data inventory current as implementation changes.
- Add and maintain redaction tests with realistic shell output.
- Maintain Keychain tests.
- Review every dependency license and update policy.
- Define diagnostics export format before collecting support bundles.
- Move the visual install seed to a Keychain/HMAC design before claiming stronger install-identity properties.
