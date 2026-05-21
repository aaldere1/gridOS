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
COLD_START_MS_OBSERVED="null"
RSS_MB_OBSERVED="null"
IDLE_CPU_PERCENT_OBSERVED="null"
RSS_STATUS="pending"
IDLE_CPU_STATUS="pending"
MEASUREMENT_APP_PID=""
MEASUREMENT_APP_BIN=""

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
  if resolve_app_binary >/dev/null; then
    printf '"gridOS.app/Contents/MacOS/gridOS"'
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

status_for_numeric_target() {
  local observed="$1"
  local target="$2"

  if [[ "$observed" == "null" ]]; then
    printf "UNAVAILABLE"
    return 0
  fi

  if /usr/bin/perl -e 'exit(($ARGV[0] <= $ARGV[1]) ? 0 : 1)' "$observed" "$target"; then
    printf "PASS"
  else
    printf "MISS"
  fi
}

measure_cold_start() {
  if ! MEASUREMENT_APP_BIN="$(resolve_app_binary)"; then
    READY_STATUS="UNAVAILABLE"
    COLD_START_MS_OBSERVED="null"
    return 0
  fi

  rm -f "$READY_MARKER_PATH"
  local started
  started="$(now_seconds)"
  "$MEASUREMENT_APP_BIN" "--phase9-ready-smoke" >/dev/null 2>&1 &
  MEASUREMENT_APP_PID=$!

  if wait_for_file "$READY_MARKER_PATH" 3; then
    local finished
    finished="$(now_seconds)"
    COLD_START_MS_OBSERVED=$(/usr/bin/perl -e 'printf "%.3f\n", ($ARGV[1] - $ARGV[0]) * 1000' "$started" "$finished")
    READY_STATUS="$(status_for_numeric_target "$COLD_START_MS_OBSERVED" "$TARGET_COLD_START_MS")"
  else
    READY_STATUS="MISS"
    COLD_START_MS_OBSERVED="null"
  fi
}

measure_resident_memory() {
  if [[ -z "$MEASUREMENT_APP_PID" ]] || ! kill -0 "$MEASUREMENT_APP_PID" 2>/dev/null; then
    RSS_MB_OBSERVED="null"
    RSS_STATUS="UNAVAILABLE"
    return 0
  fi

  sleep 1
  local rss_kib
  rss_kib="$(ps -o rss= -p "$MEASUREMENT_APP_PID" | awk 'NF >= 1 { print $1; exit }')"

  if [[ -z "$rss_kib" ]]; then
    RSS_MB_OBSERVED="null"
    RSS_STATUS="UNAVAILABLE"
    return 0
  fi

  RSS_MB_OBSERVED="$(awk -v rss_kib="$rss_kib" 'BEGIN { printf "%.2f", rss_kib / 1024 }')"
  RSS_STATUS="$(status_for_numeric_target "$RSS_MB_OBSERVED" "$TARGET_RSS_MB")"
}

measure_idle_cpu() {
  if [[ -z "$MEASUREMENT_APP_PID" ]] || ! kill -0 "$MEASUREMENT_APP_PID" 2>/dev/null; then
    IDLE_CPU_PERCENT_OBSERVED="null"
    IDLE_CPU_STATUS="UNAVAILABLE"
    return 0
  fi

  local sample_count=0
  local sample_sum="0"
  local cpu_sample

  for _ in 1 2 3 4 5; do
    cpu_sample="$(ps -o %cpu= -p "$MEASUREMENT_APP_PID" | awk 'NF >= 1 { print $1; exit }')"
    if [[ -n "$cpu_sample" ]]; then
      sample_sum="$(awk -v sum="$sample_sum" -v sample="$cpu_sample" 'BEGIN { printf "%.4f", sum + sample }')"
      sample_count=$((sample_count + 1))
    fi
    sleep 0.2
  done

  if [[ "$sample_count" -eq 0 ]]; then
    IDLE_CPU_PERCENT_OBSERVED="null"
    IDLE_CPU_STATUS="UNAVAILABLE"
    return 0
  fi

  IDLE_CPU_PERCENT_OBSERVED="$(awk -v sum="$sample_sum" -v count="$sample_count" 'BEGIN { printf "%.3f", sum / count }')"
  IDLE_CPU_STATUS="$(status_for_numeric_target "$IDLE_CPU_PERCENT_OBSERVED" "$TARGET_IDLE_CPU_PERCENT")"
}

cleanup_measurement_app() {
  if [[ -n "$MEASUREMENT_APP_PID" ]]; then
    terminate_launched_pid "$MEASUREMENT_APP_PID"
  fi
  MEASUREMENT_APP_PID=""
}

misses_json_value() {
  local first=1

  printf '['
  append_miss_json "cold_start_ms" "$READY_STATUS" "Optimize launch/readiness path or document release exception."
  append_miss_json "rss_mb" "$RSS_STATUS" "Profile resident memory and reduce baseline allocations or document release exception."
  append_miss_json "idle_cpu_percent" "$IDLE_CPU_STATUS" "Profile idle run loop, metrics sampler, and render lifecycle."
  append_miss_json "input_latency_ms" "$INPUT_LATENCY_STATUS" "Validate terminal-bound fixture availability and measure controller-to-PTY latency."
  append_miss_json "heavy_output" "$HEAVY_OUTPUT_STATUS" "Validate terminal-bound heavy-output fixture and inspect UI/output batching."
  append_miss_json "frame_pacing" "$FRAME_PACING_STATUS" "Validate render-pulse fixture and capture frame-pacing summary."
  printf ']'
}

