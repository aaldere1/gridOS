# gridOS public GitHub readiness

Date: 2026-06-15
Last validated: 2026-06-16
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.6 GitHub publication.

The source-available proprietary repository posture is already public and
acceptable. The 1.0.6 artifact is signed, notarized, stapled, Gatekeeper
accepted, visually launch-smoked from the mounted DMG path, and covered by a
signed Sparkle appcast.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS on Xcode 26.5 after the appcast,
  release-script, and release-evidence edits.
- `git diff --check`: PASS after the 1.0.6 release-script/doc evidence edits.
- Current public docs now identify 1.0.6 as the current release candidate.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256: `cf6e01770e43b94783fefa25493da01f2471b961280334f63fe804568a1fe9c1`.
- ZIP SHA-256: `69e9187ef4af85f3428b76ded72eb2eb676ead3e690b5ec1c1cc9d5207c72e21`.
- `codesign --verify --deep --strict --verbose=2` against the mounted app:
  PASS.
- `spctl --assess --type execute --verbose=4` against the mounted app: PASS,
  accepted from Notarized Developer ID.
- `spctl -a -t open --context context:primary-signature -v` against the DMG:
  PASS, accepted from Notarized Developer ID.
- `xcrun stapler validate` against the DMG: PASS.
- DMG layout contains `gridOS.app` and an `Applications -> /Applications`
  symlink.
- DMG has no quarantine xattr; only Finder/disk-image checksum metadata was
  present.
- ZIP extraction with `ditto` preserved strict codesign and Gatekeeper
  assessment: PASS.

## Computer Use Proof

- Mounted `gridOS-1.0.6-14-edda1ee.dmg` read-only at a temporary `/tmp`
  mountpoint.
- Computer Use inspected `/tmp/gridos-1.0.6-ui.XY0nxW/gridOS.app` and confirmed
  visible `v1.0.6`, terminal workspace, pane controls, right-rail signal, and
  system metrics.
- Public README imagery intentionally avoids the main terminal view because the
  live terminal correctly shows the local user/machine prompt.
- Public Settings screenshot
  `docs/assets/readme/screenshots/gridos-settings-updates.png` shows Software
  Updates controls, automatic checks, automatic install, signed GitHub release
  asset copy, and system profiling off copy without username, terminal prompt,
  local path, or private content.

## Sparkle Appcast

- `appcast.xml`: generated for `gridOS 1.0.6` build `14`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.6-14-edda1ee.dmg`: PASS.
- Appcast enclosure length `8746890` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `cf6e01770e43b94783fefa25493da01f2471b961280334f63fe804568a1fe9c1`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.6 to the next release remains
  useful external validation when a separate clean Mac is available.
