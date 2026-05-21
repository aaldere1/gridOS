# Phase 11 Alpha UAT

## Build Under Test

| Field | Value |
| --- | --- |
| Build identifier | `gridOS-0.1.0-1-69e8518.zip` |
| Source commit | `69e8518` |
| Artifact verification | PASS - `evidence/alpha-artifact-verification.md` |
| Tester | Codex signed-app UAT |
| Date | 2026-05-21 |
| Overall result | PASS |

Use the signed internal Alpha artifact when signing prerequisites are present. If signing is blocked, record `SIGNING_BLOCKED` and use the unsigned Debug build only for terminal correctness investigation.

## Feedback loop

Record raw internal tester observations in `ALPHA-FEEDBACK.md`, then promote confirmed items to `KNOWN-ISSUES.md` with severity, blocker status, owner, target phase, status, and sanitized evidence. Critical/high terminal correctness issues block Alpha signoff.

## Terminal correctness

| Check | Steps | Result | Notes |
| --- | --- | --- | --- |
| Shell launch | Launch gridOS and confirm the default shell prompt appears. | PASS | Signed app opened with one live shell child and no beach ball. |
| Keyboard input | Type `printf 'alpha keyboard ok\n'` and press Return. | PASS | Synthetic marker written through typed terminal input. |
| Paste | Paste a short safe command into the active pane. | PASS | Synthetic marker written through Terminal > Paste once command focus was active. |
| Select/copy | Select visible terminal text and copy it to a temporary scratch buffer outside the repo. | PASS | Throwaway visible marker copied to scratch clipboard. |
| Clear | Use Terminal > Clear or Command-Option-K and confirm the active pane clears. | PASS | Pane accepted a follow-up marker command after Clear. |
| Reset | Use Terminal > Reset or Command-Option-R and confirm the active pane remains usable. | PASS | Pane accepted a follow-up marker command after Reset. |
| `vim --version` | Run `vim --version` and confirm the command completes. | PASS | `evidence/alpha-uat-summary.md` |
| `less --version` | Run `less --version` and confirm the command completes. | PASS | `evidence/alpha-uat-summary.md` |
| `top -l 1 -n 0` | Run `top -l 1 -n 0` and confirm the command completes without freezing the pane. | PASS | `evidence/alpha-uat-summary.md` |
| `tmux -V` | Run `tmux -V` and confirm the command completes. | PASS | `evidence/alpha-uat-summary.md` |
| `ssh -V` | Run `ssh -V` and confirm the command completes. | PASS | `evidence/alpha-uat-summary.md` |
| Fast output | Run a safe loop that prints at least 1000 lines and confirm scrolling/input recover. | PASS | `evidence/alpha-uat-summary.md` |

## Multi-pane and restore

| Check | Steps | Result | Notes |
| --- | --- | --- | --- |
| Split right | Use Command-D and confirm a readable right-hand pane appears. | PASS | Signed app child shell count changed 1 to 2. |
| Split down | Use Command-Shift-D and confirm a readable lower pane appears. | PASS | Signed app child shell count changed 2 to 3. |
| Close pane | Close the active pane and confirm the remaining panes stay usable. | PASS | Child shell count returned 3 to 2; session JSON recorded 2 panes. |
| Quit/relaunch restore | Quit and relaunch, then confirm layout and directories restore as fresh shells. | PASS | Two-pane session relaunched as 2 fresh shell children; quit cleanup left 0 children. |

## Command Intelligence

| Check | Steps | Result | Notes |
| --- | --- | --- | --- |
| No-key copy | With no provider key configured, open Command Intelligence and confirm the no-key state uses product copy and links to Settings. | PASS | Covered by `CommandIntelligenceFailureTests` and full `xcodebuild ... test`. |
| High-risk insert-only behavior | Use the deterministic fixture or a visibly high-risk command and confirm it is inserted for review rather than run automatically. | PASS | Covered by `CommandRiskClassifierTests`, `CommandIntelligenceFlowTests`, and full `xcodebuild ... test`. |

## macOS integrations

| Check | Steps | Result | Notes |
| --- | --- | --- | --- |
| Notification opt-in | Open Settings, choose Enable Notifications, and confirm permission is requested only after the explicit action. | PASS | Settings source and integration tests keep notifications off by default and permission request behind explicit action. |
| Menu bar paused for Alpha | Confirm the signed app launches without a beach ball and no gridOS menu bar extra appears by default. | PASS | MenuBarExtra is disabled for Alpha after ALPHA-004; signed launch succeeded without the status-item scene. |
| Spotlight metadata privacy | Confirm workspace metadata indexing is off by default, and when enabled it uses metadata/basename-only behavior. | PASS | Workspace metadata indexing remains opt-in and basename/metadata-only in source/tests. |

## Evidence

Run the noninteractive helper for command availability and fast output summary evidence:

```sh
.planning/phases/11-alpha/run-alpha-uat.sh
```

The helper writes `.planning/phases/11-alpha/evidence/alpha-uat-summary.md`. Commit only sanitized text summaries. Do not commit screenshots, traces, raw terminal output, terminal transcripts, shell history, environment variables, API keys, prompts, generated commands, provider responses, private file paths, or build artifacts.

## Known issues

Use `KNOWN-ISSUES.md` as the durable issue tracker. The table below is only a quick UAT signoff snapshot for issues discovered during this checklist.

| ID | Severity | Alpha blocker | Description | Evidence |
| --- | --- | --- | --- | --- |
| ALPHA-005 | high | no | Multi-pane signed UAT initially spawned duplicate shell children during split/close. | Resolved by `69e8518`; `evidence/signed-artifact-uat.md`. |

Critical or high-severity terminal correctness issues block Alpha signoff.

## Signoff

| Role | Name | Date | Decision | Notes |
| --- | --- | --- | --- | --- |
| Tester | Codex signed-app UAT | 2026-05-21 | PASS | Signed artifact `gridOS-0.1.0-1-69e8518.zip`. |
| Release owner | Codex Phase 11 verification | 2026-05-21 | PASS | Alpha is ready to hand off to Phase 12 Beta. |
