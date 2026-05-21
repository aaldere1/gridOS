# Phase 12 Beta Feedback

Use this template for external Beta feedback. Keep reports sanitized and promote
confirmed issues to `.planning/phases/12-beta/KNOWN-ISSUES.md`.

## Report template

| Field | Entry |
| --- | --- |
| App version/build |  |
| Artifact basename |  |
| macOS version |  |
| Hardware class |  |
| Install path category |  |
| Sanitized steps |  |
| Expected result |  |
| Actual result |  |
| Blocks install | yes/no |
| Blocks launch | yes/no |
| Blocks terminal correctness | yes/no |
| Blocks Command Intelligence | yes/no |
| Blocks update flow | yes/no |
| Blocks diagnostics | yes/no |
| Linked known issue |  |

## Include

- App version/build.
- Artifact basename.
- macOS version.
- Hardware class such as Apple Silicon laptop or Apple Silicon desktop.
- Install path category such as `/Applications` or user Applications folder.
- Sanitized reproduction steps.
- Expected result and actual result.
- Whether the issue blocks install, launch, terminal correctness, Command Intelligence, update flow, or diagnostics.

## Do not include

- Shell history.
- Terminal transcripts.
- Raw command output.
- Environment variables.
- API keys.
- Prompts.
- Generated commands.
- Provider responses.
- Screenshots with secrets.
- Private file paths.

## Sanitized diagnostics

Diagnostics are local, sanitized, and user-reviewed. Do not attach automatic
diagnostics, crash uploads, shell history, terminal transcripts, raw command
output, environment variables, API keys, prompts, generated commands, provider
responses, screenshots with secrets, or private file paths.

## Triage

Promote confirmed issues to `.planning/phases/12-beta/KNOWN-ISSUES.md` with
severity, Beta blocker status, Production blocker status, owner, target phase,
status, and sanitized evidence.
