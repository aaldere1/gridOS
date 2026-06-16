# gridOS public GitHub readiness

Date: 2026-06-16
Last validated: 2026-06-16
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.8 GitHub publication.

The source-available proprietary repository posture is already public and
acceptable. The 1.0.8 artifact is signed, notarized, stapled, Gatekeeper
accepted, mounted from the final DMG for artifact proof, and covered by a signed
Sparkle appcast.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- Direct `xcodebuild build test`: PASS after the 1.0.8 terminal jitter and
  pasteboard shortcut changes.
- `scripts/ci-build-test.sh`: PASS after the 1.0.8 release commit.
- `git diff --check`: PASS after the 1.0.8 release-script/doc evidence edits.
- Current public docs now identify 1.0.8 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256: `6884374556bb43ed2895ab9ae2a0486309d52042e069deb28b9d49e88a08e346`.
- ZIP SHA-256: `34e02e501362e0fcd797987f85663b980827300238eb9801e05123e9f0d7c1e2`.
- Extracted app tree SHA-256: `6ddef1c6e063ca7c4abe143f658f459e9b72793ae99f9b9df0c8d95af469b513`.
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

- `appcast.xml`: generated for `gridOS 1.0.8` build `16`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- Feed signature:
  `8/jY42AE8dUrnVUWsB1LDix435EWYhplctNpo/egXW+XuYeU0xxKp/2Qn5HMWt7z3ELCzIcdx5IGn243Qv/gCg==`.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.8-16-c60fecb.dmg`: PASS.
- DMG enclosure signature:
  `YWoHB3TSqIDGxRcCEE8GISHa4xbwAHVYJXtq6JhEep5Zmdc2SzaNThSjyHltxJHYqv145A3xEyXeRiFwgDTyBg==`.
- Appcast enclosure length `8913473` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `6884374556bb43ed2895ab9ae2a0486309d52042e069deb28b9d49e88a08e346`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.7 to 1.0.8 remains useful
  external validation when a separate clean Mac is available.
