# Phase 12 Beta UAT

## Build Under Test

| Field | Value |
| --- | --- |
| Artifact basename | pending |
| Source commit | pending |
| SHA-256 | pending |
| Notarization | pending |
| Gatekeeper assessment | pending |
| Tester | pending |
| Date | pending |
| Overall result | pending |

## Clean Mac Gatekeeper UAT

| Check | Command or step | Result | Notes |
| --- | --- | --- | --- |
| Artifact checksum | `shasum -a 256 path/to/gridOS-beta.dmg` matches `.planning/phases/12-beta/beta-release-manifest.json`. | pending | Do not continue if checksum differs. |
| Stapled ticket | `xcrun stapler validate path/to/gridOS-beta.dmg` exits 0. | pending | For ZIP distribution, validate the extracted app bundle instead. |
| Gatekeeper assessment | `spctl --assess --type execute --verbose=4 path/to/gridOS.app` exits 0. | pending | Use the app from the downloaded/quarantined artifact. |
| DMG open/copy | Open the DMG and copy `gridOS.app` to the tester Applications folder. | pending | Do not use artifacts from `.planning`. |
| Finder launch | Launch `gridOS.app` from Finder with Gatekeeper enabled. | pending | Do not bypass Gatekeeper. |
| First-run privacy | Confirm the Beta privacy disclosure appears before normal use. | pending | Verify the disclosure facts from `12-UI-SPEC.md`. |
| Command Intelligence no-key state | Confirm the app remains useful without a provider key. | pending | No network request without explicit preview/send. |
| Diagnostics review | Confirm diagnostics are local, sanitized, and user-reviewed. | pending | No telemetry or automatic upload. |

## Update from Beta N to Beta N+1

| Check | Step | Result | Notes |
| --- | --- | --- | --- |
| Quit current Beta | Quit the installed Beta N app. | pending | Confirm no gridOS process remains. |
| Verify Beta N+1 checksum | Compare `shasum -a 256` output to the Beta N+1 manifest. | pending | Must match before replacement. |
| Replace app | Open the Beta N+1 DMG and replace the installed app. | pending | Use normal Finder flow. |
| Launch updated app | Launch from Finder and confirm version/build metadata. | pending | Record version/build. |
| Rollback | Replace with previous verified Beta if update fails. | pending | Record rollback result and reason. |

## Feedback Submission

| Check | Step | Result | Notes |
| --- | --- | --- | --- |
| Feedback template | Use `.planning/phases/12-beta/BETA-FEEDBACK.md` once available. | pending | Include only sanitized details. |
| Known issues | Promote confirmed issues to `.planning/phases/12-beta/KNOWN-ISSUES.md`. | pending | Mark Beta blocker and Production blocker status. |

## Privacy Rules

Do not commit or send shell history, terminal transcripts, raw command output,
environment variables, API keys, prompts, generated commands, provider
responses, screenshots with secrets, traces, private file paths, or build
artifacts.
