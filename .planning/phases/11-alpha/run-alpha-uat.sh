#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/evidence"
SUMMARY_PATH="$EVIDENCE_DIR/alpha-uat-summary.md"

mkdir -p "$EVIDENCE_DIR"

TOTAL_CHECKS=0
FAILED_CHECKS=0
CHECK_ROWS=""

append_row() {
  local name="$1"
  local command_label="$2"
  local result="$3"
  CHECK_ROWS="${CHECK_ROWS}| ${name} | \`${command_label}\` | ${result} |\n"
}

run_quiet_check() {
  local name="$1"
  local command_label="$2"
  shift 2

  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  if "$@" >/dev/null 2>&1; then
    append_row "$name" "$command_label" "PASS"
  else
    append_row "$name" "$command_label" "FAIL"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi
}

run_fast_output_check() {
  local line_count=1000

  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  if awk -v limit="$line_count" 'BEGIN { for (i = 1; i <= limit; i++) print "GRIDOS_ALPHA_FAST_OUTPUT_LINE" i }' >/dev/null 2>&1; then
    append_row "fast output" "1000 sanitized lines to /dev/null" "PASS"
  else
    append_row "fast output" "1000 sanitized lines to /dev/null" "FAIL"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi
}

run_quiet_check "vim availability" "vim --version" vim --version
run_quiet_check "less availability" "less --version" less --version
run_quiet_check "top availability" "top -l 1 -n 0" top -l 1 -n 0
run_quiet_check "tmux availability" "tmux -V" tmux -V
run_quiet_check "ssh availability" "ssh -V" ssh -V
run_fast_output_check

if [ "$FAILED_CHECKS" -eq 0 ]; then
  OVERALL_RESULT="PASS"
else
  OVERALL_RESULT="FAIL"
fi

SOURCE_COMMIT="$(cd "$ROOT_DIR" && git rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

{
  printf '# Phase 11 Alpha UAT Summary\n\n'
  printf '| Field | Value |\n'
  printf '| --- | --- |\n'
  printf '| Generated | %s |\n' "$GENERATED_AT"
  printf '| Source commit | %s |\n' "$SOURCE_COMMIT"
  printf '| Overall result | %s |\n' "$OVERALL_RESULT"
  printf '| Checks | %s total, %s failed |\n\n' "$TOTAL_CHECKS" "$FAILED_CHECKS"
  printf '## Noninteractive Checks\n\n'
  printf '| Check | Command | Result |\n'
  printf '| --- | --- | --- |\n'
  printf '%b' "$CHECK_ROWS"
  printf '\n## Privacy\n\n'
  printf 'This summary records command names and PASS/FAIL status only. It does not capture terminal transcripts, shell history, raw command output, environment variables, API keys, prompts, generated commands, provider responses, screenshots, traces, or private file paths.\n'
} > "$SUMMARY_PATH"

printf 'Wrote sanitized Alpha UAT summary: %s\n' "$SUMMARY_PATH"

if [ "$FAILED_CHECKS" -ne 0 ]; then
  exit 1
fi
