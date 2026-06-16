# gridOS public GitHub readiness

Date: 2026-06-16
Last validated: 2026-06-16
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.7 GitHub publication.

The source-available proprietary repository posture is already public and
acceptable. The 1.0.7 artifact is signed, notarized, stapled, Gatekeeper
accepted, mounted from the final DMG for artifact proof, and covered by a signed
Sparkle appcast.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS after the 1.0.7 screenshot-drop and helper
  layout changes.
- `git diff --check`: PASS after the 1.0.7 release-script/doc evidence edits.
- Current public docs now identify 1.0.7 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256: `415e2da75bcffdae254db65b9948e4953f8e1ab84a5587aff456d0694e8f3e6e`.
- ZIP SHA-256: `75337900bf9ff24b0372585022886bcbbe0e978bb5bbd9cfcf14853fe9219fb7`.
- Extracted app tree SHA-256: `52cdb2086fe4ac29d430a2d5919912621e261afd3a1e9f803ed3c630a99ab8f6`.
- `codesign --verify --deep --strict --verbose=2` against the mounted app:
  PASS.
- `spctl --assess --type execute --verbose=4` against the mounted app: PASS,
  accepted from Notarized Developer ID.
- `spctl -a -t open --context context:primary-signature -v` against the DMG:
  PASS, accepted from Notarized Developer ID.
- `xcrun stapler validate` against the DMG: PASS.
- DMG layout contains `gridOS.app` and an `Applications -> /Applications`
  symlink.
- ZIP extraction with `ditto` preserved strict codesign and Gatekeeper
  assessment: PASS.

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

- `appcast.xml`: generated for `gridOS 1.0.7` build `15`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.7-15-8a1d12e.dmg`: PASS.
- Appcast enclosure length `8917838` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `415e2da75bcffdae254db65b9948e4953f8e1ab84a5587aff456d0694e8f3e6e`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.6 to 1.0.7 remains useful
  external validation when a separate clean Mac is available.
