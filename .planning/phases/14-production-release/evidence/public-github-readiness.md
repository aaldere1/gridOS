# gridOS public GitHub readiness

Date: 2026-06-19
Last validated: 2026-06-19
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PREPARED for final v1.0.14 GitHub publication.

The source-available proprietary repository posture is public and acceptable.
The 1.0.14 artifact is signed, notarized, stapled, Gatekeeper accepted, and
covered by a signed Sparkle appcast. GitHub release publication, asset digest
readback, and raw `main` appcast readback are pending the release commit/tag.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS after the 1.0.14 version bump.
- Pull request CI run `27840462691`: PASS for PR #7.
- GitHub Actions CI run `27840562158`: PASS on PR #7 merge commit `bcc78a2`.
- GitHub Actions CI run `27840599226`: PASS on version bump commit `c245751`.
- `git diff --check`: PASS after the 1.0.14 release-script/doc evidence edits.
- Current public docs identify 1.0.14 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256:
  `ff78c949c06bfaec170fd56b8d63c66d6a181622fb2c4966d6834ccad4e268f9`.
- ZIP SHA-256:
  `46be3c5c3ae9721ba59c195a16d94d8497e1857ec854599e7e7c6328aa8686ba`.
- DMG app tree SHA-256:
  `2b1ddc05c684ed91c3c7bbb7fe30e0182bab5cae1fe1bd498172741529b882f2`.
- ZIP extracted app tree SHA-256:
  `be125ab5ea19ade4d87fd601239bde50b4e0d364640e8e729e0f1d47b3793659`.
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
- TerminalCore tests cover source-pane Select All, source-pane copy priority,
  cross-pane copy/paste, selected inactive-pane fallback, active-pane paste
  routing, clicked-pane focus routing, Command-T pane creation, and layout
  publication.

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

- `appcast.xml`: generated for `gridOS 1.0.14` build `22`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- Feed signature:
  `qE/y79PQ/I3mPAVhmOHXa1aTD6oV6dBpgU2DNnMaArL4tp6Kdxceg6W4PTsnJlySfdhlGIlXmyQtLpNlaH4MDQ==`.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.14-22-c245751.dmg`: PASS.
- DMG enclosure signature:
  `yi6eiKNV7Cj2ZT8hLyfvsD+bLlt/xBsvk/45nG0ObBVGWWgyL00s/qTs83WShMMrVrJVM/bm4NqHYK2ICweaDA==`.
- Appcast enclosure length `9023820` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `ff78c949c06bfaec170fd56b8d63c66d6a181622fb2c4966d6834ccad4e268f9`.
- Raw `main` appcast fetched from GitHub matched the local `appcast.xml`:
  PENDING release commit push.

## GitHub Release Readback

- Release URL: https://github.com/aaldere1/gridOS/releases/tag/v1.0.14
- Draft: PENDING.
- Prerelease: PENDING.
- Published at: PENDING.
- DMG asset digest:
  `sha256:ff78c949c06bfaec170fd56b8d63c66d6a181622fb2c4966d6834ccad4e268f9`.
- ZIP asset digest:
  `sha256:46be3c5c3ae9721ba59c195a16d94d8497e1857ec854599e7e7c6328aa8686ba`.
- Appcast asset digest:
  `sha256:4a8a67967c71589028d56e7a25e113085139aa16ebf7bc15a4acab69f9842283`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.13 to 1.0.14 remains useful
  validation when a separate clean Mac is available.
