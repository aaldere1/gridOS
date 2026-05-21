#!/usr/bin/env bash
set -euo pipefail

PHASE9_PERFORMANCE_REPORT="PHASE9_PERFORMANCE_REPORT"
PHASE9_READY="PHASE9_READY"
PHASE9_INPUT_LATENCY="PHASE9_INPUT_LATENCY"
PHASE9_HEAVY_OUTPUT_DONE="PHASE9_HEAVY_OUTPUT_DONE"
PHASE9_FRAME_PACING="PHASE9_FRAME_PACING"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/evidence"
JSON_REPORT="$EVIDENCE_DIR/phase9-results.json"
MARKDOWN_REPORT="$EVIDENCE_DIR/README.md"
BUILD_CONFIGURATION="${GRIDOS_BUILD_CONFIGURATION:-Debug}"

READY_MARKER_PATH="/tmp/gridos_phase9_ready.json"
INPUT_LATENCY_MARKER_PATH="/tmp/gridos_phase9_input_latency.json"
HEAVY_OUTPUT_MARKER_PATH="/tmp/gridos_phase9_heavy_output.json"
FRAME_PACING_MARKER_PATH="/tmp/gridos_phase9_frame_pacing.json"

TARGET_COLD_START_MS=500
TARGET_RSS_MB=100
TARGET_IDLE_CPU_PERCENT=0.5
TARGET_INPUT_LATENCY_MS=5
TARGET_FRAME_PACING="active-pulse pacing evidence"

MODE="full"
READY_STATUS="pending"
INPUT_LATENCY_STATUS="pending"
HEAVY_OUTPUT_STATUS="pending"
FRAME_PACING_STATUS="pending"

usage() {
  cat <<EOF
Usage: $0 [--quick]

Writes:
  $JSON_REPORT
  $MARKDOWN_REPORT

The --quick path launches short DEBUG fixture smokes when a built app exists.
Live threshold measurements are filled by later Phase 9 plans.
EOF
}

now_seconds() {
  /usr/bin/perl -MTime::HiRes=time -e 'printf "%.6f\n", time'
}

generated_at() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

json_quote() {
  printf "%s" "$1" | /usr/bin/perl -0777 -pe 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g'
}

resolve_app_binary() {
  if [[ -n "${GRIDOS_APP_BIN:-}" && -x "${GRIDOS_APP_BIN:-}" ]]; then
    printf "%s\n" "$GRIDOS_APP_BIN"
    return 0
  fi

  local derived_data_bin
  derived_data_bin=$(
    ls -dt "$HOME"/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/"$BUILD_CONFIGURATION"/gridOS.app/Contents/MacOS/gridOS 2>/dev/null | head -1 || true
  )

  if [[ -n "$derived_data_bin" && -x "$derived_data_bin" ]]; then
    printf "%s\n" "$derived_data_bin"
    return 0
  fi

  return 1
}

wait_for_file() {
  local path="$1"
  local timeout_seconds="${2:-10}"
  local started
  started="$(now_seconds)"

  while true; do
    if [[ -f "$path" ]]; then
      return 0
    fi

    local elapsed
    elapsed=$(/usr/bin/perl -e 'printf "%.3f\n", $ARGV[1] - $ARGV[0]' "$started" "$(now_seconds)")
    if /usr/bin/perl -e 'exit(($ARGV[0] >= $ARGV[1]) ? 0 : 1)' "$elapsed" "$timeout_seconds"; then
      return 1
    fi

    sleep 0.05
  done
}

sample_process() {
  local pid="$1"
  ps -o rss= -o %cpu= -p "$pid" | awk 'NF >= 2 { printf "{\"rss_mb\": %.2f, \"cpu_percent\": %.2f}\n", $1 / 1024, $2 }'
}

marker_payload_json_value() {
  local marker_path="$1"
  if [[ ! -f "$marker_path" ]]; then
    printf 'null'
    return 0
  fi

  printf '"%s"' "$(json_quote "$(cat "$marker_path")")"
}

resolved_app_binary_json_value() {
  local app_bin
  if app_bin="$(resolve_app_binary)"; then
    printf '"%s"' "$app_bin"
  else
    printf 'null'
  fi
}

terminate_launched_pid() {
  local pid="$1"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
}

run_app_marker_smoke() {
  local argument="$1"
  local marker_path="$2"
  local timeout_seconds="$3"
  local app_bin

  if ! app_bin="$(resolve_app_binary)"; then
    printf "UNAVAILABLE"
    return 0
  fi

  rm -f "$marker_path"
  "$app_bin" "$argument" >/dev/null 2>&1 &
  local app_pid=$!

  local status
  if wait_for_file "$marker_path" "$timeout_seconds"; then
    status="PASS"
  else
    status="MISS"
  fi

  terminate_launched_pid "$app_pid"
  printf "%s" "$status"
}

run_ready_smoke() {
  READY_STATUS="$(run_app_marker_smoke "--phase9-ready-smoke" "$READY_MARKER_PATH" 3)"
}

run_input_latency_smoke() {
  INPUT_LATENCY_STATUS="$(run_app_marker_smoke "--phase9-input-latency-smoke" "$INPUT_LATENCY_MARKER_PATH" 8)"
}

run_heavy_output_smoke() {
  HEAVY_OUTPUT_STATUS="$(run_app_marker_smoke "--phase9-heavy-output-smoke" "$HEAVY_OUTPUT_MARKER_PATH" 10)"
}

run_frame_pacing_smoke() {
  FRAME_PACING_STATUS="$(run_app_marker_smoke "--phase9-frame-pacing-smoke" "$FRAME_PACING_MARKER_PATH" 5)"
}

