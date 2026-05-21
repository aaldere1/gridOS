#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/beta-notarization-preflight.sh [--dry-run]

Runs the gridOS Phase 12 Beta signing/notarization preflight and writes
sanitized evidence unless --dry-run is supplied.
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
EVIDENCE_DIR="$ROOT_DIR/.planning/phases/12-beta/evidence"
REPORT_FILE="$EVIDENCE_DIR/beta-notarization-preflight.txt"

report_lines=()
missing_tools=()
missing_inputs=()
missing_notary_inputs=()
development_team=""

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

env_presence_line() {
  local name="$1"
  local empty_status="${2:-missing}"
  if [[ -n "${!name:-}" ]]; then
    add_line "$name=present"
  else
    add_line "$name=$empty_status"
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

stapler_available() {
  local output
  output="$(xcrun stapler --help 2>&1 || true)"
  [[ "$output" == *"Supported file formats"* ]]
}

notary_profile_present() {
  [[ -n "${GRIDOS_NOTARY_PROFILE:-}" ]]
}

notary_apple_id_mode_present() {
  [[ -n "${GRIDOS_NOTARY_APPLE_ID:-}" && -n "${GRIDOS_NOTARY_PASSWORD:-}" && -n "${GRIDOS_NOTARY_TEAM_ID:-}" ]]
}

notary_api_key_mode_present() {
  [[ -n "${GRIDOS_NOTARY_KEY_ID:-}" && -n "${GRIDOS_NOTARY_ISSUER_ID:-}" && -n "${GRIDOS_NOTARY_KEY_PATH:-}" ]]
}

developer_id_identity() {
  if ! tool_present security; then
    return 1
  fi

  security find-identity -v -p codesigning 2>/dev/null |
    awk -F\" '/"Developer ID Application:/ { print $2; exit }'
}

team_id_from_identity() {
  local identity="$1"
  sed -nE 's/.*\(([A-Z0-9]{10})\)$/\1/p' <<< "$identity"
}

notary_profile_status() {
  local profile_name="$1"
  local tmp_output
  local tmp_error

  tmp_output="$(mktemp "${TMPDIR:-/tmp}/gridos-beta-notary-profile.XXXXXX.json")"
  tmp_error="$(mktemp "${TMPDIR:-/tmp}/gridos-beta-notary-profile.XXXXXX.err")"

  if xcrun notarytool history --keychain-profile "$profile_name" --output-format json --no-progress > "$tmp_output" 2>"$tmp_error"; then
    rm -f "$tmp_output" "$tmp_error"
    printf 'present'
    return
  fi

  if grep -q 'No Keychain password item found for profile' "$tmp_error"; then
    rm -f "$tmp_output" "$tmp_error"
    printf 'missing'
    return
  fi

  rm -f "$tmp_output" "$tmp_error"
  printf 'unavailable'
}

add_line "GRIDOS_BETA_PREFLIGHT"
add_line "MODE=$([[ "$DRY_RUN" -eq 1 ]] && printf 'dry-run' || printf 'write-evidence')"
add_line "TIMESTAMP_UTC=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

for tool in xcodegen xcodebuild security ditto hdiutil spctl xcrun; do
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

if tool_present xcrun && xcrun notarytool --version >/dev/null 2>&1; then
  add_line "XCRUN_NOTARYTOOL=present"
else
  add_line "XCRUN_NOTARYTOOL=missing"
  missing_tools+=("xcrun_notarytool")
fi

if tool_present xcrun && stapler_available; then
  add_line "XCRUN_STAPLER=present"
else
  add_line "XCRUN_STAPLER=missing"
  missing_tools+=("xcrun_stapler")
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

resolved_signing_identity="${GRIDOS_SIGNING_IDENTITY:-}"
signing_identity_source="env"
if [[ -z "$resolved_signing_identity" ]]; then
  resolved_signing_identity="$(developer_id_identity || true)"
  signing_identity_source="keychain"
fi

resolved_development_team="${GRIDOS_DEVELOPMENT_TEAM:-}"
development_team_source="env"
if [[ -z "$resolved_development_team" && -n "${development_team:-}" ]]; then
  resolved_development_team="$development_team"
  development_team_source="project"
fi
if [[ -z "$resolved_development_team" && -n "$resolved_signing_identity" ]]; then
  resolved_development_team="$(team_id_from_identity "$resolved_signing_identity")"
  development_team_source="codesigning_identity"
fi

if [[ -n "$resolved_development_team" ]]; then
  add_line "GRIDOS_DEVELOPMENT_TEAM=present"
  add_line "GRIDOS_DEVELOPMENT_TEAM_SOURCE=$development_team_source"
else
  add_line "GRIDOS_DEVELOPMENT_TEAM=missing"
  add_line "GRIDOS_DEVELOPMENT_TEAM_SOURCE=missing"
  missing_inputs+=("GRIDOS_DEVELOPMENT_TEAM")
fi

if [[ -n "$resolved_signing_identity" ]]; then
  add_line "GRIDOS_SIGNING_IDENTITY=present"
  add_line "GRIDOS_SIGNING_IDENTITY_SOURCE=$signing_identity_source"
else
  add_line "GRIDOS_SIGNING_IDENTITY=missing"
  add_line "GRIDOS_SIGNING_IDENTITY_SOURCE=missing"
  missing_inputs+=("GRIDOS_SIGNING_IDENTITY")
fi

env_presence_line GRIDOS_NOTARY_PROFILE missing_optional
env_presence_line GRIDOS_NOTARY_APPLE_ID missing_optional
env_presence_line GRIDOS_NOTARY_PASSWORD missing_optional
env_presence_line GRIDOS_NOTARY_TEAM_ID missing_optional
env_presence_line GRIDOS_NOTARY_KEY_ID missing_optional
env_presence_line GRIDOS_NOTARY_ISSUER_ID missing_optional
env_presence_line GRIDOS_NOTARY_KEY_PATH missing_optional

if notary_profile_present; then
  keychain_profile_status="$(notary_profile_status "$GRIDOS_NOTARY_PROFILE")"
  add_line "NOTARY_CREDENTIAL_MODE=keychain-profile"
  add_line "NOTARY_KEYCHAIN_PROFILE=$keychain_profile_status"
  if [[ "$keychain_profile_status" != "present" ]]; then
    missing_notary_inputs+=("notarytool_keychain_profile_$keychain_profile_status")
  fi
elif notary_apple_id_mode_present; then
  add_line "NOTARY_CREDENTIAL_MODE=apple-id"
elif notary_api_key_mode_present; then
  add_line "NOTARY_CREDENTIAL_MODE=api-key"
else
  add_line "NOTARY_CREDENTIAL_MODE=missing"
  missing_notary_inputs+=("GRIDOS_NOTARY_PROFILE")
  missing_notary_inputs+=("GRIDOS_NOTARY_APPLE_ID/GRIDOS_NOTARY_PASSWORD/GRIDOS_NOTARY_TEAM_ID")
  missing_notary_inputs+=("GRIDOS_NOTARY_KEY_ID/GRIDOS_NOTARY_ISSUER_ID/GRIDOS_NOTARY_KEY_PATH")
fi

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

if [[ "${#missing_inputs[@]}" -gt 0 || "${#missing_notary_inputs[@]}" -gt 0 ]]; then
  blocked_inputs="${missing_inputs[*]-} ${missing_notary_inputs[*]-}"
  blocked_inputs="${blocked_inputs# }"
  add_line "BETA_NOTARIZATION_BLOCKED $blocked_inputs"
else
  add_line "BETA_NOTARIZATION_READY"
fi

printf '%s\n' "${report_lines[@]}"

if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$EVIDENCE_DIR"
  printf '%s\n' "${report_lines[@]}" > "$REPORT_FILE"
fi

if [[ "$DRY_RUN" -eq 0 && ( "${#missing_tools[@]}" -gt 0 || "${#missing_inputs[@]}" -gt 0 || "${#missing_notary_inputs[@]}" -gt 0 ) ]]; then
  exit 1
fi
