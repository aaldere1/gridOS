# Phase 11 Alpha UAT Summary

| Field | Value |
| --- | --- |
| Generated | 2026-05-21T13:33:17Z |
| Source commit | 88ee8d0 |
| Overall result | PASS |
| Checks | 6 total, 0 failed |

## Noninteractive Checks

| Check | Command | Result |
| --- | --- | --- |
| vim availability | `vim --version` | PASS |
| less availability | `less --version` | PASS |
| top availability | `top -l 1 -n 0` | PASS |
| tmux availability | `tmux -V` | PASS |
| ssh availability | `ssh -V` | PASS |
| fast output | `1000 sanitized lines to /dev/null` | PASS |

## Privacy

This summary records command names and PASS/FAIL status only. It does not capture terminal transcripts, shell history, raw command output, environment variables, API keys, prompts, generated commands, provider responses, screenshots, traces, or private file paths.
