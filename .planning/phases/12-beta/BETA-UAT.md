# Phase 12 Beta UAT

## Build Under Test

| Field | Value |
| --- | --- |
| Artifact basename | BLOCKED - no notarized Beta artifact |
| Source commit | 373110e |
| SHA-256 | BLOCKED - no notarized Beta artifact |
| Notarization | BLOCKED - `BETA_NOTARIZATION_BLOCKED` |
| Gatekeeper assessment | BLOCKED - no notarized/quarantined artifact |
| Tester | Codex release gate |
| Date | 2026-05-21 |
| Overall result | BLOCKED |

## Clean Mac Gatekeeper UAT

| Check | Command or step | Result | Notes |
| --- | --- | --- | --- |
| Artifact checksum | `shasum -a 256 path/to/gridOS-beta.dmg` matches `.planning/phases/12-beta/beta-release-manifest.json`. | BLOCKED | No notarized Beta artifact exists because notary credential mode is missing. |
| Stapled ticket | `xcrun stapler validate path/to/gridOS-beta.dmg` exits 0. | BLOCKED | `BETA_NOTARIZATION_BLOCKED` prevents stapling. |
| Gatekeeper assessment | `spctl --assess --type execute --verbose=4 path/to/gridOS.app` exits 0. | BLOCKED | No notarized/quarantined artifact is available. |
| DMG open/copy | Open the DMG and copy `gridOS.app` to the tester Applications folder. | BLOCKED | No notarized DMG is available. |
| Finder launch | Launch `gridOS.app` from Finder with Gatekeeper enabled. | BLOCKED | No notarized/quarantined artifact is available. |
| First-run privacy | Confirm the Beta privacy disclosure appears before normal use. | SOURCE PASS | Source/tests verify the disclosure; clean-Mac launch is blocked. |
| Command Intelligence no-key state | Confirm the app remains useful without a provider key. | SOURCE PASS | Existing tests keep no-key behavior productized; clean-Mac launch is blocked. |
| Diagnostics review | Confirm diagnostics are local, sanitized, and user-reviewed. | SOURCE PASS | Docs/source prohibit telemetry and automatic diagnostics upload. |

## Update from Beta N to Beta N+1

| Check | Step | Result | Notes |
| --- | --- | --- | --- |
| Quit current Beta | Quit the installed Beta N app. | BLOCKED | No notarized Beta N/N+1 pair exists. |
| Verify Beta N+1 checksum | Compare `shasum -a 256` output to the Beta N+1 manifest. | BLOCKED | No notarized Beta N+1 artifact exists. |
| Replace app | Open the Beta N+1 DMG and replace the installed app. | BLOCKED | No notarized Beta N+1 artifact exists. |
| Launch updated app | Launch from Finder and confirm version/build metadata. | BLOCKED | No notarized Beta N+1 artifact exists. |
| Rollback | Replace with previous verified Beta if update fails. | BLOCKED | No notarized Beta pair exists. |

## Feedback Submission

| Check | Step | Result | Notes |
| --- | --- | --- | --- |
| Feedback template | Use `.planning/phases/12-beta/BETA-FEEDBACK.md`. | PASS | Include only sanitized details. |
| Known issues | Promote confirmed issues to `.planning/phases/12-beta/KNOWN-ISSUES.md`. | PASS | `BETA-001` tracks the notary credential blocker. |

## Privacy Rules

Do not commit or send shell history, terminal transcripts, raw command output,
environment variables, API keys, prompts, generated commands, provider
responses, screenshots with secrets, traces, private file paths, or build
artifacts.
