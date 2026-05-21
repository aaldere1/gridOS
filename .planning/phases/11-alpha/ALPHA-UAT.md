# Phase 11 Alpha UAT

## Build Under Test

| Field | Value |
| --- | --- |
| Build identifier |  |
| Source commit |  |
| Artifact verification |  |
| Tester |  |
| Date |  |
| Overall result |  |

Use the signed internal Alpha artifact when signing prerequisites are present. If signing is blocked, record `SIGNING_BLOCKED` and use the unsigned Debug build only for terminal correctness investigation.

## Terminal correctness

| Check | Steps | Result | Notes |
| --- | --- | --- | --- |
| Shell launch | Launch gridOS and confirm the default shell prompt appears. |  |  |
| Keyboard input | Type `printf 'alpha keyboard ok\n'` and press Return. |  |  |
| Paste | Paste a short safe command into the active pane. |  |  |
| Select/copy | Select visible terminal text and copy it to a temporary scratch buffer outside the repo. |  |  |
| Clear | Use Terminal > Clear or Command-Option-K and confirm the active pane clears. |  |  |
| Reset | Use Terminal > Reset or Command-Option-R and confirm the active pane remains usable. |  |  |
| `vim --version` | Run `vim --version` and confirm the command completes. |  |  |
| `less --version` | Run `less --version` and confirm the command completes. |  |  |
| `top -l 1 -n 0` | Run `top -l 1 -n 0` and confirm the command completes without freezing the pane. |  |  |
| `tmux -V` | Run `tmux -V` and confirm the command completes. |  |  |
| `ssh -V` | Run `ssh -V` and confirm the command completes. |  |  |
| Fast output | Run a safe loop that prints at least 1000 lines and confirm scrolling/input recover. |  |  |

## Multi-pane and restore

| Check | Steps | Result | Notes |
| --- | --- | --- | --- |
| Split right | Use Command-D and confirm a readable right-hand pane appears. |  |  |
| Split down | Use Command-Shift-D and confirm a readable lower pane appears. |  |  |
| Close pane | Close the active pane and confirm the remaining panes stay usable. |  |  |
| Quit/relaunch restore | Quit and relaunch, then confirm layout and directories restore as fresh shells. |  |  |

## Command Intelligence

| Check | Steps | Result | Notes |
| --- | --- | --- | --- |
| No-key copy | With no provider key configured, open Command Intelligence and confirm the no-key state uses product copy and links to Settings. |  |  |
| High-risk insert-only behavior | Use the deterministic fixture or a visibly high-risk command and confirm it is inserted for review rather than run automatically. |  |  |

## macOS integrations

| Check | Steps | Result | Notes |
| --- | --- | --- | --- |
| Notification opt-in | Open Settings, choose Enable Notifications, and confirm permission is requested only after the explicit action. |  |  |
| Menu bar | Confirm the gridOS menu bar extra appears when enabled and exposes sanitized host/workspace status only. |  |  |
| Spotlight metadata privacy | Confirm workspace metadata indexing is off by default, and when enabled it uses metadata/basename-only behavior. |  |  |

## Evidence

Run the noninteractive helper for command availability and fast output summary evidence:

```sh
.planning/phases/11-alpha/run-alpha-uat.sh
```

The helper writes `.planning/phases/11-alpha/evidence/alpha-uat-summary.md`. Commit only sanitized text summaries. Do not commit screenshots, traces, raw terminal output, terminal transcripts, shell history, environment variables, API keys, prompts, generated commands, provider responses, private file paths, or build artifacts.

## Known issues

| ID | Severity | Alpha blocker | Description | Evidence |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

Critical or high-severity terminal correctness issues block Alpha signoff.

## Signoff

| Role | Name | Date | Decision | Notes |
| --- | --- | --- | --- | --- |
| Tester |  |  |  |  |
| Release owner |  |  |  |  |
