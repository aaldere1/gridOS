# gridOS public GitHub readiness

Date: 2026-06-17
Last validated: 2026-06-17
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.9 GitHub publication.

The source-available proprietary repository posture is already public and
acceptable. The 1.0.9 artifact is signed, notarized, stapled, Gatekeeper
accepted, mounted from the final DMG for artifact proof, and covered by a signed
Sparkle appcast.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS after the 1.0.9 source commit.
- `git diff --check`: PASS after the 1.0.9 release-script/doc evidence edits.
- Current public docs now identify 1.0.9 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256: `e112a0d16c6e350579cee44c475bc9e0916ab2a4768f7c7b3fb48cc4a2048633`.
- ZIP SHA-256: `f211ecef83d26f09b98258e1d40884c6dfb8382e928143464fe04e4d42e40f6e`.
- Extracted app tree SHA-256: `5215282e064aa3305a964bdc2acfa0da2568649c4bc0065c5210a07676acdb08`.
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

- `appcast.xml`: generated for `gridOS 1.0.9` build `17`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- Feed signature:
  `g4+jOhanczeBHZFAjhBB6pskeZy76YmafZn3G7MZphMRfPLdsH/sbqRwxMh/5gaVNJFQjPH5zXnNAjbs6sQZAA==`.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.9-17-2d2fe8d.dmg`: PASS.
- DMG enclosure signature:
  `sSa4rWUS6+Ba+9MVueL0vASK5yOqgY1NY1nwWWEJ6i6NIcoUwU3tHS4Q2w7Pjzgn/9JE81KEKPSVr1KdEHWTCg==`.
- Appcast enclosure length `9051257` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `e112a0d16c6e350579cee44c475bc9e0916ab2a4768f7c7b3fb48cc4a2048633`.

## Remaining External Validation

- Publish the GitHub release assets and record asset readback proof.
- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.8 to 1.0.9 remains useful
  external validation when a separate clean Mac is available.
