#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: GRIDOS_NOTARY_PROFILE=profile-name scripts/check-beta-notary-profile.sh

Checks that a notarytool Keychain profile can authenticate and writes sanitized
presence-only evidence to:
  .planning/phases/12-beta/evidence/beta-notary-profile-check.txt
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/.planning/phases/12-beta/evidence"
REPORT_FILE="$EVIDENCE_DIR/beta-notary-profile-check.txt"
PROFILE_NAME="${GRIDOS_NOTARY_PROFILE:-}"
TMP_OUTPUT=""

cleanup() {
  if [[ -n "$TMP_OUTPUT" && -f "$TMP_OUTPUT" ]]; then
    rm -f "$TMP_OUTPUT"
  fi
}
trap cleanup EXIT

mkdir -p "$EVIDENCE_DIR"

if [[ -z "$PROFILE_NAME" ]]; then
  {
    printf 'GRIDOS_BETA_NOTARY_PROFILE_CHECK\n'
    printf 'TIMESTAMP_UTC=%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    printf 'GRIDOS_NOTARY_PROFILE=missing\n'
    printf 'RESULT=BLOCKED\n'
    printf 'BLOCKER=GRIDOS_NOTARY_PROFILE\n'
  } > "$REPORT_FILE"
  echo "NOTARY_PROFILE_CHECK_BLOCKED GRIDOS_NOTARY_PROFILE" >&2
  exit 1
fi

TMP_OUTPUT="$(mktemp "${TMPDIR:-/tmp}/gridos-notary-profile-check.XXXXXX.json")"

if xcrun notarytool history --keychain-profile "$PROFILE_NAME" --output-format json --no-progress > "$TMP_OUTPUT" 2>/dev/null; then
  {
    printf 'GRIDOS_BETA_NOTARY_PROFILE_CHECK\n'
    printf 'TIMESTAMP_UTC=%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    printf 'GRIDOS_NOTARY_PROFILE=present\n'
    printf 'NOTARY_HISTORY=available\n'
    printf 'RESULT=PASS\n'
  } > "$REPORT_FILE"
  printf 'NOTARY_PROFILE_CHECK PASS\n'
else
  {
    printf 'GRIDOS_BETA_NOTARY_PROFILE_CHECK\n'
    printf 'TIMESTAMP_UTC=%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    printf 'GRIDOS_NOTARY_PROFILE=present\n'
    printf 'NOTARY_HISTORY=unavailable\n'
    printf 'RESULT=BLOCKED\n'
    printf 'BLOCKER=notarytool_history_authentication\n'
  } > "$REPORT_FILE"
  echo "NOTARY_PROFILE_CHECK_BLOCKED notarytool_history_authentication" >&2
  exit 1
fi
