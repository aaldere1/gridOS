# Beta artifact manifest

- Timestamp UTC: 2026-06-17T17:10:52Z
- Source commit: 2d2fe8d
- Bundle ID: com.aaldere1.gridos
- Version: 1.0.9
- Build: 17
- ZIP basename: gridOS-1.0.9-17-2d2fe8d.zip
- ZIP SHA-256 after app stapling/repack: f211ecef83d26f09b98258e1d40884c6dfb8382e928143464fe04e4d42e40f6e
- DMG basename: gridOS-1.0.9-17-2d2fe8d.dmg
- DMG SHA-256 after app stapling/repack and DMG notarization/stapling: e112a0d16c6e350579cee44c475bc9e0916ab2a4768f7c7b3fb48cc4a2048633
- DMG code signature: present
- Signing identity: present
- Development team: present
- Hardened runtime: YES
- Embedded Sparkle helpers: Developer ID signed with secure timestamps
- Artifact path policy: local output directory only; no artifacts are stored under .planning.
- Notarization command: scripts/notarize-beta-artifact.sh <local-output-dir>/gridOS-1.0.9-17-2d2fe8d.dmg
- Verification command: scripts/verify-beta-artifact.sh <local-output-dir>/gridOS-1.0.9-17-2d2fe8d.dmg
- Final distribution SHA-256 is recorded after stapling in .planning/phases/12-beta/beta-release-manifest.json and .planning/phases/12-beta/evidence/beta-artifact-verification.md.
- Repack note: the archived app was notarized through the ZIP path, stapled,
  the ZIP was rebuilt from the stapled app, and the DMG was repacked from the
  same stapled app before the final DMG notarization.
