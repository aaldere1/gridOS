# Signed artifact UAT

| Field | Value |
| --- | --- |
| Timestamp UTC | 2026-05-21T15:45:00Z |
| Artifact | `gridOS-0.1.0-1-69e8518.zip` |
| Source commit | `69e8518` |
| Overall result | PASS |

## Signed app terminal probes

| Check | Result | Sanitized evidence |
| --- | --- | --- |
| Launch | PASS | Archived signed app opened with one live shell child and no beach ball. |
| Keyboard input | PASS | Deterministic marker content `ALPHA_KEYBOARD_OK` was written through typed terminal input. |
| Paste | PASS | Deterministic marker content `ALPHA_PASTE_OK` was written through the Terminal Paste command after command focus was active. |
| Select/copy | PASS | A throwaway visible marker copied from the terminal appeared in the scratch clipboard. |
| Clear | PASS | Terminal > Clear remained enabled and the pane accepted a follow-up marker command. |
| Reset | PASS | Terminal > Reset remained enabled and the pane accepted a follow-up marker command. |
| Split right | PASS | Child shell count changed from 1 to 2. |
| Split down | PASS | Child shell count changed from 2 to 3. |
| Close pane | PASS | Child shell count returned from 3 to 2; session JSON recorded 2 panes and a valid active pane. |
| Quit cleanup | PASS | Signed app quit left 0 child shell processes. |
| Relaunch restore | PASS | Two-pane session relaunched as two fresh shell children, then quit left 0 child shell processes. |

## Helper and source-backed checks

| Check | Result | Sanitized evidence |
| --- | --- | --- |
| Command availability | PASS | `alpha-uat-summary.md` records `vim`, `less`, `top`, `tmux`, `ssh`, and fast-output checks as PASS. |
| Command Intelligence no-key copy | PASS | `CommandIntelligenceFailureTests` covers no-provider-key product copy and Settings recovery action. |
| High-risk insert-only behavior | PASS | `CommandRiskClassifierTests` and `CommandIntelligenceFlowTests` cover high-risk and unknown commands as insert-only. |
| Notification opt-in | PASS | Settings source and integration tests keep notifications off by default and permission request behind `Enable Notifications`. |
| Menu bar paused for Alpha | PASS | `GridOSApp` keeps `MenuBarExtra` out of the Alpha scene graph; signed launch probe opened normally. |
| Spotlight metadata privacy | PASS | `WorkspaceMetadataIndexerTests` verify basename/metadata-only indexing and app preferences keep indexing opt-in. |

## Privacy

This evidence records pass/fail outcomes, source commit, artifact basename, synthetic marker names, and process counts only. It does not include terminal transcripts, shell history, raw command output, environment variables, API keys, prompts, generated commands, provider responses, screenshots, traces, private paths, or build artifacts.
