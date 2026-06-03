# Clean Mac Gatekeeper UAT

- Timestamp UTC: 2026-06-03T11:27:03Z
- Source commit: e1c7005
- Artifact basename: `gridOS-0.1.0-6-e1c7005.dmg`
- Artifact SHA-256: `fc4e353604f7b5195678fc86320633a4918955146db7429146133f8be495879d`
- Notarization: PASS
- Stapler command: xcrun stapler validate
- Stapler status: PASS
- Gatekeeper command: spctl --assess --type execute --verbose=4
- Local Gatekeeper status: PASS
- Finder launch: BLOCKED
- Update from Beta N to Beta N+1: BLOCKED
- Result: BLOCKED
- Blockers: BETA_CLEAN_MAC_BLOCKED clean_mac_finder_gatekeeper_uat, BETA_UPDATE_FLOW_BLOCKED update_flow_record_not_available_clean_mac

Local notarized artifact verification for build 6 passed in
`.planning/phases/12-beta/evidence/beta-artifact-verification.md`, and local
launch smoke passed in
`.planning/phases/12-beta/evidence/local-notarized-launch-smoke.md`. This file
remains blocked until the DMG is copied to a separate clean Mac, opened from
Finder with Gatekeeper enabled, launched, and recorded without committing raw
terminal transcripts, screenshots, private paths, or build artifacts.
