# gridOS public GitHub readiness

Date: 2026-06-19
Last validated: 2026-06-19
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.13 GitHub publication.

The source-available proprietary repository posture is public and acceptable.
The 1.0.13 artifact is signed, notarized, stapled, Gatekeeper accepted, uploaded
to the public GitHub release, and covered by a signed Sparkle appcast that
matches raw `main`.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS after the 1.0.13 version bump.
- Pull request CI run `27839566314`: PASS for PR #6.
- GitHub Actions CI run `27839645362`: PASS on PR #6 merge commit `45670df`.
- GitHub Actions CI run `27839793210`: PASS on version bump commit `00e2893`.
- `git diff --check`: PASS after the 1.0.13 release-script/doc evidence edits.
- Current public docs identify 1.0.13 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256:
  `0c68b1115377dfd4675304ae022f5e40ebf090c237c2192dfd3eb79ada688041`.
- ZIP SHA-256:
  `ca58ce5da13f035934872c9c19880f185271f6fbd932c6a7a1bbaa1b4b926d7e`.
- DMG app tree SHA-256:
  `74d77fda1c2fc9989202e0c20624e97e1d4a996da28b717b1f597ea0e9c4ada7`.
- ZIP extracted app tree SHA-256:
  `0dfba7130c5eeaa87ae06caba26edec79f10c205002bbe59b16fcac02fad93f6`.
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
- TerminalCore tests cover source-pane copy priority, cross-pane copy/paste,
  selected inactive-pane fallback, active-pane paste routing, clicked-pane focus
  routing, Command-T pane creation, and layout publication.

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

- `appcast.xml`: generated for `gridOS 1.0.13` build `21`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- Feed signature:
  `PnK88HOyNWlROUL+PnDfo9d7tpmfHc7RWonTX4rn3q53PhQmEbJF1tHZcOc92DxL2tg8DXaoqKpmi3xCHV9zCg==`.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.13-21-00e2893.dmg`: PASS.
- DMG enclosure signature:
  `U9tR8Br66nufemK7r2faYEYd8B20r0yLKrbZQkPJ3P2FAqaA8DmGjZExc8ENv7u0IobPdUMf5BzRy0S19bi4Bg==`.
- Appcast enclosure length `9023660` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `0c68b1115377dfd4675304ae022f5e40ebf090c237c2192dfd3eb79ada688041`.
- Raw `main` appcast fetched from GitHub matched the local `appcast.xml`: PASS.

## GitHub Release Readback

- Release URL: https://github.com/aaldere1/gridOS/releases/tag/v1.0.13
- Draft: false.
- Prerelease: false.
- Published at: 2026-06-19T17:35:23Z.
- DMG asset digest:
  `sha256:0c68b1115377dfd4675304ae022f5e40ebf090c237c2192dfd3eb79ada688041`.
- ZIP asset digest:
  `sha256:ca58ce5da13f035934872c9c19880f185271f6fbd932c6a7a1bbaa1b4b926d7e`.
- Appcast asset digest:
  `sha256:a758184b6926365bdbec64e38bc2d00e00a2669d099e71a1faafb5496e4e26df`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.12 to 1.0.13 remains useful
  validation when a separate clean Mac is available.
