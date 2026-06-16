# Beta artifact manifest

- Timestamp UTC: 2026-06-16T22:21:48Z
- Source commit: c60fecb
- Bundle ID: com.aaldere1.gridos
- Version: 1.0.8
- Build: 16
- ZIP basename: gridOS-1.0.8-16-c60fecb.zip
- ZIP SHA-256 after app stapling: 34e02e501362e0fcd797987f85663b980827300238eb9801e05123e9f0d7c1e2
- DMG basename: gridOS-1.0.8-16-c60fecb.dmg
- DMG SHA-256 after final notarization/stapling: 6884374556bb43ed2895ab9ae2a0486309d52042e069deb28b9d49e88a08e346
- DMG code signature: present
- Signing identity: present
- Development team: present
- Hardened runtime: YES
- Embedded Sparkle helpers: Developer ID signed with secure timestamps
- Artifact path policy: local output directory only; no artifacts are stored under .planning.
- Notarization command: scripts/notarize-beta-artifact.sh <local-output-dir>/gridOS-1.0.8-16-c60fecb.dmg
- Verification command: scripts/verify-beta-artifact.sh <local-output-dir>/gridOS-1.0.8-16-c60fecb.dmg
- Final distribution SHA-256 is recorded after stapling in .planning/phases/12-beta/beta-release-manifest.json and .planning/phases/12-beta/evidence/beta-artifact-verification.md.
- Final ZIP and DMG were rebuilt after app-bundle stapling so both downloadable
  packages contain or wrap the stapled app.
