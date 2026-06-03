# Beta artifact manifest

- Timestamp UTC: 2026-06-03T11:18:31Z
- Source commit: 403d2d2
- Bundle ID: com.aaldere1.gridos
- Version: 0.1.0
- Build: 5
- ZIP basename: gridOS-0.1.0-5-403d2d2.zip
- ZIP SHA-256: bbc360017e0756cfc44109220b2c52a251ecc7a8faa3d5fa433364d08e2b269a
- DMG basename: gridOS-0.1.0-5-403d2d2.dmg
- DMG SHA-256 before notarization/stapling: 5405d3c583950ce83c9bc327f7a33470e36cfcbb18809fc57caeffcab9ef8dd6
- Signing identity: present
- Development team: present
- Hardened runtime: YES
- Artifact path policy: local output directory only; no artifacts are stored under .planning.
- Notarization command: scripts/notarize-beta-artifact.sh <local-output-dir>/gridOS-0.1.0-5-403d2d2.dmg
- Verification command: scripts/verify-beta-artifact.sh <local-output-dir>/gridOS-0.1.0-5-403d2d2.dmg
- Final distribution SHA-256 is recorded after stapling in `.planning/phases/12-beta/beta-release-manifest.json` and `.planning/phases/12-beta/evidence/beta-artifact-verification.md`.
