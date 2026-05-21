# Clean Mac Gatekeeper UAT

- Timestamp UTC: 2026-05-21T21:16:00Z
- Source commit: 373110e
- Artifact basename: unavailable
- Notarization: BLOCKED
- Stapler command: xcrun stapler validate
- Stapler status: BLOCKED
- Gatekeeper command: spctl --assess --type execute --verbose=4
- Gatekeeper status: BLOCKED
- Finder launch: BLOCKED
- Update from Beta N to Beta N+1: BLOCKED
- Result: BLOCKED
- Blockers: BETA_NOTARIZATION_BLOCKED, BETA_CLEAN_MAC_BLOCKED notarized_beta_artifact

Clean-Mac Gatekeeper UAT cannot run until a notarized Beta artifact exists. The
current release lane has Developer ID signing inputs present, but no notary
credential mode is configured.
