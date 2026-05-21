# gridOS release process

This document starts as a release checklist and should become the operational source of truth before alpha.

## Versioning

Initial version:

- Marketing version: `0.1.0`
- Build number: `1`

Before alpha, decide whether the version source of truth lives in `project.yml`, a generated config file, or CI.

## Local build

```sh
xcodegen generate
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' build
```

For unsigned CI builds:

```sh
xcodebuild -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build test
```

The project currently depends on SwiftTerm pinned through XcodeGen/SwiftPM. Regenerate the project after changing `project.yml` so package resolution stays in sync.

## Terminal smoke

Debug builds support a startup command for verification:

```sh
open -n path/to/gridOS.app --args --cmd 'echo ok; exit'
```

This is intended for local smoke tests of the shell bridge, not as a user-facing automation contract yet.

## Visual identity smoke

Phase 2 adds a Metal-backed background through `RenderCore.MetalBackgroundView`. The current smoke bar is:

- app launches without shader setup crashes
- startup command still reaches the shell
- shell child exits after command completion
- app quits cleanly
- app CPU returns to idle after the startup render burst

Recent local Phase 2 evidence:

```text
GRIDOS_PHASE2_SMOKE
APP_SAMPLE=0.0 106496 SN .../gridOS.app/Contents/MacOS/gridOS
```

This is not a substitute for Phase 9 performance hardening; it is only the Phase 2 guardrail that the first renderer does not obviously spin while idle.

## Phase 3 app-frame smoke

Phase 3 adds persisted app-frame settings, hidden-titlebar window autosave, reduced-motion-aware rendering, and accessibility coverage. The current local smoke bar is:

- app launches with the Debug binary and accepts `--cmd`
- startup command writes `GRIDOS_PHASE3_SMOKE` through the terminal path
- app quits cleanly after shell exit
- `SettingsView` persists shell path, font size, reduced motion, and visual intensity through shared keys
- `WindowFrameController` configures `setFrameAutosaveName("gridOS.main")`
- reduced motion suppresses Metal pulse magnitude through `VisualEffectConfiguration`

Smoke command:

```sh
rm -f /tmp/gridos-phase3-smoke.txt
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --cmd "printf 'GRIDOS_PHASE3_SMOKE\n' > /tmp/gridos-phase3-smoke.txt; exit"
cat /tmp/gridos-phase3-smoke.txt
```

## Phase 4 metrics smoke

Phase 4 adds truthful local metrics through `SystemMetrics` and wires them into the app frame. The current smoke bar is:

- app launches with the Debug binary and accepts `--cmd`
- startup command writes `GRIDOS_PHASE4_SMOKE` through the terminal path
- app quits cleanly after shell exit
- `SystemMetricsSnapshot`, `SystemMetricsSampler`, `SystemMetricsSamplingPolicy`, and `NativeSystemMetricsProvider` are present in source
- graceful copy strings are present for `Battery unavailable`, `Thermal unavailable`, `Network idle`, `No process data`, and `Stale`
- metrics sampling stays local-only and no-root; no telemetry, LLM handoff, persistent logs, or shell command provider is used for normal metrics
- idle CPU sampling after startup remains a Phase 9 hardening target, but Phase 4 verifies that startup smoke still completes with metrics integrated

Smoke command:

```sh
rm -f /tmp/gridos-phase4-smoke.txt
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --cmd "printf 'GRIDOS_PHASE4_SMOKE\n' > /tmp/gridos-phase4-smoke.txt; exit"
cat /tmp/gridos-phase4-smoke.txt
```

For automated local verification, quit the launched Debug app through LaunchServices after the smoke file appears and confirm no `gridOS` process remains.

Recent local Phase 4 evidence:

```text
GRIDOS_PHASE4_SMOKE
APP_QUIT=clean
```

## Phase 5 aesthetic mode evidence

Phase 5 adds local aesthetic modes for Tron, Severance, and Apple-native. The release evidence lane verifies the mode contract with automated checks, shared-seed screenshots, same-mode install-variation screenshots, and a human Command-Shift-M terminal-focus smoke.

