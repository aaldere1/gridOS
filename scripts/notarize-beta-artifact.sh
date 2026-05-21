#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/notarize-beta-artifact.sh path/to/gridOS.dmg-or-zip-or-app

Submits a Beta artifact to Apple notarization, waits for completion, staples
supported artifact types, and writes sanitized evidence.
USAGE
}

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  [[ $# -eq 1 ]] && exit 0
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/.planning/phases/12-beta/evidence"
REPORT_FILE="$EVIDENCE_DIR/beta-notarization.md"
LOG_FILE="$EVIDENCE_DIR/beta-notarization-log.json"
INPUT_PATH="$1"
SUBMIT_PLIST=""

cleanup() {
  if [[ -n "$SUBMIT_PLIST" && -f "$SUBMIT_PLIST" ]]; then
    rm -f "$SUBMIT_PLIST"
  fi
}
trap cleanup EXIT

absolute_path() {
  local path="$1"
  local dir
  local base
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  printf '%s/%s' "$(cd "$dir" && pwd -P)" "$base"
}

fail_if_planning_path() {
  local path="$1"
  local planning_dir
  planning_dir="$(cd "$ROOT_DIR/.planning" && pwd -P)"
  if [[ "$path" == "$planning_dir" || "$path" == "$planning_dir/"* ]]; then
    echo "BETA_NOTARIZATION_BLOCKED: pass artifacts from a local output directory, not .planning" >&2
    exit 1
  fi
}

plist_field() {
  local plist="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true
}

sanitize_file() {
  local input="$1"
  local output="$2"
  sed -E \
    -e "s#${HOME}#[home]#g" \
    -e "s#${ROOT_DIR}#[repo]#g" \
    -e 's#([Pp]assword|[Tt]oken|[Kk]ey)[^",} ]*#\1=[redacted]#g' \
    "$input" > "$output"
}

supports_staple() {
  case "$1" in
    *.dmg|*.pkg|*.app|*.app/)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

notary_args=()
credential_mode=""
credential_blocker=""

if [[ -n "${GRIDOS_NOTARY_PROFILE:-}" ]]; then
  credential_mode="keychain-profile"
  notary_args=(--keychain-profile "$GRIDOS_NOTARY_PROFILE")
elif [[ -n "${GRIDOS_NOTARY_APPLE_ID:-}" && -n "${GRIDOS_NOTARY_PASSWORD:-}" && -n "${GRIDOS_NOTARY_TEAM_ID:-}" ]]; then
  credential_mode="apple-id"
  notary_args=(--apple-id "$GRIDOS_NOTARY_APPLE_ID" --password "$GRIDOS_NOTARY_PASSWORD" --team-id "$GRIDOS_NOTARY_TEAM_ID")
elif [[ -n "${GRIDOS_NOTARY_KEY_ID:-}" && -n "${GRIDOS_NOTARY_ISSUER_ID:-}" && -n "${GRIDOS_NOTARY_KEY_PATH:-}" ]]; then
  credential_mode="api-key"
  notary_args=(--key "$GRIDOS_NOTARY_KEY_PATH" --key-id "$GRIDOS_NOTARY_KEY_ID" --issuer "$GRIDOS_NOTARY_ISSUER_ID")
else
  credential_mode="missing"
  credential_blocker="GRIDOS_NOTARY_PROFILE GRIDOS_NOTARY_APPLE_ID/GRIDOS_NOTARY_PASSWORD/GRIDOS_NOTARY_TEAM_ID GRIDOS_NOTARY_KEY_ID/GRIDOS_NOTARY_ISSUER_ID/GRIDOS_NOTARY_KEY_PATH"
fi

mkdir -p "$EVIDENCE_DIR"

if [[ ! -e "$INPUT_PATH" ]]; then
  {
    printf '# Beta notarization\n\n'
    printf -- '- Timestamp UTC: %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- Artifact basename: missing\n'
    printf -- '- Credential mode: %s\n' "$credential_mode"
    printf -- '- Result: BLOCKED\n'
    printf -- '- Blocker: artifact missing\n'
  } > "$REPORT_FILE"
  echo "BETA_NOTARIZATION_BLOCKED artifact_missing" >&2
  exit 1
fi

INPUT_ABS="$(absolute_path "$INPUT_PATH")"
fail_if_planning_path "$INPUT_ABS"
ARTIFACT_BASENAME="$(basename "$INPUT_ABS")"

if [[ -n "$credential_blocker" ]]; then
  {
    printf '# Beta notarization\n\n'
    printf -- '- Timestamp UTC: %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- Artifact basename: %s\n' "$ARTIFACT_BASENAME"
    printf -- '- Credential mode: missing\n'
    printf -- '- Result: BLOCKED\n'
    printf -- '- Blocker: BETA_NOTARIZATION_BLOCKED %s\n' "$credential_blocker"
  } > "$REPORT_FILE"
  printf 'BETA_NOTARIZATION_BLOCKED %s\n' "$credential_blocker" >&2
  exit 1
fi

SUBMIT_PLIST="$(mktemp "${TMPDIR:-/tmp}/gridos-notary-submit.XXXXXX.plist")"
SUBMIT_STATUS="not_submitted"
SUBMISSION_ID=""
SUBMISSION_MESSAGE=""
STAPLE_STATUS="not_attempted"
VALIDATE_STATUS="not_attempted"

if xcrun notarytool submit "${notary_args[@]}" --wait --no-progress --output-format plist "$INPUT_ABS" > "$SUBMIT_PLIST"; then
  SUBMISSION_ID="$(plist_field "$SUBMIT_PLIST" id)"
  SUBMIT_STATUS="$(plist_field "$SUBMIT_PLIST" status)"
  SUBMISSION_MESSAGE="$(plist_field "$SUBMIT_PLIST" message)"
else
  SUBMISSION_ID="$(plist_field "$SUBMIT_PLIST" id)"
  SUBMIT_STATUS="$(plist_field "$SUBMIT_PLIST" status)"
  SUBMISSION_MESSAGE="$(plist_field "$SUBMIT_PLIST" message)"
  [[ -z "$SUBMIT_STATUS" ]] && SUBMIT_STATUS="submit_failed"
fi

if [[ -n "$SUBMISSION_ID" && "$SUBMIT_STATUS" != "Accepted" ]]; then
  TMP_LOG="$(mktemp "${TMPDIR:-/tmp}/gridos-notary-log.XXXXXX.json")"
  if xcrun notarytool log "${notary_args[@]}" "$SUBMISSION_ID" "$TMP_LOG" >/dev/null 2>&1; then
    sanitize_file "$TMP_LOG" "$LOG_FILE"
  fi
  rm -f "$TMP_LOG"
fi

if [[ "$SUBMIT_STATUS" == "Accepted" ]] && supports_staple "$INPUT_ABS"; then
  if xcrun stapler staple "$INPUT_ABS" >/dev/null 2>&1; then
    STAPLE_STATUS="PASS"
  else
    STAPLE_STATUS="FAIL"
  fi

  if xcrun stapler validate "$INPUT_ABS" >/dev/null 2>&1; then
    VALIDATE_STATUS="PASS"
  else
    VALIDATE_STATUS="FAIL"
  fi
elif [[ "$SUBMIT_STATUS" == "Accepted" ]]; then
  STAPLE_STATUS="not_supported_for_artifact"
  VALIDATE_STATUS="not_supported_for_artifact"
fi

if [[ "$SUBMIT_STATUS" == "Accepted" && "$STAPLE_STATUS" != "FAIL" && "$VALIDATE_STATUS" != "FAIL" ]]; then
  RESULT="PASS"
else
  RESULT="FAIL"
fi

{
  printf '# Beta notarization\n\n'
  printf -- '- Timestamp UTC: %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  printf -- '- Artifact basename: %s\n' "$ARTIFACT_BASENAME"
  printf -- '- Credential mode: %s\n' "$credential_mode"
  printf -- '- Notary command: xcrun notarytool submit --wait --no-progress --output-format plist\n'
  printf -- '- Submission ID: %s\n' "${SUBMISSION_ID:-unavailable}"
  printf -- '- Submission status: %s\n' "${SUBMIT_STATUS:-unavailable}"
  printf -- '- Submission message: %s\n' "${SUBMISSION_MESSAGE:-unavailable}"
  printf -- '- Staple command: xcrun stapler staple\n'
  printf -- '- Staple status: %s\n' "$STAPLE_STATUS"
  printf -- '- Validate command: xcrun stapler validate\n'
  printf -- '- Validate status: %s\n' "$VALIDATE_STATUS"
  printf -- '- Failure log: %s\n' "$([[ -f "$LOG_FILE" ]] && printf 'beta-notarization-log.json' || printf 'not_applicable')"
  printf -- '- Result: %s\n' "$RESULT"
} > "$REPORT_FILE"

printf 'BETA_NOTARIZATION_RESULT %s\n' "$RESULT"
printf 'BETA_NOTARIZATION_REPORT %s\n' "$REPORT_FILE"

if [[ "$RESULT" != "PASS" ]]; then
  exit 1
fi
