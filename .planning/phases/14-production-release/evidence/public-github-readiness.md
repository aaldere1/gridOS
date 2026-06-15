# gridOS public GitHub readiness

Date: 2026-06-15
Scope: source-available public repository visibility for `aaldere1/gridOS`.

## Verdict

PASS for public GitHub visibility as source-available proprietary code.

This is not an open-source license change. `LICENSE` still grants no public
copying, modification, distribution, sublicensing, or use rights without written
permission from the copyright holder.

## Source and CI

- `scripts/ci-build-test.sh`: PASS on Xcode 26.5.
- `git diff --check`: PASS.
- Current public docs now identify 1.0.5 as the current release.
- Repository posture is documented as source-available proprietary, not open
  source.

## Artifact Checks

- DMG SHA-256: `b3f94f03ca5db2f1c3fa9fb1df0fa0cdcacd6998927a878fc6b312768e0c5a05`.
- ZIP SHA-256: `b34e83b27ea4f17d9e6076d46686bee7f6330f3eb5357459b5085b1f5ed3e54f`.
- `codesign --verify --deep --strict --verbose=2 build/release/production/gridOS-1.0.5-13-379289a.dmg`: PASS.
- `spctl -a -t open --context context:primary-signature -v build/release/production/gridOS-1.0.5-13-379289a.dmg`: PASS, accepted from Notarized Developer ID.

## Computer Use Proof

- Mounted `gridOS-1.0.5-13-379289a.dmg` read-only at `/Volumes/gridOS`.
- Finder showed the polished DMG window with `gridOS.app`, Applications
  shortcut, drag arrow, and `signed and notarized` footer.
- `/Applications/gridOS.app` reports version `1.0.5`, build `13`.
- `/Applications/gridOS.app` strict codesign: PASS.
- `/Applications/gridOS.app` Gatekeeper exec assessment: PASS, accepted from
  Notarized Developer ID.
- Computer Use inspected the running app from `/Applications/gridOS.app` and
  confirmed visible `v1.0.5`, terminal pane, pane controls, Open Folder, system
  pulse, and right-rail signal.
- Computer Use inspected Command-K and confirmed AI Command Helper mode
  guidance, no-key state, example actions, provider setup path, and previewed /
  insert-first policy copy.

## Remaining External Validation

- Separate clean-Mac Finder/Gatekeeper install proof remains useful external
  validation when a separate clean Mac is available.
- Separate clean-Mac 1.0.4 to 1.0.5 update proof remains useful external
  validation when a separate clean Mac is available.
- These are not blockers for public source-available GitHub visibility because
  the 1.0.5 direct-download release already has signed/notarized/Gatekeeper
  local proof and same-machine Computer Use inspection.
