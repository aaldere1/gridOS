#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/alpha-signing-preflight.sh [--dry-run]

Runs the gridOS Phase 11 signing preflight and writes sanitized evidence unless
--dry-run is supplied.
USAGE
}

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "UNKNOWN_ARGUMENT $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/project.yml"
EVIDENCE_DIR="$ROOT_DIR/.planning/phases/11-alpha/evidence"
REPORT_FILE="$EVIDENCE_DIR/signing-preflight.txt"

report_lines=()
missing_tools=()
missing_inputs=()

add_line() {
  report_lines+=("$1")
}

clean_value() {
  local value="$1"
  value="${value%%#*}"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  value="${value%\"}"
  value="${value#\"}"
  printf '%s' "$value"
}

project_setting() {
  local key="$1"
  awk -v key="$key" '
    /^  gridOS:$/ { in_target = 1; next }
    in_target && /^  [A-Za-z0-9_]+:$/ { exit }
    in_target && $1 == key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "")
      print
      exit
    }
  ' "$PROJECT_FILE" | {
    IFS= read -r value || true
    clean_value "${value:-}"
  }
}

tool_present() {
  command -v "$1" >/dev/null 2>&1
}

presence() {
  local value="$1"
  if [[ -n "$value" ]]; then
    printf 'present'
  else
    printf 'missing'
  fi
}

required_env_present() {
  local name="$1"
  if [[ -n "${!name:-}" ]]; then
    add_line "$name=present"
  else
    add_line "$name=missing"
    missing_inputs+=("$name")
  fi
}

optional_env_present() {
  local name="$1"
  if [[ -n "${!name:-}" ]]; then
    add_line "$name=present"
  else
    add_line "$name=missing_optional"
  fi
}

add_line "GRIDOS_ALPHA_PREFLIGHT"
add_line "MODE=$([[ "$DRY_RUN" -eq 1 ]] && printf 'dry-run' || printf 'write-evidence')"
add_line "TIMESTAMP_UTC=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

for tool in xcodegen xcodebuild security; do
  if tool_present "$tool"; then
    add_line "TOOL_$tool=present"
  else
    add_line "TOOL_$tool=missing"
    missing_tools+=("$tool")
  fi
done

if tool_present xcodebuild; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && add_line "XCODE_${line}"
  done < <(xcodebuild -version 2>/dev/null | sed -E 's/[[:space:]]+/ /g')
else
  add_line "XCODE_VERSION=unavailable"
fi

if [[ -f "$PROJECT_FILE" ]]; then
  bundle_identifier="$(project_setting PRODUCT_BUNDLE_IDENTIFIER)"
  development_team="$(project_setting DEVELOPMENT_TEAM)"
  code_sign_style="$(project_setting CODE_SIGN_STYLE)"
  hardened_runtime="$(project_setting ENABLE_HARDENED_RUNTIME)"

  add_line "PRODUCT_BUNDLE_IDENTIFIER=${bundle_identifier:-missing}"
  add_line "PROJECT_DEVELOPMENT_TEAM=$(presence "$development_team")"
  add_line "CODE_SIGN_STYLE=${code_sign_style:-missing}"
  add_line "ENABLE_HARDENED_RUNTIME=${hardened_runtime:-missing}"

  [[ -z "$bundle_identifier" ]] && missing_inputs+=("PRODUCT_BUNDLE_IDENTIFIER")
  [[ -z "$code_sign_style" ]] && missing_inputs+=("CODE_SIGN_STYLE")
  [[ "$hardened_runtime" != "YES" ]] && missing_inputs+=("ENABLE_HARDENED_RUNTIME")
else
  add_line "PROJECT_FILE=missing"
  missing_inputs+=("project.yml")
fi

required_env_present GRIDOS_DEVELOPMENT_TEAM
required_env_present GRIDOS_SIGNING_IDENTITY
optional_env_present GRIDOS_EXPORT_METHOD

if tool_present security; then
  identity_count="$(
    security find-identity -v -p codesigning 2>/dev/null |
      awk '/valid identities found/ { print $1 }' |
      tail -n 1
  )"
  if [[ "${identity_count:-0}" =~ ^[0-9]+$ ]] && [[ "$identity_count" -gt 0 ]]; then
    add_line "CODESIGNING_IDENTITIES=present"
  else
    add_line "CODESIGNING_IDENTITIES=missing"
    missing_inputs+=("codesigning_identity")
  fi
else
  add_line "CODESIGNING_IDENTITIES=unavailable"
fi

if [[ "${#missing_tools[@]}" -gt 0 ]]; then
  add_line "TOOL_BLOCKED ${missing_tools[*]}"
fi

if [[ "${#missing_inputs[@]}" -gt 0 ]]; then
  add_line "SIGNING_BLOCKED ${missing_inputs[*]}"
else
  add_line "SIGNING_READY"
fi

printf '%s\n' "${report_lines[@]}"

if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$EVIDENCE_DIR"
  printf '%s\n' "${report_lines[@]}" > "$REPORT_FILE"
fi

if [[ "$DRY_RUN" -eq 0 && ( "${#missing_tools[@]}" -gt 0 || "${#missing_inputs[@]}" -gt 0 ) ]]; then
  exit 1
fi
