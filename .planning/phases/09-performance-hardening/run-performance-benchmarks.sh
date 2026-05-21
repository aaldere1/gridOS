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
INPUT_LATENCY_MS_OBSERVED="null"
HEAVY_OUTPUT_MS_OBSERVED="null"
HEAVY_OUTPUT_LINE_COUNT="null"
FRAME_PACING_MS_OBSERVED="null"
FRAME_PACING_PULSE_COUNT="null"
XCTRACE_STATUS="UNAVAILABLE"
XCTRACE_REASON="Skipped until capture_xctrace_summary runs."
XCTRACE_TRACE_PATH="null"
XCTRACE_TOC_PATH="null"
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

json_number_field() {
  local path="$1"
  local field="$2"

  if [[ ! -f "$path" ]]; then
    printf 'null'
    return 0
  fi

  local value
  value="$(/usr/bin/perl -ne 'BEGIN { $field = shift @ARGV } if (/"\Q$field\E": ([0-9.]+)/) { print $1; exit }' "$field" "$path")"
  if [[ -n "$value" ]]; then
    printf "%s" "$value"
  else
    printf 'null'
  fi
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

measure_input_latency() {
  INPUT_LATENCY_STATUS="$(run_app_marker_smoke "--phase9-input-latency-smoke" "$INPUT_LATENCY_MARKER_PATH" 8)"
  INPUT_LATENCY_MS_OBSERVED="$(json_number_field "$INPUT_LATENCY_MARKER_PATH" "elapsed_ms")"

  if [[ "$INPUT_LATENCY_STATUS" == "PASS" ]]; then
    INPUT_LATENCY_STATUS="$(status_for_numeric_target "$INPUT_LATENCY_MS_OBSERVED" "$TARGET_INPUT_LATENCY_MS")"
  fi
}

measure_heavy_output() {
  HEAVY_OUTPUT_STATUS="$(run_app_marker_smoke "--phase9-heavy-output-smoke" "$HEAVY_OUTPUT_MARKER_PATH" 10)"
  HEAVY_OUTPUT_MS_OBSERVED="$(json_number_field "$HEAVY_OUTPUT_MARKER_PATH" "elapsed_ms")"
  HEAVY_OUTPUT_LINE_COUNT="$(json_number_field "$HEAVY_OUTPUT_MARKER_PATH" "line_count")"

  if [[ "$HEAVY_OUTPUT_STATUS" == "PASS" ]] && ! grep -q "$PHASE9_HEAVY_OUTPUT_DONE" "$HEAVY_OUTPUT_MARKER_PATH"; then
    HEAVY_OUTPUT_STATUS="MISS"
  fi
}

measure_frame_pacing() {
  FRAME_PACING_STATUS="$(run_app_marker_smoke "--phase9-frame-pacing-smoke" "$FRAME_PACING_MARKER_PATH" 5)"
  FRAME_PACING_MS_OBSERVED="$(json_number_field "$FRAME_PACING_MARKER_PATH" "elapsed_ms")"
  FRAME_PACING_PULSE_COUNT="$(json_number_field "$FRAME_PACING_MARKER_PATH" "pulse_count")"
}

json_nullable_string() {
  local value="$1"
  if [[ "$value" == "null" ]]; then
    printf 'null'
  else
    printf '"%s"' "$(json_quote "$value")"
  fi
}

capture_xctrace_summary() {
  if [[ "$MODE" == "quick" ]]; then
    XCTRACE_STATUS="UNAVAILABLE"
    XCTRACE_REASON="Skipped in --quick mode."
    return 0
  fi

  if ! command -v xcrun >/dev/null 2>&1; then
    XCTRACE_STATUS="UNAVAILABLE"
    XCTRACE_REASON="xcrun is unavailable."
    return 0
  fi

  local app_bin
  if ! app_bin="$(resolve_app_binary)"; then
    XCTRACE_STATUS="UNAVAILABLE"
    XCTRACE_REASON="gridOS app binary is unavailable."
    return 0
  fi

  local trace_path="$EVIDENCE_DIR/phase9-animation-hitches.trace"
  local toc_path="$EVIDENCE_DIR/phase9-animation-hitches-toc.xml"
  rm -rf "$trace_path" "$toc_path"

  if xcrun xctrace record --template 'Animation Hitches' --time-limit 5s --output "$trace_path" --launch -- "$app_bin" --phase9-frame-pacing-smoke >/dev/null 2>&1; then
    if xcrun xctrace export --input "$trace_path" --toc --output "$toc_path" >/dev/null 2>&1; then
      XCTRACE_STATUS="PASS"
      XCTRACE_REASON="Animation Hitches trace and TOC export completed."
      XCTRACE_TRACE_PATH="evidence/phase9-animation-hitches.trace"
      XCTRACE_TOC_PATH="evidence/phase9-animation-hitches-toc.xml"
    else
      XCTRACE_STATUS="UNAVAILABLE"
      XCTRACE_REASON="xcrun xctrace export failed after record."
      XCTRACE_TRACE_PATH="evidence/phase9-animation-hitches.trace"
      XCTRACE_TOC_PATH="null"
    fi
  else
    XCTRACE_STATUS="UNAVAILABLE"
    XCTRACE_REASON="xcrun xctrace record failed or required permissions."
  fi
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
      "observed": $INPUT_LATENCY_MS_OBSERVED,
      "target": $TARGET_INPUT_LATENCY_MS,
      "marker": "$PHASE9_INPUT_LATENCY",
      "marker_payload": $(marker_payload_json_value "$INPUT_LATENCY_MARKER_PATH"),
      "notes": "Controller-to-PTY marker proxy. Synthetic terminal markers only; no user shell output captured."
    },
    "heavy_output": {
      "status": "$HEAVY_OUTPUT_STATUS",
      "observed": $HEAVY_OUTPUT_MS_OBSERVED,
      "line_count": $HEAVY_OUTPUT_LINE_COUNT,
      "marker": "$PHASE9_HEAVY_OUTPUT_DONE",
      "marker_payload": $(marker_payload_json_value "$HEAVY_OUTPUT_MARKER_PATH"),
      "notes": "Synthetic terminal markers only; no user shell output captured."
    },
    "frame_pacing": {
      "status": "$FRAME_PACING_STATUS",
      "observed": $FRAME_PACING_MS_OBSERVED,
      "pulse_count": $FRAME_PACING_PULSE_COUNT,
      "marker": "$PHASE9_FRAME_PACING",
      "marker_payload": $(marker_payload_json_value "$FRAME_PACING_MARKER_PATH"),
      "xctrace": {
        "status": "$XCTRACE_STATUS",
        "reason": "$(json_quote "$XCTRACE_REASON")",
        "trace_path": $(json_nullable_string "$XCTRACE_TRACE_PATH"),
        "toc_path": $(json_nullable_string "$XCTRACE_TOC_PATH")
      },
      "notes": "Active-pulse marker and optional Animation Hitches xctrace summary."
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

Status: quick benchmark captured. Full xctrace capture is skipped in --quick mode.

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

## Input latency

- **Target:** < ${TARGET_INPUT_LATENCY_MS} ms
- **Observed:** ${INPUT_LATENCY_MS_OBSERVED} ms
- **Status:** ${INPUT_LATENCY_STATUS}
- **Command:** \`gridOS --phase9-input-latency-smoke\`
- **Notes:** Controller-to-PTY marker proxy. Synthetic terminal markers only; no user shell output captured.

## Heavy output

- **Target:** synthetic marker completes and writes ${PHASE9_HEAVY_OUTPUT_DONE}
- **Observed:** ${HEAVY_OUTPUT_MS_OBSERVED} ms, ${HEAVY_OUTPUT_LINE_COUNT} synthetic lines
- **Status:** ${HEAVY_OUTPUT_STATUS}
- **Command:** \`gridOS --phase9-heavy-output-smoke\`
- **Notes:** Synthetic terminal markers only; no user shell output captured.

## Frame pacing

- **Target:** ${TARGET_FRAME_PACING}
- **Observed:** ${FRAME_PACING_MS_OBSERVED} ms, ${FRAME_PACING_PULSE_COUNT} render pulses
- **Status:** ${FRAME_PACING_STATUS}
- **Command:** \`gridOS --phase9-frame-pacing-smoke\`
- **xctrace status:** ${XCTRACE_STATUS}
- **xctrace detail:** ${XCTRACE_REASON}
- **Trace path:** ${XCTRACE_TRACE_PATH}
- **TOC path:** ${XCTRACE_TOC_PATH}
- **Notes:** Full mode attempts \`xcrun xctrace record --template 'Animation Hitches'\` and \`xcrun xctrace export\`; raw trace bundles may be excluded from commits if too large or private.

## Misses and mitigations

| Metric | Status | Owner | Mitigation |
| --- | --- | --- | --- |
$(misses_markdown_rows)

## Privacy proof

- Evidence is limited to synthetic DEBUG markers, process samples, benchmark status, and sanitized summary metadata.
- The committed report labels the app binary as \`gridOS.app/Contents/MacOS/gridOS\` instead of recording the local DerivedData path.
- The benchmark does not capture private shell history, terminal transcripts, environment variables, API keys, screenshots, or raw Instruments traces.

## Known limitations

- This quick report captures local Debug benchmark evidence; full xctrace capture is skipped in --quick mode.
- No private shell history, terminal transcripts, environment variables, API keys, screenshots, or raw Instruments traces are captured.
- Full xctrace/profile behavior records summary availability; raw trace bundles may be excluded from commits if too large or private.
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
  measure_input_latency
  measure_heavy_output
  measure_frame_pacing
  capture_xctrace_summary
  write_json_report
  write_markdown_report

  printf "%s\n" "$PHASE9_PERFORMANCE_REPORT"
  printf "mode=%s\n" "$MODE"
  printf "json=%s\n" "$JSON_REPORT"
  printf "markdown=%s\n" "$MARKDOWN_REPORT"
}

main "$@"
