# gridOS public GitHub readiness

Date: 2026-06-19
Last validated: 2026-06-19
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.12 GitHub publication.

The source-available proprietary repository posture is public and acceptable.
The 1.0.12 artifact is signed, notarized, stapled, Gatekeeper accepted, uploaded
to the public GitHub release, and covered by a signed Sparkle appcast that
matches raw `main`.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS after the 1.0.12 version bump.
- Pull request CI run `27837910031`: PASS for PR #5.
- GitHub Actions CI run `27838082157`: PASS on version bump commit `7b007d0`.
- GitHub Actions CI run `27838453986`: PASS on release-prep commit `5600ced`.
- `git diff --check`: PASS after the 1.0.12 release-script/doc evidence edits.
- Current public docs identify 1.0.12 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256:
  `b0cf33cbd020c45dbd359bffd8e1b59421a12a8980f6ef428ec2cd6b5ed77ff4`.
- ZIP SHA-256:
  `3ef677d2d96de9655360b3b7a1dc63617dce0a32df78cb0e1bd3f8a93e4fe914`.
- DMG app tree SHA-256:
  `bef75a3db4af2f16c17c6099cec9272fa4db1d0dadcbdc022c0f9f95a784e106`.
- ZIP extracted app tree SHA-256:
  `9db7babc3c89c2f267b1d03da707fbdbf6b5ddb62706b3ca4dcaf375c907604f`.
- `codesign --verify --deep --strict --verbose=2` against the app: PASS.
- `spctl --assess --type execute --verbose=4` against the app: PASS.
- `spctl -a -t open --context context:primary-signature -v` against the DMG:
  PASS.
- `xcrun stapler validate` against the DMG: PASS.
- `xcrun stapler validate` against the ZIP-extracted app: PASS.
- ZIP extraction with `ditto` preserved strict codesign, stapler validation, and
  Gatekeeper assessment: PASS.
- GitHub release asset readback matched the local DMG, ZIP, and appcast
  SHA-256 digests: PASS.

## Product Proof

- Local cross-pane app smoke: PASS. It copied selected output from a blocked
  first pane, created a second pane with Command-T, pasted a command into the
  second pane, and verified the blocked first pane remained untouched.
- TerminalCore tests cover cross-pane copy/paste, selected inactive-pane
  fallback, active-pane paste routing, clicked-pane focus routing, Command-T
  pane creation, and layout publication.

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

- `appcast.xml`: generated for `gridOS 1.0.12` build `20`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- Feed signature:
  `rrpdf2CrhuJyEa6m/LuXDvblVS99uQcDjQ6zjvv2dhWDSaOjH5Aust8O2GMNwXlU7H8/aHYLtTeXPZ9Y9MUtAQ==`.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.12-20-7b007d0.dmg`: PASS.
- DMG enclosure signature:
  `OHnHwZGcLRkp3NSyDhR7AZ5jkyw/N0vvO2I5h37Ef+VwVY6DGW+YcJZjPILgQs9u42KtYd067zbscli2aM0GDg==`.
- Appcast enclosure length `9022718` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `b0cf33cbd020c45dbd359bffd8e1b59421a12a8980f6ef428ec2cd6b5ed77ff4`.
- Raw `main` appcast fetched from GitHub matched the local `appcast.xml`: PASS.

## GitHub Release Readback

- Release URL: https://github.com/aaldere1/gridOS/releases/tag/v1.0.12
- Draft: false.
- Prerelease: false.
- Published at: 2026-06-19T16:54:57Z.
- DMG asset digest:
  `sha256:b0cf33cbd020c45dbd359bffd8e1b59421a12a8980f6ef428ec2cd6b5ed77ff4`.
- ZIP asset digest:
  `sha256:3ef677d2d96de9655360b3b7a1dc63617dce0a32df78cb0e1bd3f8a93e4fe914`.
- Appcast asset digest:
  `sha256:181679685fc48ab09ed0f9a47db9a87ac0f4e2ec4e013e9bbb9959b03addb771`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.11 to 1.0.12 remains useful
  validation when a separate clean Mac is available.