Final automated commands:

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
rg "case tron|case severance|case appleNative|VisualTheme|VisualMotionProfile" Sources/RenderCore Tests/RenderCoreTests
rg "identity\\.seed\\.normalizedVector|uniforms.seed|testInstallDerivedSeedIsInstallSpecificWithinSameMode" Sources/RenderCore Tests/RenderCoreTests
rg "appearance.visualMode|appearance.installSeed|@AppStorage" Sources/GridOSApp Sources/GridOSKit Tests/GridOSKitTests
rg "keyboardShortcut\\(\"m\", modifiers: \\[\\.command, \\.shift\\]\\)|Cycle Visual Mode" Sources/GridOSApp
rg "accessibilityReduceMotion|reducedMotion|VisualEffectConfiguration" Sources/GridOSApp Sources/RenderCore
.planning/phases/05-aesthetic-modes/capture-mode-evidence.sh
sips -g pixelWidth -g pixelHeight .planning/phases/05-aesthetic-modes/evidence/*-screenshot
```

The mode-comparison screenshots must use the same install seed, `phase5-evidence-shared-seed`, for Tron, Severance, and Apple-native PNG evidence. The install-variation screenshots must use the same raw mode, `tron`, with three different seeds for the install A, install B, and install C PNG evidence files.

Command-Shift-M terminal-focus smoke:

1. Launch the built Debug app.
2. Click or focus the terminal.
3. Type `echo PHASE5_FOCUS_SMOKE`.
4. Press `Command-Shift-M` at least three times and verify the visual mode indicator cycles.
5. Type `echo PHASE5_FOCUS_AFTER` and confirm shell input still works.
6. Record pass/fail and any focus anomaly in `05-04-SUMMARY.md` or `.planning/phases/05-aesthetic-modes/evidence/README.md`.

Cyberpunk, Matrix, sound themes, plugin/user themes, full light mode, GPU terminal text rendering, marketplace/import themes, and eDEX theme compatibility remain deferred and out of scope for this release evidence lane.

## Phase 6 command intelligence smoke

Phase 6 adds the one-shot Command Intelligence palette, preview-approved provider requests, local risk policy, insert-first generated commands, and a deterministic Debug smoke fixture. The final smoke must not require a live Anthropic key.

Final automated commands:

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
rg "CommandIntelligenceFlow|suggestCommand|explainOutput|failedCommandHelp" Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg "SecretRedactor|RedactionFinding|privateKey|Bearer|Basic|credentialURL" Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg "CommandRiskClassifier|networkPipeToShell|sudo|rm -rf|git push|kubectl|docker|brew install|npm install|PHASE6_INSERT" Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg "DebugCommandIntelligenceFixtureProvider|debug-smoke-fixture|--command-intelligence-smoke-fixture|PHASE6_INSERT|rm -rf ~/tmp/gridos-test" Sources/CommandIntelligence Sources/GridOSApp Tests/CommandIntelligenceTests
rg "CommandCredentialStore|KeychainCommandCredentialStore|kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly" Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'keyboardShortcut\("k", modifiers: \[\.command\]\)|keyboardShortcut\("k", modifiers: \[\.command, \.option\]\)|CommandIntelligenceCommands|Clear' Sources/GridOSApp
rg "Open Command Intelligence Settings|openCommandIntelligenceSettings|command-intelligence-settings|onOpenCommandIntelligenceSettings" Sources/GridOSApp
rg "TerminalInteractionController|getSelection|sendText|focusTerminal" Sources/TerminalCore Sources/GridOSApp
FORBIDDEN="api""Key.*AppStorage|User""Defaults.*api|anthropic.*AppStorage|import SwiftTerm"
! rg "$FORBIDDEN" Sources/GridOSApp Sources/CommandIntelligence
```

Debug fixture launch:

```sh
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --command-intelligence-smoke-fixture
```

Manual smoke checklist:

1. Focus the terminal, press `Command-K`, confirm `Command Intelligence` opens with `Suggest Command`, `Explain Output`, and `Fix Failed Command`, then close it with Escape or the close control.
2. After dismissal, type `printf 'PHASE6_FOCUS\n' > /tmp/gridos_phase6_focus.txt` in the terminal and confirm `cat /tmp/gridos_phase6_focus.txt` prints `PHASE6_FOCUS`.
3. With no hosted provider key configured, trigger a normal Anthropic request and verify `Provider not configured` plus `Open Command Intelligence Settings`; click the action and verify Settings opens or focuses Command Intelligence.
4. Relaunch the Debug app with `--command-intelligence-smoke-fixture`; request the deterministic `PHASE6_INSERT` fixture, choose `Insert Command`, and verify `/tmp/gridos_phase6_insert.txt` is not created until Return or explicit `Run Command`.
5. Request the deterministic high-risk fixture `rm -rf ~/tmp/gridos-test` and verify `Insert for Review` or `Run exactly this command?` appears; no execution happens when the provider response appears.
6. Try `Explain Output` with selected output; if terminal selection is unavailable, verify `Selection unavailable` and the paste fallback.
7. Record pass/fail details in `.planning/phases/06-llm-command-palette/evidence/README.md`.

## Phase 7 multi-pane/session smoke

Phase 7 adds recursive split panes, active-pane command routing, local workspace persistence, and honest fresh-shell restore. The automated gate is:

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
rg 'TerminalWorkspaceView|TerminalPaneLayout|HSplitView|VSplitView|Active pane' Sources/GridOSApp
rg 'Split Right|Split Down|Duplicate Pane|Close Pane|Focus Next Pane|Focus Previous Pane|TerminalWorkspaceCommandsValue|@FocusedValue' Sources/GridOSApp
rg 'TerminalWorkspaceSnapshotStore|session-v1.json|recent-directories-v1.json|Application Support|loadSnapshot|saveSnapshot' Sources/TerminalCore Sources/GridOSApp Tests/TerminalCoreTests
rg 'Pane layout and directories are restored on relaunch.|Running shell processes are not restored after relaunch.|Directory unavailable. Starting in your default directory.' Sources
! rg 'TerminalCommandCenter\.copy|TerminalCommandCenter\.paste|TerminalCommandCenter\.clear|TerminalCommandCenter\.reset|import SwiftTerm' Sources/GridOSApp
```

Manual smoke checklist:

DEBUG launch helpers:

```sh
rm -f /tmp/gridos_phase7_pane_a.txt /tmp/gridos_phase7_pane_b.txt /tmp/gridos_phase7_close_cleanup.txt
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --phase7-multipane-smoke
cat /tmp/gridos_phase7_pane_a.txt /tmp/gridos_phase7_pane_b.txt /tmp/gridos_phase7_close_cleanup.txt

rm -f /tmp/gridos_phase7_restore.txt
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --phase7-session-restore-smoke
cat /tmp/gridos_phase7_restore.txt
```

1. Launch the Debug app and focus the terminal.
2. Use `Command-D` for `Split Right` and `Command-Shift-D` for `Split Down`; verify at least two panes are visible and readable.
3. Click or cycle pane focus with `Command-]` and `Command-[`; verify the active pane indicator changes and typed shell input goes to the intended pane.
4. Use Copy, Paste, Clear, Reset, and Command Intelligence from the Terminal menu/palette; verify each targets only the active pane.
5. Use `Command-W` to close one pane; verify only that pane's shell terminates and the remaining pane stays usable.
6. Quit and relaunch; verify pane layout and directories restore with fresh shell processes.
7. Confirm no orphan shell processes remain after pane close and app quit.

Manual fallback if UI automation is unavailable: create two panes with the shortcuts above, run `printf 'PHASE7_PANE_A\n' > /tmp/gridos_phase7_pane_a.txt` in the first pane, run `printf 'PHASE7_PANE_B\n' > /tmp/gridos_phase7_pane_b.txt` in the second pane, close the second pane, quit and relaunch with `--phase7-session-restore-smoke`, then verify the marker files exist and no orphan shell processes remain.

## Phase 8 macOS integrations smoke

Phase 8 adds a native menu bar companion, explicit local notification permission flow, shared Keychain primitives, and metadata-only indexing foundations.

Automated gate:

```sh
xcodegen generate --use-cache
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test
git diff --check
rg 'MenuBarExtra|showMenuBarExtra|Open gridOS|Host Status|Recent Directories' Sources Tests docs .planning
rg 'UNUserNotificationCenter|UNNotificationRequest|NotificationAuthorizationState|Enable Notifications|gridOS work finished' Sources Tests docs .planning
rg 'Keychain|kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly|Manage Stored Secrets' Sources Tests docs .planning
rg 'CSSearchableItem|WorkspaceSearchMetadata|Index saved workspace metadata|Terminal output and command history are never indexed' Sources Tests docs .planning
FORBIDDEN="shell""History|command""Output|terminal""Transcript|environment""Variables|api""Key.*AppStorage|User""Defaults.*api|import SwiftTerm"
! rg "$FORBIDDEN" Sources/GridOSApp Sources/GridOSKit Sources/CommandIntelligence Sources/TerminalCore Sources/SystemMetrics Sources/Integrations
```

Notification smoke:

```sh
rm -f /tmp/gridos_phase8_notification_smoke.txt
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --phase8-notification-smoke
cat /tmp/gridos_phase8_notification_smoke.txt
```

Command-line fallback if LaunchServices does not produce the marker:

```sh
rm -f /tmp/gridos_phase8_notification_smoke.txt
APP_BIN=$(ls -dt ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app/Contents/MacOS/gridOS 2>/dev/null | head -1)
"$APP_BIN" --phase8-notification-smoke
cat /tmp/gridos_phase8_notification_smoke.txt
```

Expected marker content includes:

```text
PHASE8_NOTIFICATION_SMOKE
gridOS work finished
A long-running task completed in your workspace.
```

Manual smoke checklist:

1. Launch the Debug app and confirm the `gridOS` menu bar extra is present when `Show Menu Bar Extra` is on.
2. Open the menu and verify `Open gridOS`, `Active workspace`, `Host Status`, `Recent Directories`, `Settings`, and `Quit gridOS`.
3. Choose `Open gridOS` and verify the main window activates without typing or running anything in the active pane.
4. Open Settings, use `Enable Notifications`, and verify the macOS permission prompt appears only after this explicit action.
5. Verify default notification content uses `gridOS work finished` and `A long-running task completed in your workspace.`
6. Verify `Manage Stored Secrets` scrolls/focuses the existing Command Intelligence credential section without revealing stored values.
7. Confirm `Index saved workspace metadata` is off by default, enable it only by explicit user action, and verify Spotlight indexing code references `WorkspaceSearchMetadata` rather than full paths or terminal content.

## Phase 9 performance hardening

Phase 9 adds a repeatable benchmark evidence lane for cold start, resident memory, idle CPU, input latency, heavy output, and frame pacing.

Quick benchmark smoke:

```sh
.planning/phases/09-performance-hardening/run-performance-benchmarks.sh --quick
```

Outputs:

- `.planning/phases/09-performance-hardening/evidence/phase9-results.json`
- `.planning/phases/09-performance-hardening/evidence/README.md`

Final Phase 9 evidence lives in `.planning/phases/09-performance-hardening/evidence/README.md` with the machine-readable report in `.planning/phases/09-performance-hardening/evidence/phase9-results.json`.

Full benchmark mode may attempt `xcrun xctrace` for Instruments/profile summaries after deterministic Phase 9 app fixtures exist. The `--quick` path keeps local smoke lightweight and writes measured quick evidence without long stress runs or profile capture.

Phase 9 benchmark evidence uses synthetic terminal markers and must not commit private shell history, terminal transcripts, environment variables, API keys, or screenshots containing user content.

## Phase 10 security and privacy hardening

Phase 10 release-readiness evidence is anchored by:

- `docs/security-threat-model.md`
- `docs/privacy-data-inventory.md`
- `docs/dependency-security-review.md`
- `.planning/phases/10-security-and-privacy-hardening/evidence/README.md`

The final Phase 10 gate must cover the threat model, privacy inventory, redaction tests, provider-boundary tests, command-risk tests, Keychain tests, persistence/indexing/notification privacy tests, dependency review, hardened runtime check, and privacy gates.

The dependency and hardened-runtime posture lives in `docs/dependency-security-review.md`, including the `SwiftTerm` dependency, proprietary private-alpha license posture, eDEX-UI inspiration boundary, and `ENABLE_HARDENED_RUNTIME: YES` compatibility note.

Representative privacy gates:

```sh
rg 'gridOS Threat Model|gridOS Privacy Data Inventory|gridOS Dependency and License Review|Phase 10 security and privacy hardening' docs .planning/phases/10-security-and-privacy-hardening
FORBIDDEN="api""Key.*AppStorage|User""Defaults.*api|shell""History|terminal""Transcript|environment""Variables|command""Output|selected""Output.*write|pro""mpt.*write|\\.""png|\\.""trace"
! rg "$FORBIDDEN" Sources docs .planning/phases/10-security-and-privacy-hardening/evidence
```

## Phase 11 alpha

Phase 11 alpha is the internal daily-driver lane. It starts with signing preflight evidence, then moves through internal build artifact creation, artifact verification, daily-driver UAT, known-issues triage, and final Alpha signoff.

Primary references:

- `.planning/phases/11-alpha/evidence/README.md` defines the Phase 11 alpha evidence policy, privacy boundaries, and blocker policy.
- `scripts/alpha-signing-preflight.sh` checks Xcode tooling, hardened-runtime settings, signing identity presence, and required signing environment variables without printing private values.
- `scripts/build-alpha.sh` is the internal artifact build entrypoint.
- `scripts/verify-alpha-artifact.sh` is the signed artifact verification entrypoint.
- `.planning/phases/11-alpha/ALPHA-UAT.md` is the daily-driver UAT checklist and signoff log.
- `.planning/phases/11-alpha/run-alpha-uat.sh` writes sanitized command-availability and fast output evidence to `.planning/phases/11-alpha/evidence/alpha-uat-summary.md`.
- `.planning/phases/11-alpha/KNOWN-ISSUES.md` is the future Alpha known-issues workflow.
- `.planning/phases/11-alpha/DIAGNOSTICS.md` is the Phase 11 Alpha Diagnostics Policy.
- `.planning/phases/11-alpha/11-VERIFICATION.md` is the final Alpha verification report and Phase 12 handoff gate.

Signing absence is recorded as `SIGNING_BLOCKED` with missing input names only. Current Phase 11 evidence has signing unblocked, artifact verification passing for `build/alpha/gridOS-0.1.0-1-69e8518.zip`, and signed daily-driver UAT passing in `.planning/phases/11-alpha/evidence/signed-artifact-uat.md`. Alpha cannot be marked complete with a high-severity terminal correctness blocker.

Final Alpha signoff must use `.planning/phases/11-alpha/11-VERIFICATION.md` as the source of truth. If the report is `BLOCKED`, do not mark Phase 11 complete or move the active target to Phase 12.

Signed internal alpha build:

```sh
GRIDOS_DEVELOPMENT_TEAM=team-id \
GRIDOS_SIGNING_IDENTITY='Developer ID Application: Example' \
scripts/build-alpha.sh
```

The build script runs `scripts/alpha-signing-preflight.sh`, regenerates the project with `xcodegen generate --use-cache`, then performs an `xcodebuild archive` with manual signing. If signing variables or local signing identities are missing, it stops before archiving and preserves the preflight blocker evidence.

`GRIDOS_ALPHA_OUTPUT_DIR` may point to another local output directory, but artifact paths must remain local-output paths only. Do not place `.app`, `.xcarchive`, `.dmg`, `.zip`, `.pkg`, traces, screenshots, or private logs under `.planning`.

Successful builds write `.planning/phases/11-alpha/evidence/alpha-artifact-manifest.md` with source commit, version/build, artifact basename, checksum, signing presence, hardened-runtime status, and the verification command to run next.

Alpha artifact verification:

```sh
scripts/verify-alpha-artifact.sh build/alpha/gridOS-version-build-commit.zip
```

The verifier accepts a generated ZIP or an extracted `gridOS.app`, rejects artifacts under `.planning`, computes `shasum -a 256` checksums, runs `codesign --verify --deep --strict --verbose=2`, records sanitized `codesign -dv` metadata, and writes `.planning/phases/11-alpha/evidence/alpha-artifact-verification.md`.

The verification report includes `Alpha artifact manifest`, bundle ID, version, build, checksum, pass/fail status, and `Notarization: deferred to Phase 12`.

DEBUG alpha daily-driver smoke:

```sh
rm -f /tmp/gridos_phase11_alpha_terminal_ready.txt /tmp/gridos_phase11_alpha_workspace_ready.txt /tmp/gridos_phase11_alpha_privacy_ready.txt
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --phase11-alpha-smoke
cat /tmp/gridos_phase11_alpha_terminal_ready.txt /tmp/gridos_phase11_alpha_workspace_ready.txt /tmp/gridos_phase11_alpha_privacy_ready.txt
```

Expected marker content:

```text
PHASE11_ALPHA_TERMINAL_READY
PHASE11_ALPHA_WORKSPACE_READY
PHASE11_ALPHA_PRIVACY_READY
```

The smoke uses deterministic local marker commands through the app workspace controller when a terminal view is attached. If a headless/debug launch cannot attach the terminal view, the app writes the same marker files with `source=app-launch-fallback` or `source=app-smoke-fallback` metadata so the smoke reports that the app, workspace model, and privacy-safe marker path ran without pretending to be full terminal UAT. It does not use live provider credentials, screenshots, terminal transcripts, selected output, prompts, generated commands, environment variables, or shell history.

Daily-driver Alpha UAT:

```sh
.planning/phases/11-alpha/run-alpha-uat.sh
```

Then complete the manual checklist in `.planning/phases/11-alpha/ALPHA-UAT.md` against the signed internal Alpha build. The helper records only command names, PASS/FAIL status, timestamps, and source commit; it does not capture terminal transcripts, shell history, raw command output, environment variables, API keys, prompts, generated commands, provider responses, screenshots, traces, or private file paths.

Alpha issue triage uses `.planning/phases/11-alpha/ALPHA-FEEDBACK.md` for intake and `.planning/phases/11-alpha/KNOWN-ISSUES.md` for confirmed issues with severity, Alpha/Beta/Production blocker status, owner, target phase, status, and sanitized evidence. The release rule is: critical/high terminal correctness issues block Alpha signoff.

The Phase 11 Alpha Diagnostics Policy keeps diagnostics local and sanitized. Phase 11 does not add telemetry, crash reporting, automatic diagnostics upload, or support portal functionality.

No artifacts committed: .app, .xcarchive, .dmg, .zip, .pkg, .trace, and screenshots stay out of source control.

## Phase 12 beta

Phase 12 beta is the external installability and feedback lane. It starts with
notarization preflight evidence, then moves through signed Beta artifact
creation, notarization, stapling or ticket validation, clean-Mac Gatekeeper UAT,
manual update-flow proof, first-run privacy, feedback triage, and final Beta
signoff.

Primary references:

- `.planning/phases/12-beta/evidence/README.md` defines the Phase 12 beta evidence policy, privacy boundaries, and blocker policy.
- `docs/beta-distribution.md` defines the manual Beta install, update, rollback, feedback, and privacy flow.
- `scripts/beta-notarization-preflight.sh` checks Xcode tooling, Developer ID signing input presence, hardened-runtime settings, notary tool presence, stapler presence, and notary credential mode presence without printing private values.
- `scripts/build-beta.sh` is the Beta artifact build entrypoint.
- `scripts/notarize-beta-artifact.sh` is the notary submission and stapling entrypoint.
- `scripts/verify-beta-artifact.sh` is the Beta artifact verification entrypoint.
- `.planning/phases/12-beta/BETA-UAT.md` is the clean-Mac Gatekeeper UAT checklist.
- `.planning/phases/12-beta/beta-release-manifest.json` is the manual Beta update manifest.
- `.planning/phases/12-beta/BETA-FEEDBACK.md` is the sanitized Beta feedback template.
- `.planning/phases/12-beta/KNOWN-ISSUES.md` is the Beta known-issues workflow.

Signing or notary absence is recorded as `BETA_NOTARIZATION_BLOCKED` with
missing input names only. Clean-Mac access absence is recorded as
`BETA_CLEAN_MAC_BLOCKED` with missing prerequisite names only. Beta cannot be
marked complete without notarized artifact evidence, Gatekeeper UAT evidence,
manual update-flow evidence, and a known-issues check showing no current
critical or high-severity Beta blocker.

Beta notarization preflight:

```sh
GRIDOS_DEVELOPMENT_TEAM=team-id \
GRIDOS_SIGNING_IDENTITY='Developer ID Application: Example' \
GRIDOS_NOTARY_PROFILE=notarytool-profile \
scripts/beta-notarization-preflight.sh
```

`GRIDOS_NOTARY_PROFILE` is the preferred credential mode and should name a
notarytool Keychain profile created outside this repo. Apple ID/app-specific
password/team and App Store Connect API key modes may be supported by later
scripts, but private values must never be committed or printed.

Signed and packaged Beta build:

```sh
GRIDOS_DEVELOPMENT_TEAM=team-id \
GRIDOS_SIGNING_IDENTITY='Developer ID Application: Example' \
GRIDOS_NOTARY_PROFILE=notarytool-profile \
scripts/build-beta.sh
```

The build script writes ZIP and DMG artifacts under `build/beta` by default and
writes `.planning/phases/12-beta/evidence/beta-artifact-manifest.md` with
artifact basenames, checksums, version/build, source commit, signing presence,
hardened-runtime status, and next commands.

Beta notarization:

```sh
GRIDOS_NOTARY_PROFILE=notarytool-profile \
scripts/notarize-beta-artifact.sh build/beta/gridOS-version-build-commit.dmg
```

The notarization script uses `xcrun notarytool submit --wait`, staples supported
artifact types with `xcrun stapler staple`, validates with
`xcrun stapler validate`, and records sanitized evidence in
`.planning/phases/12-beta/evidence/beta-notarization.md`.

Beta artifact verification:

```sh
scripts/verify-beta-artifact.sh build/beta/gridOS-version-build-commit.dmg
```

The verifier checks `codesign --verify --deep --strict --verbose=2`,
`xcrun stapler validate`, `spctl --assess --type execute --verbose=4`, bundle
metadata, and SHA-256 checksums, then writes
`.planning/phases/12-beta/evidence/beta-artifact-verification.md`.

No artifacts committed: .app, .xcarchive, .dmg, .zip, .pkg, .trace, and screenshots stay out of source control.

## Production distribution target

The likely 1.0 path is direct Mac distribution:

- archive from clean checkout
- sign with Developer ID Application certificate
- enable hardened runtime
- notarize with Apple
- staple the notarization ticket where applicable
- package as DMG or ZIP
- publish checksum
- verify launch on a clean Gatekeeper-enabled Mac

## Release candidate checklist

- Clean working tree.
- Version and build number incremented.
- Tests passing.
- Performance report captured.
- Dependency licenses reviewed.
- Privacy/security checklist reviewed.
- App archived from clean checkout.
- Code signature verified.
- Notarization accepted.
- Gatekeeper launch tested from downloaded artifact.
- Update flow tested, if updater has shipped.
- Release notes written.
- Rollback/hotfix path documented.

## CI responsibilities

The initial CI skeleton should:

- install XcodeGen
- generate the Xcode project
- build the app with signing disabled
- run unit tests

Release signing and notarization should remain manual or protected until credentials and branch protections are ready.
