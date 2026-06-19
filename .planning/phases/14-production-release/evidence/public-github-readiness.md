# gridOS public GitHub readiness

Date: 2026-06-19
Last validated: 2026-06-19
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.15 GitHub publication.

The source-available proprietary repository posture is public and acceptable.
The 1.0.15 artifact is signed, notarized, stapled, Gatekeeper accepted,
uploaded to the public GitHub release, and covered by a signed Sparkle appcast
that matches raw `main`.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS after the 1.0.15 version bump.
- Pull request CI run `27842828065`: PASS for PR #8.
- GitHub Actions CI run `27842904901`: PASS on PR #8 merge commit `c47a0aa`.
- GitHub Actions CI run `27842978804`: PASS on version bump commit `f7b51bc`.
- GitHub Actions CI run `27843486220`: PASS on release-prep commit `5014593`.
- `git diff --check`: PASS after the 1.0.15 release-script/doc evidence edits.
- Current public docs identify 1.0.15 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256:
  `92f6a0fd0f74b5fdae70b1cdb390e3846dd3020555ebe01a312ea459252b1593`.
- ZIP SHA-256:
  `395df75adbc9f8487cb59a6e24aba0ae1467ea5eb30d56817679e1c14fe4843b`.
- DMG app tree SHA-256:
  `eb5a56c3f0d56eb5c39388955218a752c60cae275c567ef1ce7c2c148885a77d`.
- ZIP extracted app tree SHA-256:
  `eb5a56c3f0d56eb5c39388955218a752c60cae275c567ef1ce7c2c148885a77d`.
- `codesign --verify --deep --strict --verbose=2` against the app: PASS.
- `spctl --assess --type execute --verbose=4` against the app: PASS.
- `spctl -a -t open --context context:primary-signature -v` against the DMG:
  PASS.
- `xcrun stapler validate` against the DMG: PASS.
- `xcrun stapler validate` against the ZIP-extracted app: PASS.
- ZIP extraction with `ditto` preserved strict codesign, stapler validation, and
  Gatekeeper assessment: PASS.

## Product Proof

- Local pane-to-pane selected-text copy/paste smoke: PASS. It copied selected
  text from pane 1, moved to pane 2, pasted, and visibly landed the copied text
  in pane 2.
- TerminalCore tests cover source-pane paste, source-pane Select All,
  source-pane copy priority, cross-pane copy/paste, selected inactive-pane
  fallback, active-pane menu routing, clicked-pane focus routing, Command-T
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

- `appcast.xml`: generated for `gridOS 1.0.15` build `23`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- Feed signature:
  `K6e5RX24GX2Zdd246nWIhuX/RlBrUXgyOQ06+bXrYMhEixSfrdhoy5yd5yGYA8jgleL96BKCiS7UMD3WeedsDQ==`.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.15-23-f7b51bc.dmg`: PASS.
- DMG enclosure signature:
  `SnkImN0R2yNKX5DI1He+aEv/I9PUNgwktev6tXDbNz8QxbS+f+XpeQkKxo47RL3h10qmVOtMbwGbx1xUitoZAg==`.
- Appcast enclosure length `9101039` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `92f6a0fd0f74b5fdae70b1cdb390e3846dd3020555ebe01a312ea459252b1593`.
- Raw `main` appcast fetched from GitHub matched the local `appcast.xml`: PASS.

## GitHub Release Readback

- Release URL: https://github.com/aaldere1/gridOS/releases/tag/v1.0.15
- Draft: false.
- Prerelease: false.
- Published at: 2026-06-19T19:00:39Z.
- DMG asset digest:
  `sha256:92f6a0fd0f74b5fdae70b1cdb390e3846dd3020555ebe01a312ea459252b1593`.
- ZIP asset digest:
  `sha256:395df75adbc9f8487cb59a6e24aba0ae1467ea5eb30d56817679e1c14fe4843b`.
- Appcast asset digest:
  `sha256:d989da7d411803bf8df5499d81b9b93d966063e54b5adc2a8e21544a4d83cbf9`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.14 to 1.0.15 remains useful
  validation when a separate clean Mac is available.
