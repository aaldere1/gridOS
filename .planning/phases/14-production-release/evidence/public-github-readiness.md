# gridOS public GitHub readiness

Date: 2026-06-18
Last validated: 2026-06-18
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.11 GitHub publication.

The source-available proprietary repository posture is public and acceptable.
The 1.0.11 artifact is signed, notarized, stapled, Gatekeeper accepted, mounted
from the final DMG for artifact proof, uploaded to the public GitHub release,
and covered by a signed Sparkle appcast that matches raw `main`.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS after the 1.0.11 source commit.
- Pull request CI run `27760536472`: PASS for PR #4.
- GitHub Actions CI run `27761563976`: PASS on release-prep commit `6f25f10`.
- `git diff --check`: PASS after the 1.0.11 release-script/doc evidence edits.
- Current public docs identify 1.0.11 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256:
  `1712d5b34d9b6edf233214a2b927bb7c0cb55838dfe4e9d42c95dcfcee80c9d6`.
- ZIP SHA-256:
  `c956322ff601d6538d748cae1a8025a646d488d079df8703cc5e99b0cb0ebf4d`.
- DMG app tree SHA-256:
  `d03ad0b435427dd7b084f285d68f61c7ca3ab75487463d6ea2475b480a3fa29b`.
- ZIP extracted app tree SHA-256:
  `78bc7a7749805c64043bce21bf1fea922bcdc3c5164bfe95b6bb3f5ae8cc816c`.
- `codesign --verify --deep --strict --verbose=2` against the mounted app:
  PASS.
- `spctl --assess --type execute --verbose=4` against the mounted app: PASS,
  accepted from Notarized Developer ID.
- `spctl -a -t open --context context:primary-signature -v` against the DMG:
  PASS, accepted from Notarized Developer ID.
- `xcrun stapler validate` against the DMG: PASS.
- `xcrun stapler validate` against the mounted app: PASS.
- DMG layout contains `gridOS.app` and an `Applications -> /Applications`
  symlink.
- ZIP extraction with `ditto` preserved strict codesign, stapler validation, and
  Gatekeeper assessment: PASS.
- GitHub release asset readback matched the local DMG, ZIP, and appcast
  SHA-256 digests: PASS.

## Visual Proof

- Public README imagery intentionally avoids the main terminal view because the
  live terminal correctly shows the local user/machine prompt.
- Public HUD screenshot
  `docs/assets/readme/screenshots/gridos-hud-signal.png` shows the Redline HUD
  Signal rail without username, terminal prompt, local path, or private content.
- Public AI Command Helper screenshot
  `docs/assets/readme/screenshots/gridos-command-helper.png` shows the
  screenshot drop zone and local OCR messaging without username, terminal
  prompt, local path, or private content.
- Public Settings screenshot
  `docs/assets/readme/screenshots/gridos-settings-updates.png` shows Software
  Updates controls, automatic checks, automatic install, signed GitHub release
  asset copy, and system profiling off copy without username, terminal prompt,
  local path, or private content.

## Sparkle Appcast

- `appcast.xml`: generated for `gridOS 1.0.11` build `19`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- Feed signature:
  `VYsgZ0IFL8Znq0e8hAvm5MlKg//RZleUhidCuw0ZtXMZ8QhujbDkTqZV/fGCCcEWxRl5fsMmmpp99UY0SUiQCg==`.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.11-19-a3fb5ec.dmg`: PASS.
- DMG enclosure signature:
  `DsLJWqsdISLnJ0i4+fHpyat3qStQlBcWdIUbym+w4YoRu0gpOOVluZoIhnXRLRi0t0L5aUmv260U1ZjvrBL5Dw==`.
- Appcast enclosure length `9014868` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `1712d5b34d9b6edf233214a2b927bb7c0cb55838dfe4e9d42c95dcfcee80c9d6`.
- Raw `main` appcast fetched from GitHub matched the local `appcast.xml`: PASS.

## GitHub Release Readback

- Release URL: https://github.com/aaldere1/gridOS/releases/tag/v1.0.11
- Draft: false.
- Prerelease: false.
- Published at: 2026-06-18T13:09:31Z.
- DMG asset digest:
  `sha256:1712d5b34d9b6edf233214a2b927bb7c0cb55838dfe4e9d42c95dcfcee80c9d6`.
- ZIP asset digest:
  `sha256:c956322ff601d6538d748cae1a8025a646d488d079df8703cc5e99b0cb0ebf4d`.
- Appcast asset digest:
  `sha256:cdc032fbb1c360f93a39fb757122f84c6f272cedd0b9b353eb1b242cf2ef1e06`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.10 to 1.0.11 remains useful
  validation when a separate clean Mac is available.