run_fixture_smokes() {
  run_ready_smoke
  run_input_latency_smoke
  run_heavy_output_smoke
  run_frame_pacing_smoke
}

write_json_report() {
  mkdir -p "$EVIDENCE_DIR"

  local timestamp
  timestamp="$(generated_at)"

  cat > "$JSON_REPORT" <<EOF
{
  "report": "$PHASE9_PERFORMANCE_REPORT",
  "generated_at": "$timestamp",
  "configuration": {
    "mode": "$MODE",
    "build_configuration": "$BUILD_CONFIGURATION",
    "app_binary": $(resolved_app_binary_json_value),
    "phase": "09-performance-hardening"
  },
  "targets": {
    "cold_start_ms": $TARGET_COLD_START_MS,
    "rss_mb": $TARGET_RSS_MB,
    "idle_cpu_percent": $TARGET_IDLE_CPU_PERCENT,
    "input_latency_ms": $TARGET_INPUT_LATENCY_MS,
    "frame_pacing": "$TARGET_FRAME_PACING"
  },
  "results": {
    "cold_start_ms": {
      "status": "$READY_STATUS",
      "observed": null,
      "marker": "$PHASE9_READY",
      "marker_payload": $(marker_payload_json_value "$READY_MARKER_PATH"),
      "notes": "Fixture smoke result; threshold measurements are pending until Plan 09-03."
    },
    "rss_mb": {
      "status": "pending",
      "observed": null,
      "notes": "Live measurements are pending until Plans 09-02 and 09-03."
    },
    "idle_cpu_percent": {
      "status": "pending",
      "observed": null,
      "notes": "Live measurements are pending until Plans 09-02 and 09-03."
    },
    "input_latency_ms": {
      "status": "$INPUT_LATENCY_STATUS",
      "observed": null,
      "marker": "$PHASE9_INPUT_LATENCY",
      "marker_payload": $(marker_payload_json_value "$INPUT_LATENCY_MARKER_PATH"),
      "notes": "Fixture smoke result; measured latency is pending until Plan 09-03."
    },
    "heavy_output": {
      "status": "$HEAVY_OUTPUT_STATUS",
      "observed": null,
      "marker": "$PHASE9_HEAVY_OUTPUT_DONE",
      "marker_payload": $(marker_payload_json_value "$HEAVY_OUTPUT_MARKER_PATH"),
      "notes": "Fixture smoke result; measured heavy-output stress is pending until Plan 09-03."
    },
    "frame_pacing": {
      "status": "$FRAME_PACING_STATUS",
      "observed": null,
      "marker": "$PHASE9_FRAME_PACING",
      "marker_payload": $(marker_payload_json_value "$FRAME_PACING_MARKER_PATH"),
      "notes": "Fixture smoke result; xctrace/frame-pacing summary is pending until Plan 09-03."
    }
  },
  "misses": []
}
EOF
}

write_markdown_report() {
  mkdir -p "$EVIDENCE_DIR"

  cat > "$MARKDOWN_REPORT" <<EOF
# Phase 9 performance hardening

## Phase 9 final gate

Status: fixture smoke ready. Live threshold measurements are added in later Phase 9 plans.

## Benchmark invocation

\`\`\`sh
.planning/phases/09-performance-hardening/run-performance-benchmarks.sh --quick
\`\`\`

Outputs:

- \`.planning/phases/09-performance-hardening/evidence/phase9-results.json\`
- \`.planning/phases/09-performance-hardening/evidence/README.md\`

## Targets

| Metric | Target |
| --- | --- |
| Cold start | < ${TARGET_COLD_START_MS} ms to terminal-ready marker |
| Resident memory | < ${TARGET_RSS_MB} MB for basic terminal plus one visual mode |
| Idle CPU | < ${TARGET_IDLE_CPU_PERCENT}% after startup/render bursts settle |
| Input latency | < ${TARGET_INPUT_LATENCY_MS} ms controller-to-PTY marker proxy |
| Frame pacing | ${TARGET_FRAME_PACING} |

## Results

| Scenario | Status | Marker |
| --- | --- | --- |
| Ready smoke | ${READY_STATUS} | ${PHASE9_READY} |
| Input latency smoke | ${INPUT_LATENCY_STATUS} | ${PHASE9_INPUT_LATENCY} |
| Heavy output smoke | ${HEAVY_OUTPUT_STATUS} | ${PHASE9_HEAVY_OUTPUT_DONE} |
| Frame pacing smoke | ${FRAME_PACING_STATUS} | ${PHASE9_FRAME_PACING} |

Threshold measurements are pending until Plan 09-03.

## Misses and mitigations

| Metric | Status | Owner | Mitigation |
| --- | --- | --- | --- |
| Live measurements | pending | Phase 09 | Add measured scenarios in Plan 09-03. |

## Known limitations

- This report contains fixture smoke status only until Plan 09-03 adds measured scenarios.
- No private shell history, terminal transcripts, environment variables, API keys, screenshots, or raw Instruments traces are captured.
- Full xctrace/profile behavior is added after deterministic app-side benchmark markers exist.
EOF
}

main() {
  while (($#)); do
    case "$1" in
      --quick)
        MODE="quick"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf "Unknown argument: %s\n\n" "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  run_fixture_smokes
  write_json_report
  write_markdown_report

  printf "%s\n" "$PHASE9_PERFORMANCE_REPORT"
  printf "mode=%s\n" "$MODE"
  printf "json=%s\n" "$JSON_REPORT"
  printf "markdown=%s\n" "$MARKDOWN_REPORT"
}

main "$@"
