#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/write-sparkle-appcast.sh path/to/gridOS-version-build-commit.dmg

Generates appcast.xml for Sparkle automatic updates using the gridOS EdDSA
signing key stored in Keychain.

Environment:
  GRIDOS_SPARKLE_ACCOUNT              Keychain account (default: com.aaldere1.gridos)
  GRIDOS_SPARKLE_OUTPUT               Appcast path (default: appcast.xml)
  GRIDOS_SPARKLE_DOWNLOAD_URL_PREFIX  Override release download URL prefix
  GRIDOS_SPARKLE_RELEASE_LINK         Override release page link
  GRIDOS_SPARKLE_PUBLIC_KEY           Expected SUPublicEDKey value
USAGE
}

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  [[ $# -eq 1 ]] && exit 0
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_PATH="$1"
ARTIFACT_BASENAME="$(basename "$ARTIFACT_PATH")"
ACCOUNT="${GRIDOS_SPARKLE_ACCOUNT:-com.aaldere1.gridos}"
OUTPUT_PATH_INPUT="${GRIDOS_SPARKLE_OUTPUT:-appcast.xml}"
EXPECTED_PUBLIC_KEY="${GRIDOS_SPARKLE_PUBLIC_KEY:-nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=}"

if [[ ! -f "$ARTIFACT_PATH" ]]; then
  echo "SPARKLE_APPCAST_BLOCKED: artifact missing: $ARTIFACT_PATH" >&2
  exit 1
fi

if [[ "$ARTIFACT_BASENAME" =~ ^gridOS-([0-9]+([.][0-9]+)*)-([0-9]+)-([0-9a-f]+)[.]dmg$ ]]; then
  VERSION="${BASH_REMATCH[1]}"
  BUILD="${BASH_REMATCH[3]}"
else
  echo "SPARKLE_APPCAST_BLOCKED: artifact name must look like gridOS-1.0.6-14-abcdef0.dmg" >&2
  exit 1
fi

if [[ "$OUTPUT_PATH_INPUT" = /* ]]; then
  OUTPUT_PATH="$OUTPUT_PATH_INPUT"
else
  OUTPUT_PATH="$ROOT_DIR/$OUTPUT_PATH_INPUT"
fi

RELEASE_TAG="v$VERSION"
DOWNLOAD_URL_PREFIX="${GRIDOS_SPARKLE_DOWNLOAD_URL_PREFIX:-https://github.com/aaldere1/gridOS/releases/download/$RELEASE_TAG/}"
RELEASE_LINK="${GRIDOS_SPARKLE_RELEASE_LINK:-https://github.com/aaldere1/gridOS/releases/tag/$RELEASE_TAG}"
RELEASE_NOTES="$ROOT_DIR/docs/release-notes/$RELEASE_TAG.md"
MINIMUM_SYSTEM_VERSION="14.0"
ARCHIVE_INFO_PLIST="$ROOT_DIR/build/release/production/gridOS.xcarchive/Products/Applications/gridOS.app/Contents/Info.plist"

if [[ -f "$ARCHIVE_INFO_PLIST" ]]; then
  if plist_minimum_version="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$ARCHIVE_INFO_PLIST" 2>/dev/null)"; then
    MINIMUM_SYSTEM_VERSION="$plist_minimum_version"
  fi
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

python3 - "$ARTIFACT_PATH" "$OUTPUT_PATH" "$ACCOUNT" "$EXPECTED_PUBLIC_KEY" \
  "$VERSION" "$BUILD" "$DOWNLOAD_URL_PREFIX" "$RELEASE_LINK" "$RELEASE_NOTES" \
  "$MINIMUM_SYSTEM_VERSION" <<'PY'
import base64
import email.utils
import html
import pathlib
import subprocess
import sys
import urllib.parse

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ed25519

(
    artifact_path,
    output_path,
    account,
    expected_public_key,
    version,
    build,
    download_url_prefix,
    release_link,
    release_notes_path,
    minimum_system_version,
) = sys.argv[1:]

artifact = pathlib.Path(artifact_path)
output = pathlib.Path(output_path)
release_notes = pathlib.Path(release_notes_path)

try:
    secret_b64 = subprocess.check_output(
        [
            "security",
            "find-generic-password",
            "-w",
            "-s",
            "https://sparkle-project.org",
            "-a",
            account,
        ],
        stderr=subprocess.PIPE,
        text=True,
    ).strip()
except subprocess.CalledProcessError as exc:
    stderr = exc.stderr.strip()
    detail = f": {stderr}" if stderr else ""
    raise SystemExit(f"SPARKLE_APPCAST_BLOCKED: unable to read signing key{detail}") from exc

try:
    secret = base64.b64decode(secret_b64, validate=True)
except Exception as exc:
    raise SystemExit("SPARKLE_APPCAST_BLOCKED: signing key is not valid base64") from exc

if len(secret) != 32:
    raise SystemExit(
        f"SPARKLE_APPCAST_BLOCKED: expected 32-byte Ed25519 seed, got {len(secret)} bytes"
    )

private_key = ed25519.Ed25519PrivateKey.from_private_bytes(secret)
public_key = private_key.public_key().public_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PublicFormat.Raw,
)
derived_public_key = base64.b64encode(public_key).decode("ascii")

if expected_public_key and derived_public_key != expected_public_key:
    raise SystemExit("SPARKLE_APPCAST_BLOCKED: signing key does not match SUPublicEDKey")

artifact_data = artifact.read_bytes()
artifact_signature = base64.b64encode(private_key.sign(artifact_data)).decode("ascii")
artifact_length = len(artifact_data)

notes_text = release_notes.read_text(encoding="utf-8") if release_notes.exists() else ""
safe_cdata_notes = notes_text.replace("]]>", "]]]]><![CDATA[>")
escaped_link = html.escape(release_link, quote=True)
escaped_version = html.escape(version, quote=True)
escaped_build = html.escape(build, quote=True)
escaped_minimum_system_version = html.escape(minimum_system_version, quote=True)
escaped_download_url = html.escape(
    urllib.parse.urljoin(download_url_prefix, urllib.parse.quote(artifact.name)),
    quote=True,
)
pub_date = email.utils.formatdate(artifact.stat().st_mtime, usegmt=True)

content = f"""<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>gridOS Updates</title>
        <link>{escaped_link}</link>
        <description>Signed gridOS direct-download updates.</description>
        <language>en</language>
        <item>
            <title>gridOS {escaped_version}</title>
            <link>{escaped_link}</link>
            <sparkle:version>{escaped_build}</sparkle:version>
            <sparkle:shortVersionString>{escaped_version}</sparkle:shortVersionString>
            <description sparkle:format="markdown"><![CDATA[{safe_cdata_notes}]]></description>
            <pubDate>{pub_date}</pubDate>
            <enclosure url="{escaped_download_url}" length="{artifact_length}" type="application/octet-stream" sparkle:edSignature="{artifact_signature}" />
            <sparkle:minimumSystemVersion>{escaped_minimum_system_version}</sparkle:minimumSystemVersion>
        </item>
    </channel>
</rss>
"""

content_bytes = content.encode("utf-8")
feed_signature = base64.b64encode(private_key.sign(content_bytes)).decode("ascii")
public_key_obj = ed25519.Ed25519PublicKey.from_public_bytes(public_key)
public_key_obj.verify(base64.b64decode(artifact_signature), artifact_data)
public_key_obj.verify(base64.b64decode(feed_signature), content_bytes)

signed_content = (
    content
    + "<!-- sparkle-signatures:\n"
    + f"edSignature: {feed_signature}\n"
    + f"length: {len(content_bytes)}\n"
    + "-->\n"
)
output.write_text(signed_content, encoding="utf-8")
PY

printf 'SPARKLE_APPCAST_WRITTEN %s\n' "$OUTPUT_PATH"