append_miss_json() {
  local metric="$1"
  local status="$2"
  local mitigation="$3"

  if [[ "$status" != "MISS" ]]; then
    return 0
  fi

  if [[ "${first}" -eq 0 ]]; then
    printf ','
  fi

  first=0
  printf '\n    {"metric": "%s", "status": "MISS", "owner": "Phase 09", "mitigation": "%s"}' "$metric" "$(json_quote "$mitigation")"
}

misses_markdown_rows() {
  local rows=""

  append_miss_markdown "Cold start" "$READY_STATUS" "Optimize launch/readiness path or document release exception."
  append_miss_markdown "Resident memory" "$RSS_STATUS" "Profile resident memory and reduce baseline allocations or document release exception."
  append_miss_markdown "Idle CPU" "$IDLE_CPU_STATUS" "Profile idle run loop, metrics sampler, and render lifecycle."
  append_miss_markdown "Input latency" "$INPUT_LATENCY_STATUS" "Validate terminal-bound fixture availability and measure controller-to-PTY latency."
  append_miss_markdown "Heavy output" "$HEAVY_OUTPUT_STATUS" "Validate terminal-bound heavy-output fixture and inspect UI/output batching."
  append_miss_markdown "Frame pacing" "$FRAME_PACING_STATUS" "Validate render-pulse fixture and capture frame-pacing summary."

  if [[ -z "$rows" ]]; then
    printf "| None | PASS | n/a | n/a |\n"
  else
    printf "%s" "$rows"
  fi
}

append_miss_markdown() {
  local metric="$1"
  local status="$2"
  local mitigation="$3"

  if [[ "$status" == "MISS" ]]; then
    rows="${rows}| ${metric} | MISS | Phase 09 | ${mitigation} |"$'\n'
  fi
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
      "observed": $COLD_START_MS_OBSERVED,
      "target": $TARGET_COLD_START_MS,
      "marker": "$PHASE9_READY",
      "marker_payload": $(marker_payload_json_value "$READY_MARKER_PATH"),
      "notes": "App launch to Phase 9 ready marker."
    },
    "rss_mb": {
      "status": "$RSS_STATUS",
      "observed": $RSS_MB_OBSERVED,
      "target": $TARGET_RSS_MB,
      "notes": "Resident set size sampled from ps after startup settle."
    },
    "idle_cpu_percent": {
      "status": "$IDLE_CPU_STATUS",
      "observed": $IDLE_CPU_PERCENT_OBSERVED,
      "target": $TARGET_IDLE_CPU_PERCENT,
      "notes": "Average of five ps CPU samples during a quiet window."
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
  "misses": $(misses_json_value)
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
| Cold start | ${READY_STATUS} | ${PHASE9_READY} |
| Resident memory | ${RSS_STATUS} | ps rss |
| Idle CPU | ${IDLE_CPU_STATUS} | ps %cpu |
| Input latency smoke | ${INPUT_LATENCY_STATUS} | ${PHASE9_INPUT_LATENCY} |
| Heavy output smoke | ${HEAVY_OUTPUT_STATUS} | ${PHASE9_HEAVY_OUTPUT_DONE} |
| Frame pacing smoke | ${FRAME_PACING_STATUS} | ${PHASE9_FRAME_PACING} |

## Cold start

- **Target:** < ${TARGET_COLD_START_MS} ms
- **Observed:** ${COLD_START_MS_OBSERVED} ms
- **Status:** ${READY_STATUS}
- **Command:** \`gridOS --phase9-ready-smoke\`
- **Notes:** App launch to Phase 9 ready marker.

## Resident memory

- **Target:** < ${TARGET_RSS_MB} MB
- **Observed:** ${RSS_MB_OBSERVED} MB
- **Status:** ${RSS_STATUS}
- **Command:** \`ps -o rss= -p <gridOS pid>\`
- **Notes:** RSS sampled after a short startup settle window.

## Idle CPU

- **Target:** < ${TARGET_IDLE_CPU_PERCENT}%
- **Observed:** ${IDLE_CPU_PERCENT_OBSERVED}%
- **Status:** ${IDLE_CPU_STATUS}
- **Command:** \`ps -o %cpu= -p <gridOS pid>\`
- **Notes:** Average of five quiet-window samples.

## Misses and mitigations

| Metric | Status | Owner | Mitigation |
| --- | --- | --- | --- |
$(misses_markdown_rows)

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

  measure_cold_start
  measure_resident_memory
  measure_idle_cpu
  cleanup_measurement_app
  run_input_latency_smoke
  run_heavy_output_smoke
  run_frame_pacing_smoke
  write_json_report
  write_markdown_report

  printf "%s\n" "$PHASE9_PERFORMANCE_REPORT"
  printf "mode=%s\n" "$MODE"
  printf "json=%s\n" "$JSON_REPORT"
  printf "markdown=%s\n" "$MARKDOWN_REPORT"
}

main "$@"
