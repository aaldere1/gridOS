#!/usr/bin/env bash
set -euo pipefail

PHASE9_PERFORMANCE_REPORT="PHASE9_PERFORMANCE_REPORT"
PHASE9_READY="PHASE9_READY"
PHASE9_INPUT_LATENCY="PHASE9_INPUT_LATENCY"
PHASE9_HEAVY_OUTPUT_DONE="PHASE9_HEAVY_OUTPUT_DONE"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/evidence"
JSON_REPORT="$EVIDENCE_DIR/phase9-results.json"
MARKDOWN_REPORT="$EVIDENCE_DIR/README.md"
BUILD_CONFIGURATION="${GRIDOS_BUILD_CONFIGURATION:-Release}"

TARGET_COLD_START_MS=500
TARGET_RSS_MB=100
TARGET_IDLE_CPU_PERCENT=0.5
TARGET_INPUT_LATENCY_MS=5
TARGET_FRAME_PACING="active-pulse pacing evidence"

MODE="full"

usage() {
  cat <<EOF
Usage: $0 [--quick]

Writes:
  $JSON_REPORT
  $MARKDOWN_REPORT

The --quick path writes a lightweight PHASE9_PERFORMANCE_REPORT placeholder.
Live measurements are filled by later Phase 9 plans after app fixtures exist.
EOF
}

now_seconds() {
  /usr/bin/perl -MTime::HiRes=time -e 'printf "%.6f\n", time'
}

generated_at() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
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

resolved_app_binary_json_value() {
  local app_bin
  if app_bin="$(resolve_app_binary)"; then
    printf '"%s"' "$app_bin"
  else
    printf 'null'
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
      "status": "pending",
      "observed": null,
      "marker": "$PHASE9_READY",
      "notes": "Live measurements are pending until Plans 09-02 and 09-03."
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
      "status": "pending",
      "observed": null,
      "marker": "$PHASE9_INPUT_LATENCY",
      "notes": "Live measurements are pending until Plans 09-02 and 09-03."
    },
    "heavy_output": {
      "status": "pending",
      "observed": null,
      "marker": "$PHASE9_HEAVY_OUTPUT_DONE",
      "notes": "Live measurements are pending until Plans 09-02 and 09-03."
    },
    "frame_pacing": {
      "status": "pending",
      "observed": null,
      "notes": "Live measurements are pending until Plans 09-02 and 09-03."
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

Status: pending live measurements. The benchmark harness and report schema are present; app-side fixtures and measured scenarios are added in later Phase 9 plans.

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

Live measurements are pending until Plans 09-02 and 09-03.

## Misses and mitigations

| Metric | Status | Owner | Mitigation |
| --- | --- | --- | --- |
| Live measurements | pending | Phase 09 | Add app fixtures and measured scenarios in Plans 09-02 and 09-03. |

## Known limitations

- This initial report is a schema and quick-smoke placeholder.
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

  write_json_report
  write_markdown_report

  printf "%s\n" "$PHASE9_PERFORMANCE_REPORT"
  printf "mode=%s\n" "$MODE"
  printf "json=%s\n" "$JSON_REPORT"
  printf "markdown=%s\n" "$MARKDOWN_REPORT"
}

main "$@"
