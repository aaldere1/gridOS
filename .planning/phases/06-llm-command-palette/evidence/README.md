# Phase 6 Command Intelligence Evidence

This file records the final automated and interactive smoke evidence for Phase 6 Plan 06.

## Automated Verification

Status: Pending final gate.

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

## Smoke Checklist

| Check | Status | Evidence |
| --- | --- | --- |
| Command-K opens `Command Intelligence` and Escape/close restores the terminal | Pending final smoke | Use `PHASE6_FOCUS` after dismissal: `printf 'PHASE6_FOCUS\n' > /tmp/gridos_phase6_focus.txt` |
| No-key hosted-provider state is calm and terminal remains usable | Pending final smoke | Expect `Provider not configured` and `Open Command Intelligence Settings` |
| Settings action opens or focuses Command Intelligence Settings | Pending final smoke | Trigger `Open Command Intelligence Settings` from the no-key state |
| Deterministic fixture insert path does not run on insertion | Pending final smoke | `PHASE6_INSERT`: `printf 'PHASE6_INSERT\n' > /tmp/gridos_phase6_insert.txt` must not create the file until Return or explicit `Run Command` |
| Deterministic high-risk fixture is insert-only or exact-command confirmed | Pending final smoke | `rm -rf ~/tmp/gridos-test` must show `Insert for Review` or `Run exactly this command?` and must not run on provider response receipt |
| Explain Output selected-output fallback is clear | Pending final smoke | If selection is unavailable, expect `Selection unavailable` and paste fallback copy |

## Results

Pending final gate.
