# Phase 12: Beta - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Source:** Auto-context from Phase 11 verification, release docs, roadmap, local Xcode tools, and official Apple distribution guidance

<domain>
## Phase Boundary

Phase 12 turns the signed internal Alpha into an externally installable Beta. The phase is complete only when a Developer ID signed, hardened, notarized, stapled or ticket-validated distribution artifact can be installed and launched on a clean Gatekeeper-enabled Mac, and when beta testers have a clear update, feedback, support, diagnostics, and privacy path.

This phase is still not the 1.0 release candidate. It should prove external trust and installability without freezing all features, opening a public plugin ecosystem, adding telemetry, or making App Store commitments.
</domain>

<decisions>
## Implementation Decisions

### Beta Distribution
- Direct Mac distribution remains the chosen path for Beta.
- Keep `project.yml` authoritative and preserve `ENABLE_HARDENED_RUNTIME: YES`.
- Use Developer ID signing for Beta artifacts. If signing or notary credentials are unavailable, record `BETA_NOTARIZATION_BLOCKED` with missing input names only.
- Beta artifacts must be produced under ignored local output directories such as `build/beta`. Never commit `.app`, `.xcarchive`, `.dmg`, `.zip`, `.pkg`, `.trace`, screenshots, raw logs, or private terminal data.
- Phase 12 should notarize the distributed artifact and staple when the artifact type supports stapling. For ZIP distribution, verify the extracted app ticket/Gatekeeper path explicitly because `stapler` supports app bundles, UDIF disk images, and signed flat installer packages.

### Update Flow
- The minimum Beta update mechanism is a versioned release manifest with artifact basename, SHA-256, version/build, source commit, notarization status, Gatekeeper UAT status, release notes path, and rollback instructions.
- If Sparkle is added later, the Beta manifest must not block that migration. For Phase 12, the update flow can be proven as a manual Beta N to Beta N+1 replacement flow using signed/notarized artifacts and checksum verification.
- Automatic in-app updates are a Phase 13/14 decision unless Phase 12 execution proves Sparkle credentials, appcast hosting, and update signing are ready without weakening the release lane.

### Clean Mac Gatekeeper Proof
- Clean-Mac proof requires a fresh macOS user or separate Mac with Gatekeeper enabled, a quarantined downloaded artifact, normal Finder launch, and `spctl --assess`/`stapler validate` evidence where applicable.
- Evidence must be sanitized text only. Record command names, statuses, version/build, artifact basename, checksum, and high-level outcomes. Do not record private paths, screenshots, raw terminal transcripts, shell history, environment dumps, or credentials.

### First Run, Privacy, Feedback, And Support
- Beta first-run UX must make privacy defaults understandable without docs: local terminal sessions, Keychain-only API keys, opt-in Command Intelligence, preview-before-send, insert-first risky commands, opt-in notifications, and metadata-only indexing.
- Beta users must have a support email/site placeholder and a feedback template that asks for sanitized diagnostics only.
- Diagnostics remain local and user-reviewed. Phase 12 does not add telemetry, crash-report uploads, or automatic diagnostics upload.

### Compatibility And Deferrals
- Apple Silicon remains the Beta CPU support target.
- macOS 14 remains the minimum OS.
- Intel support, final public license posture, App Store sandbox migration, hosted download infrastructure, and automatic update hosting remain open decisions for later phases unless they become Beta blockers.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning State
- `.planning/ROADMAP.md` - Defines Phase 12 Beta goal and exit criteria.
- `.planning/STATE.md` - Records Phase 11 signed-artifact handoff and active Beta target.
- `.planning/phases/11-alpha/11-VERIFICATION.md` - Source of truth for signed Alpha pass and Phase 12 handoff.
- `.planning/phases/11-alpha/ALPHA-UAT.md` - Alpha UAT coverage that Beta must preserve.
- `.planning/phases/11-alpha/KNOWN-ISSUES.md` - Known-issues tracker; all current Alpha blockers resolved.

### Release And Security
- `docs/release.md` - Existing alpha build/verify commands and production distribution target.
- `docs/production-roadmap.md` - Beta deliverables, release checklist, and risk register.
- `docs/security-privacy.md` - User-facing privacy posture.
- `docs/security-threat-model.md` - Security boundaries and out-of-scope items.
- `docs/privacy-data-inventory.md` - Data boundaries for diagnostics, preferences, indexing, notifications, and Command Intelligence.
- `docs/dependency-security-review.md` - Dependency/license posture before external Beta.

### Build Source Of Truth
- `project.yml` - XcodeGen source of truth for bundle IDs, signing placeholders, hardened runtime, version/build, and target graph.
- `scripts/build-alpha.sh` - Current signed archive/ZIP lane to evolve for Beta.
- `scripts/verify-alpha-artifact.sh` - Current codesign/checksum verification lane to evolve for Beta.
- `scripts/alpha-signing-preflight.sh` - Current signing preflight pattern for presence-only evidence.

### App Surfaces
- `Sources/GridOSApp/GridOSApp.swift` - App entry point and launch-argument smoke hooks.
- `Sources/GridOSApp/SettingsView.swift` - Existing settings shell.
- `Sources/GridOSApp/CommandIntelligenceSettingsView.swift` - Existing Command Intelligence privacy/setup copy.
- `Sources/GridOSApp/MacIntegrationsSettingsView.swift` - Existing notification/indexing controls.
- `Sources/GridOSKit/GridOSAppPreferences.swift` - Shared preference keys and default/reset behavior.

### Apple References
- Apple Developer ID overview: `https://developer.apple.com/developer-id/`
- Apple notarization documentation: `https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution`
- Apple custom notarization workflow: `https://developer.apple.com/documentation/security/customizing-the-notarization-workflow`
- Apple hardened runtime documentation: `https://developer.apple.com/documentation/xcode/configuring-the-hardened-runtime`
- Apple app distribution preparation: `https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution`
</canonical_refs>

<specifics>
## Specific Ideas

- Add `scripts/beta-notarization-preflight.sh` to check `xcrun notarytool`, `xcrun stapler`, `hdiutil`, `ditto`, `spctl`, signing identity presence, hardened runtime, and credential presence without exposing values.
- Add `scripts/build-beta.sh` to archive and package local Beta artifacts under `build/beta`, using the same signing variables as Alpha plus Beta-specific manifests.
- Add `scripts/notarize-beta-artifact.sh` to submit an app ZIP/DMG/PKG using `xcrun notarytool submit --wait`, fetch the log on failure, staple where supported, and write sanitized evidence.
- Add `scripts/verify-beta-artifact.sh` to verify codesign, notarization/stapling ticket state, Gatekeeper assessment, app metadata, and SHA-256.
- Add a Beta release manifest and distribution doc that can prove manual Beta N to Beta N+1 update flow.
- Add first-run privacy disclosure and a support/feedback command or settings section without adding telemetry or upload behavior.
- Add `.planning/phases/12-beta/BETA-UAT.md`, `BETA-FEEDBACK.md`, `KNOWN-ISSUES.md`, and `12-VERIFICATION.md`.
</specifics>

<deferred>
## Deferred Ideas

- Public launch landing page and hosted download infrastructure.
- Automatic Sparkle appcast hosting and in-app update UI, unless Phase 12 credentials/hosting are ready.
- Crash reporting service, telemetry, automatic diagnostic upload, or support portal backend.
- App Store sandbox migration.
- Intel support.
- Public license/source posture.
- Plugin signing or plugin marketplace.
</deferred>

---

*Phase: 12-beta*
*Context gathered: 2026-05-21 via auto-context*
