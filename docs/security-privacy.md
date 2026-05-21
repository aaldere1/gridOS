# gridOS security and privacy posture

gridOS is a terminal, system monitor, and optional LLM-assisted command surface. That combination requires conservative defaults.

## Current stance

- No telemetry by default.
- No LLM network request without explicit user action.
- No shell history, selected output, command context, or API key should be logged by default.
- API keys and install identity secrets must use Keychain once implemented.
- Generated command execution must be gated, with stronger confirmation for destructive commands.

Phase 10 source-of-truth documents:

- `docs/security-threat-model.md` — current-app assets, trust boundaries, abuse cases, mitigations, and verification gates.
- `docs/privacy-data-inventory.md` — stored, sent, indexed, notified, displayed, and evidence-captured data classes.

## Procedural identity

The visual identity system must not expose raw machine identifiers.

Recommended implementation:

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

Direct distribution is the initial recommendation:

- Developer ID signed
- Hardened runtime enabled
- Notarized
- Gatekeeper-tested from a quarantined download

Mac App Store distribution remains a later evaluation because sandboxing may interfere with expected terminal and system-monitor behavior.

## Open security tasks

- Keep the Phase 10 threat model and privacy data inventory current as implementation changes.
- Add and maintain redaction tests with realistic shell output.
- Maintain Keychain tests.
- Review every dependency license and update policy.
- Define diagnostics export format before collecting support bundles.
