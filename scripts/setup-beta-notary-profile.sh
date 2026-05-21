#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/setup-beta-notary-profile.sh profile-name

Creates or updates a notarytool Keychain profile for Phase 12 Beta.

Apple ID mode:
  GRIDOS_NOTARY_APPLE_ID='apple-id@example.com' \
  GRIDOS_NOTARY_TEAM_ID='TEAMID1234' \
  scripts/setup-beta-notary-profile.sh gridOS-beta

The script intentionally does not read GRIDOS_NOTARY_PASSWORD. notarytool will
prompt securely for the app-specific password so it does not appear in shell
history, process arguments, logs, or committed evidence.

App Store Connect API key mode:
  GRIDOS_NOTARY_KEY_PATH='/path/to/AuthKey_ABC123DEFG.p8' \
  GRIDOS_NOTARY_KEY_ID='ABC123DEFG' \
  GRIDOS_NOTARY_ISSUER_ID='00000000-0000-0000-0000-000000000000' \
  scripts/setup-beta-notary-profile.sh gridOS-beta
USAGE
}

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  [[ $# -eq 1 ]] && exit 0
  exit 2
fi

PROFILE_NAME="$1"

if [[ -z "$PROFILE_NAME" || "$PROFILE_NAME" == -* ]]; then
  echo "NOTARY_PROFILE_SETUP_BLOCKED: profile name is required" >&2
  exit 2
fi

if [[ -n "${GRIDOS_NOTARY_KEY_PATH:-}" || -n "${GRIDOS_NOTARY_KEY_ID:-}" || -n "${GRIDOS_NOTARY_ISSUER_ID:-}" ]]; then
  missing=()
  [[ -z "${GRIDOS_NOTARY_KEY_PATH:-}" ]] && missing+=("GRIDOS_NOTARY_KEY_PATH")
  [[ -z "${GRIDOS_NOTARY_KEY_ID:-}" ]] && missing+=("GRIDOS_NOTARY_KEY_ID")
  [[ -z "${GRIDOS_NOTARY_ISSUER_ID:-}" ]] && missing+=("GRIDOS_NOTARY_ISSUER_ID")

  if [[ "${#missing[@]}" -gt 0 ]]; then
    printf 'NOTARY_PROFILE_SETUP_BLOCKED %s\n' "${missing[*]}" >&2
    exit 1
  fi

  xcrun notarytool store-credentials "$PROFILE_NAME" \
    --key "$GRIDOS_NOTARY_KEY_PATH" \
    --key-id "$GRIDOS_NOTARY_KEY_ID" \
    --issuer "$GRIDOS_NOTARY_ISSUER_ID"

  printf 'NOTARY_PROFILE_READY %s\n' "$PROFILE_NAME"
  printf 'NEXT GRIDOS_NOTARY_PROFILE=%s scripts/check-beta-notary-profile.sh\n' "$PROFILE_NAME"
  exit 0
fi

missing=()
[[ -z "${GRIDOS_NOTARY_APPLE_ID:-}" ]] && missing+=("GRIDOS_NOTARY_APPLE_ID")
[[ -z "${GRIDOS_NOTARY_TEAM_ID:-}" ]] && missing+=("GRIDOS_NOTARY_TEAM_ID")

if [[ "${#missing[@]}" -gt 0 ]]; then
  printf 'NOTARY_PROFILE_SETUP_BLOCKED %s\n' "${missing[*]}" >&2
  exit 1
fi

xcrun notarytool store-credentials "$PROFILE_NAME" \
  --apple-id "$GRIDOS_NOTARY_APPLE_ID" \
  --team-id "$GRIDOS_NOTARY_TEAM_ID"

printf 'NOTARY_PROFILE_READY %s\n' "$PROFILE_NAME"
printf 'NEXT GRIDOS_NOTARY_PROFILE=%s scripts/check-beta-notary-profile.sh\n' "$PROFILE_NAME"
