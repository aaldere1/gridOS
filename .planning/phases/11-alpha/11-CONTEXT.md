# Phase 11: Alpha - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Source:** Auto-context from roadmap, Phase 10 verification, and current repo state

<domain>
## Phase Boundary

Phase 11 turns the current verified app into an internal alpha that can be used for daily command-line work. The phase is complete only when an internal build path, signing preflight, artifact verification, daily-driver UAT checklist, evidence log, and known-issues workflow agree that the app can be dogfooded without terminal correctness blockers.

This phase is not public beta. It does not need a public update feed, Sparkle, notarized public DMG, website/download page, support portal, or App Store path. Those belong to Phase 12+ unless a Phase 11 signing issue exposes a blocker that must be solved earlier.
</domain>

<decisions>
## Implementation Decisions

### Alpha Scope
- Phase 11 is internal daily-driver validation, not public distribution.
- The alpha build must preserve Phase 1-10 guarantees: terminal correctness, multi-pane/session behavior, performance evidence honesty, Command Intelligence privacy gates, local run policy, Keychain-only secrets, metadata-only indexing, sanitized notifications, and hardened-runtime compatibility.
- Alpha evidence must be text-first and privacy-safe. Do not commit screenshots, traces, shell history, terminal transcripts, raw command output, environment variables, API keys, or real user paths beyond sanitized examples.

### Signing And Build Policy
- A signed internal build is the target. If no signing identity/team is available locally, the phase must record a blocker with presence-only evidence rather than pretending the build is signed.
- Keep `project.yml` authoritative. Do not hand-edit generated Xcode project settings except through XcodeGen output.
- Preserve `ENABLE_HARDENED_RUNTIME: YES`.
- Developer ID notarization is not required for Phase 11 signoff, but the plan must avoid choices that would make Phase 12 notarization harder.
- Build artifacts should be created outside source-controlled paths or under ignored build directories. Commit manifests, checksums, and logs only after sanitization.

### Daily-Driver Validation
- Alpha UAT must cover real terminal use: shell startup, keyboard input, paste, fast output, `vim`, `less`, `top`, `tmux`, `ssh -V`, multi-pane split/close/restore, Command Intelligence no-key behavior, insert-only risky command handling, menu bar presence, notification opt-in behavior, and Spotlight/indexing privacy defaults.
- Any high-severity terminal correctness issue blocks Phase 11 signoff.
- Known issues must classify severity and state whether they block alpha, beta, or production.

### Feedback And Diagnostics
- The alpha loop needs a durable known-issues and feedback document in the repo.
- Diagnostics must be local and sanitized. If diagnostics export is added, it must exclude shell history, transcripts, environment variables, API keys, prompts, generated commands, and raw terminal output.

### Official Apple Distribution Context
- Apple currently documents Developer ID as the path for software distributed outside the Mac App Store, with notarization and hardened runtime expected for broader direct distribution.
- Apple documentation says notarization requires hardened runtime for macOS apps distributed outside the App Store. Phase 11 should keep this compatibility intact but defer public notarized distribution to Phase 12.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning State
- `.planning/ROADMAP.md` — Defines Phase 11 Alpha goal and exit criteria.
- `.planning/STATE.md` — Records Phase 10 verification handoff and current project decisions.
- `.planning/phases/10-security-and-privacy-hardening/10-VERIFICATION.md` — Security/privacy baseline that Alpha must preserve.

### Release And Security
- `docs/release.md` — Existing release gates, smoke procedures, and distribution direction.
- `docs/dependency-security-review.md` — Current dependency/license/hardened-runtime posture.
- `docs/security-threat-model.md` — Abuse cases and verification gates to preserve.
- `docs/privacy-data-inventory.md` — Data boundaries for evidence, diagnostics, Spotlight, notifications, and preferences.

### Build Source Of Truth
- `project.yml` — XcodeGen source of truth, signing placeholders, bundle ID, hardened runtime setting, and target list.
- `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` — Generated scheme used by build/test gates.
- `LICENSE` — Current proprietary private-alpha posture.

### Apple References
- Apple Developer ID support: `https://developer.apple.com/support/developer-id/`
- Apple notarization documentation: `https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution`
- Apple hardened runtime documentation: `https://developer.apple.com/documentation/xcode/configuring-the-hardened-runtime`
</canonical_refs>

<specifics>
## Specific Ideas

- Create `scripts/alpha-signing-preflight.sh` to capture presence-only signing and build-setting evidence.
- Create `scripts/build-alpha.sh` to archive/package an internal alpha build with clear environment-variable prerequisites.
- Create `scripts/verify-alpha-artifact.sh` to run `codesign --verify --deep --strict --verbose=2`, collect `codesign -dv` metadata, and write a checksum manifest.
- Add a DEBUG-only `--phase11-alpha-smoke` path to create deterministic terminal/app integration markers without live credentials or private data.
- Create `.planning/phases/11-alpha/evidence/README.md`, `ALPHA-UAT.md`, and `KNOWN-ISSUES.md`.
</specifics>

<deferred>
## Deferred Ideas

- Public notarized DMG/ZIP distribution.
- Sparkle or any update feed.
- Public download page, support portal, crash reporting service, telemetry, or public privacy policy site.
- App Store sandbox migration.
- Intel support decision.
- Public plugin architecture or signed plugin packages.
</deferred>

---

*Phase: 11-alpha*
*Context gathered: 2026-05-21 via auto-context*
