# gridOS public GitHub readiness

Date: 2026-06-17
Last validated: 2026-06-17
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for final v1.0.10 GitHub publication.

The source-available proprietary repository posture is already public and
acceptable. The 1.0.10 artifact is signed, notarized, stapled, Gatekeeper
accepted, mounted from the final DMG for artifact proof, and covered by a signed
Sparkle appcast.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS after the 1.0.10 source commit.
- GitHub Actions CI run `27722694434`: PASS on `4d58dd7`.
- `git diff --check`: PASS after the 1.0.10 release-script/doc evidence edits.
- Current public docs now identify 1.0.10 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256: `5fc389fa655ae9793503bd554615ee067443856a30fb64c5700e459ecb5b56c1`.
- ZIP SHA-256: `a5b6d670a7ab3949642a23c8c3305cb768dbbb916262f3557d271e04385e21c4`.
- Extracted app tree SHA-256: `0efb8b232885fff498c4bf6109cbea98aeeb6fc606a8278e8e323df13b80886c`.
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

- `appcast.xml`: generated for `gridOS 1.0.10` build `18`.
- `xmllint --noout appcast.xml`: PASS.
- Feed Ed25519 signature verification against
  `nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=`: PASS.
- Feed signature:
  `dYSMubq7UsMpw83TKkGS51Uo5amH8xN0BmOtW2QsESyxDNjbQuREQCvI0A6ilkhWVMn7dJsxKM15LmFN4LcVCw==`.
- DMG enclosure Ed25519 signature verification against
  `build/release/production/gridOS-1.0.10-18-26f01e7.dmg`: PASS.
- DMG enclosure signature:
  `SsYMVyBHd/SeFbiS8gVoer6skjwdoQaiSrkZ+JROadWEN6g5yKvNk1jN9DDqAAByhlr/JC+Cq+kqEYbZoTG9Bw==`.
- Appcast enclosure length `9086688` matches the local DMG.
- Appcast DMG SHA-256 verification matched
  `5fc389fa655ae9793503bd554615ee067443856a30fb64c5700e459ecb5b56c1`.
- Raw `main` appcast fetched from GitHub matched the local `appcast.xml`: PASS.

## GitHub Release Readback

- Release URL: https://github.com/aaldere1/gridOS/releases/tag/v1.0.10
- Draft: false.
- Prerelease: false.
- Published at: 2026-06-17T22:05:52Z.
- DMG asset digest:
  `sha256:5fc389fa655ae9793503bd554615ee067443856a30fb64c5700e459ecb5b56c1`.
- ZIP asset digest:
  `sha256:a5b6d670a7ab3949642a23c8c3305cb768dbbb916262f3557d271e04385e21c4`.
- Appcast asset digest:
  `sha256:4c38aae00dd762acb2076583253bd2a7775881c4bb8c8a4358f4dd89893780b8`.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac Sparkle update proof from 1.0.9 to 1.0.10 remains useful
  external validation when a separate clean Mac is available.
