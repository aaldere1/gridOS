---
phase: 11
slug: alpha
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for Alpha planning and execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Xcode/XCTest plus shell gates |
| **Config file** | `project.yml` |
| **Quick run command** | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test` |
| **Full suite command** | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| **Estimated runtime** | ~10-30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-specific quick gate.
- **After every plan wave:** Run the full suite command or the closest signed-artifact gate for signing tasks.
- **Before `$gsd-verify-work`:** Full suite, signing/artifact verification, UAT evidence scan, and privacy scan must be green or have an explicit signing blocker.
- **Max feedback latency:** 30 seconds for normal XCTest/doc gates; signed archive gates may be longer.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | Signing preflight | shell/source | `scripts/alpha-signing-preflight.sh --dry-run && rg 'GRIDOS_DEVELOPMENT_TEAM|GRIDOS_SIGNING_IDENTITY|ENABLE_HARDENED_RUNTIME' scripts docs .planning/phases/11-alpha` | ✅ | ⬜ pending |
| 11-01-02 | 01 | 1 | Alpha evidence policy | docs/source | `rg 'Phase 11 alpha|Signing preflight|Blocker policy|No artifacts committed' .planning/phases/11-alpha/evidence/README.md docs/release.md` | ✅ | ⬜ pending |
| 11-02-01 | 02 | 2 | Alpha build script | shell/source | `bash -n scripts/build-alpha.sh && rg 'xcodebuild archive|GRIDOS_DEVELOPMENT_TEAM|GRIDOS_SIGNING_IDENTITY|ENABLE_HARDENED_RUNTIME' scripts/build-alpha.sh docs/release.md` | ✅ | ⬜ pending |
| 11-02-02 | 02 | 2 | Artifact verification | shell/source | `bash -n scripts/verify-alpha-artifact.sh && rg 'codesign --verify --deep --strict --verbose=2|shasum -a 256|Alpha artifact manifest' scripts docs .planning/phases/11-alpha` | ✅ | ⬜ pending |
| 11-03-01 | 03 | 2 | DEBUG alpha smoke | XCTest/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test && rg 'phase11-alpha-smoke|PHASE11_ALPHA_TERMINAL_READY|PHASE11_ALPHA_PRIVACY_READY' Sources Tests docs` | ✅ | ⬜ pending |
| 11-03-02 | 03 | 2 | Daily-driver UAT checklist | docs/shell | `rg 'vim|less|top|tmux|ssh -V|fast output|multi-pane|Command Intelligence|Terminal correctness' .planning/phases/11-alpha/ALPHA-UAT.md .planning/phases/11-alpha/run-alpha-uat.sh` | ✅ | ⬜ pending |
| 11-04-01 | 04 | 3 | Known issues and feedback | docs/source | `rg 'Severity|Alpha blocker|Beta blocker|Owner|Target phase|Known issues' .planning/phases/11-alpha/KNOWN-ISSUES.md docs/release.md` | ✅ | ⬜ pending |
| 11-04-02 | 04 | 3 | Sanitized diagnostics policy | docs/source | `rg 'Diagnostics|shell history|terminal transcript|environment variables|API keys|prompts|generated commands' docs .planning/phases/11-alpha` | ✅ | ⬜ pending |
| 11-05-01 | 05 | 4 | Alpha verification report | full gate | `rg 'Phase 11: Alpha Verification Report|Signed internal build|Terminal correctness|Known issues|Phase 12 - Beta' .planning/phases/11-alpha/11-VERIFICATION.md .planning/STATE.md` | ✅ | ⬜ pending |
| 11-05-02 | 05 | 4 | Final source/privacy gates | full gate | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Phase 11 may add shell scripts and DEBUG smoke code, but no new test framework is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Internal signed build used for real work | Alpha daily-driver validation | Requires local signing identity and human use of the app | Build signed alpha artifact, verify `codesign`, launch it from Finder, use it for at least one real command-line task, record pass/fail in `ALPHA-UAT.md`. |
| Terminal interactive tools | Terminal correctness | `vim`, `less`, `top`, and `tmux` require interactive confidence beyond unit tests | Run the checklist in `ALPHA-UAT.md`; high-severity input/render/process issues block signoff. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or manual evidence where unavoidable.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-21
