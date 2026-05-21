# Clean Mac Gatekeeper UAT

- Timestamp UTC: 2026-05-21T21:58:22Z
- Source commit: 20b35f0
- Artifact basename: `gridOS-0.1.0-1-20b35f0.dmg`
- Artifact SHA-256: `253467b61b934d633a4d3f703532e7fdf1f59a4ff2636df5fc79289384b7967a`
- Notarization: PASS
- Stapler command: xcrun stapler validate
- Stapler status: PASS
- Gatekeeper command: spctl --assess --type execute --verbose=4
- Local Gatekeeper status: PASS
- Finder launch: BLOCKED
- Update from Beta N to Beta N+1: BLOCKED
- Result: BLOCKED
- Blockers: BETA_CLEAN_MAC_BLOCKED clean_mac_finder_gatekeeper_uat, BETA_UPDATE_FLOW_BLOCKED notarized_beta_n_plus_one_artifact

Local notarized artifact verification passed in
`.planning/phases/12-beta/evidence/beta-artifact-verification.md`, and local
launch smoke passed in
`.planning/phases/12-beta/evidence/local-notarized-launch-smoke.md`. This file
remains blocked until the DMG is copied to a separate clean Mac, opened from
Finder with Gatekeeper enabled, launched, and recorded without committing raw
terminal transcripts, screenshots, private paths, or build artifacts.
