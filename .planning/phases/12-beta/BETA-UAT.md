# Phase 12 Beta UAT

## Build Under Test

| Field | Value |
| --- | --- |
| Artifact basename | `gridOS-0.1.0-6-e1c7005.dmg` |
| Source commit | `e1c7005` |
| SHA-256 | `fc4e353604f7b5195678fc86320633a4918955146db7429146133f8be495879d` |
| Notarization | PASS |
| Gatekeeper assessment | LOCAL PASS; clean-Mac Finder launch pending |
| Tester | Codex release gate |
| Date | 2026-06-03 |
| Overall result | LOCAL PASS; EXTERNAL CLEAN-MAC BLOCKED |

## Clean Mac Gatekeeper UAT

| Check | Command or step | Result | Notes |
| --- | --- | --- | --- |
| Artifact checksum | `shasum -a 256 path/to/gridOS-beta.dmg` matches `.planning/phases/12-beta/beta-release-manifest.json`. | PASS | Release manifest records SHA-256 `fc4e353604f7b5195678fc86320633a4918955146db7429146133f8be495879d`. |
| Stapled ticket | `xcrun stapler validate path/to/gridOS-beta.dmg` exits 0. | PASS | `.planning/phases/12-beta/evidence/beta-notarization.md` records stapler validate PASS. |
| Gatekeeper assessment | `spctl --assess --type execute --verbose=4 path/to/gridOS.app` exits 0. | LOCAL PASS | `.planning/phases/12-beta/evidence/beta-artifact-verification.md` records local Gatekeeper PASS. |
| DMG open/copy | Open the DMG and copy `gridOS.app` to the tester Applications folder. | BLOCKED | Requires separate clean-Mac Finder UAT. |
| Finder launch | Launch `gridOS.app` from Finder with Gatekeeper enabled. | BLOCKED | Requires separate clean-Mac Finder UAT. |
| First-run privacy | Confirm the Beta privacy disclosure appears before normal use. | SOURCE PASS | Source/tests verify the disclosure; clean-Mac launch is still pending. |
| Command Intelligence no-key state | Confirm the app remains useful without a provider key. | SOURCE PASS | Existing tests keep no-key behavior productized; clean-Mac launch is blocked. |
| Diagnostics review | Confirm diagnostics are local, sanitized, and user-reviewed. | SOURCE PASS | Docs/source prohibit telemetry and automatic diagnostics upload. |
| Local packaged launch smoke | Launch the mounted notarized DMG with a deterministic startup marker, then quit and detach. | PASS | `.planning/phases/12-beta/evidence/local-notarized-launch-smoke.md` records build 6 local launch smoke PASS. |

## Update from Beta N to Beta N+1

| Check | Step | Result | Notes |
| --- | --- | --- | --- |
| Quit current Beta | Quit the installed Beta N app. | BLOCKED | Update-flow evidence is not yet recorded on a clean-Mac environment. |
| Verify Beta N+1 checksum | Compare `shasum -a 256` output to the Beta N+1 manifest. | BLOCKED | `BETA_UPDATE_FLOW_BLOCKED update_flow_record_not_available_clean_mac`. |
| Replace app | Open the Beta N+1 DMG and replace the installed app. | BLOCKED | Update-flow evidence is not yet recorded on a clean-Mac environment. |
| Launch updated app | Launch from Finder and confirm version/build metadata. | BLOCKED | Update-flow evidence is not yet recorded on a clean-Mac environment. |
| Rollback | Replace with previous verified Beta if update fails. | BLOCKED | Update-flow evidence is not yet recorded on a clean-Mac environment. |

## Feedback Submission

| Check | Step | Result | Notes |
| --- | --- | --- | --- |
| Feedback template | Use `.planning/phases/12-beta/BETA-FEEDBACK.md`. | PASS | Include only sanitized details. |
| Known issues | Promote confirmed issues to `.planning/phases/12-beta/KNOWN-ISSUES.md`. | PASS | `BETA-001` is resolved; `BETA-002` and `BETA-003` track remaining Beta blockers. |

## Privacy Rules

Do not commit or send shell history, terminal transcripts, raw command output,
environment variables, API keys, prompts, generated commands, provider
responses, screenshots with secrets, traces, private file paths, or build
artifacts.
