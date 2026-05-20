# Phase 6 Command Intelligence Evidence

This file records the final automated and interactive smoke evidence for Phase 6 Plan 06.

## Automated Verification

Status: Passed on 2026-05-20.

Commands:

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
! rg "apiKey.*AppStorage|UserDefaults.*api|anthropic.*AppStorage|import SwiftTerm|auto.*run|provider response.*execute" Sources/GridOSApp Sources/CommandIntelligence
```

## Debug Fixture Launch

The smoke fixture is selected only in Debug builds:

```sh
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-*/Build/Products/Debug/gridOS.app --args --command-intelligence-smoke-fixture
```

The fixture does not require a live Anthropic key and still routes through `CommandContextPreview`, `CommandIntelligenceService`, `CommandRiskClassifier`, and `CommandPaletteView`.

Additional noninteractive launch check passed:

```sh
open -n ~/Library/Developer/Xcode/DerivedData/gridOS-dssjhmncjnjrebctirhcurshdpbe/Build/Products/Debug/gridOS.app --args --cmd "printf 'PHASE6_FIXTURE_LAUNCH\n' > /tmp/gridos_phase6_fixture_launch.txt; exit" --command-intelligence-smoke-fixture
cat /tmp/gridos_phase6_fixture_launch.txt
```

Result:

```text
PHASE6_FIXTURE_LAUNCH
```

Additional orchestrator spot-check after plan execution:

```text
PHASE6_ORCHESTRATOR_FIXTURE
```

The orchestrator also launched the Debug app with `--command-intelligence-smoke-fixture`, activated gridOS, sent `Command-K` through System Events, and captured a local screenshot showing the `Command Intelligence` palette open with `Suggest Command`, `Explain Output`, `Fix Failed Command`, and `Open Command Intelligence Settings` visible. The screenshot was intentionally not committed because it captured unrelated desktop/private content outside gridOS.

## Smoke Checklist

| Check | Status | Evidence |
| --- | --- | --- |
| Command-K opens `Command Intelligence` and Escape/close restores the terminal | Auto-approved in GSD auto mode | Source verifies `CommandIntelligenceCommands` uses Command-K and `dismissCommandPalette()` calls `focusTerminal()`. Noninteractive fixture launch kept terminal startup usable. Human-visible `PHASE6_FOCUS` pass remains the documented manual smoke path. |
| No-key hosted-provider state is calm and terminal remains usable | Auto-approved in GSD auto mode | `testMissingKeyDoesNotInvokeProvider` proves missing Anthropic key returns `Provider not configured` before provider invocation; palette renders `Open Command Intelligence Settings`. |
| Settings action opens or focuses Command Intelligence Settings | Auto-approved in GSD auto mode | Source verifies `onOpenCommandIntelligenceSettings`, `openCommandIntelligenceSettingsFromPalette`, and `command-intelligence-settings` routing. |
| Deterministic fixture insert path does not run on insertion | Auto-approved in GSD auto mode | `testDebugFixtureDoesNotRequireProviderKey` and `testFixtureReturnsPhase6InsertCommand` prove `PHASE6_INSERT` fixture output without a live key; `CommandPaletteView` routes `Insert Command` to `insert` without newline. |
| Deterministic high-risk fixture is insert-only or exact-command confirmed | Auto-approved in GSD auto mode | `testFixtureReturnsHighRiskSmokeCommand` and `testGeneratedCommandsAreLocallyReclassified` prove `rm -rf ~/tmp/gridos-test` is classified locally as high risk with `insertOnly`; palette shows `Insert for Review` and only medium risk uses `Run exactly this command?`. |
| Explain Output selected-output fallback is clear | Auto-approved in GSD auto mode | Source verifies `Selection unavailable` copy and paste fallback; `testExplainOnlyResponsesHaveNoCommandsByDefault` proves read-only explain responses render without commands by default. |

## Results

Final automated gate passed:

```text
xcodegen generate --use-cache: passed
xcodebuild build test: passed
git diff --check: passed
Phase 6 source checks: passed
Forbidden source checks: passed
Debug fixture launch without live Anthropic key: passed
Human-verify checkpoint: auto-approved because workflow._auto_chain_active and workflow.auto_advance are true
```
