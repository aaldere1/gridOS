---
phase: 07
slug: multi-pane-session-management
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-20
---

# Phase 07 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest via Xcode scheme |
| **Config file** | `project.yml` and `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` |
| **Quick run command** | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| **Full suite command** | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` |
| **Estimated runtime** | ~90-210 seconds |

## Sampling Rate

- **After every task commit:** Run `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`.
- **After every plan wave:** Run `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check`.
- **Before `$gsd-verify-work`:** Full suite, Phase 7 source gates, process cleanup smoke, and active-pane UI smoke must be green.
- **Max feedback latency:** 210 seconds for automated build/test feedback.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-W0-01 | 01 | 0 | TerminalCore exposes pane ID, split axis, layout tree, pane descriptor, workspace snapshot, and workspace state models | unit/source | `rg 'TerminalPaneID|TerminalSplitAxis|TerminalPaneLayout|TerminalPaneDescriptor|TerminalWorkspaceSnapshot' Sources/TerminalCore Tests/TerminalCoreTests` plus quick run command | no, add source/tests | pending |
| 07-W0-02 | 01 | 0 | Layout operations split right/down, close, duplicate, focus next/previous, and clamp split fractions | unit | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:TerminalCoreTests/TerminalWorkspaceModelTests` | no, add test file | pending |
| 07-W0-03 | 01 | 0 | Workspace snapshot round-trips through Codable and never stores process IDs as restorable state | unit/source | `rg 'TerminalWorkspaceSnapshot|schemaVersion|Codable' Sources/TerminalCore Tests/TerminalCoreTests` and `! rg 'shellPid|processID|pid' Sources/TerminalCore/TerminalWorkspace*.swift` | no, add source/tests | pending |
| 07-ROUTE-01 | 02 | 1 | Active-pane selected text, insert, run, focus, copy, paste, clear, reset, and terminate route to exactly one pane | unit/source | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:TerminalCoreTests/TerminalWorkspaceControllerTests` | no, add test file | pending |
| 07-LIFE-01 | 02 | 1 | Pane close and app quit detach controllers and terminate each pane shell process | unit/source | `rg 'terminateActivePane|terminateAllPanes|processTerminated|isTerminated' Sources/TerminalCore Tests/TerminalCoreTests` plus quick run command | no, add source/tests | pending |
| 07-UI-01 | 03 | 2 | Workspace UI exposes split right/down, duplicate, close, focus next/previous, active pane indicator, and no SwiftTerm import in GridOSApp | source/build | `rg 'Split Right|Split Down|Duplicate Pane|Close Pane|Focus Next Pane|Focus Previous Pane|activePaneID' Sources/GridOSApp Sources/TerminalCore` and `! rg 'import SwiftTerm' Sources/GridOSApp` | no, add UI files | pending |
| 07-UI-02 | 03 | 2 | Existing Terminal commands and Command Intelligence closures target active pane only | source/unit | `rg 'selectedTextInActivePane|insertInActivePane|runInActivePane|focusActivePane|copyActivePaneSelection|clearActivePane' Sources/TerminalCore Sources/GridOSApp Tests` | no, add routing | pending |
| 07-PERSIST-01 | 04 | 3 | Session layout and recent directories persist locally without shell history/output/environment data | unit/source | `rg 'session-v1.json|recent-directories-v1.json|Application Support|TerminalWorkspaceSnapshotStore' Sources/TerminalCore Tests/TerminalCoreTests` and `! rg 'shell history|environment variables|command output|UserDefaults.*history|UserDefaults.*output' Sources` | no, add source/tests | pending |
| 07-RESTORE-01 | 04 | 3 | Relaunch restores layout/directories as fresh shells and falls back for missing directories | unit/source | `rg 'Directory unavailable. Starting in your default directory.|Running shell processes are not restored after relaunch.' Sources docs .planning` plus quick run command | no, add source/docs | pending |
| 07-SMOKE-01 | 05 | 4 | DEBUG smoke creates panes, targets active pane, closes pane, restores layout/directories, and proves no orphan shells | source/manual | `rg 'phase7-multipane-smoke|PHASE7_PANE_A|PHASE7_PANE_B|PHASE7_RESTORE|orphan' Sources docs .planning` plus manual smoke checklist | no, add fixture/docs | pending |

## Wave 0 Requirements

- [ ] `Sources/TerminalCore/TerminalWorkspaceModel.swift` or equivalent contains `TerminalPaneID`, `TerminalSplitAxis`, `TerminalPaneLayout`, `TerminalPaneDescriptor`, and `TerminalWorkspaceSnapshot`.
- [ ] `Tests/TerminalCoreTests/TerminalWorkspaceModelTests.swift` covers split, close, duplicate, focus order, clamp, snapshot round trip, and no process-ID persistence.
- [ ] `Tests/TerminalCoreTests/TerminalWorkspaceControllerTests.swift` covers active-pane routing with spies.
- [ ] Persistence tests use a temporary directory and do not touch real user app support.
- [ ] Source-check commands are copied into plan verification criteria so executor proof includes routing, privacy, process cleanup, and no-SwiftTerm-leak checks.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Multi-pane visual readability | Phase 7 layout readability | Requires observing real SwiftTerm panes under current visual themes | Launch Debug app, create at least two panes, verify both panes remain readable at laptop and external-display sizes, and record any crowding in Phase 7 evidence. |
| Active-pane focus smoke | Active-pane routing | First responder behavior crosses SwiftUI/AppKit/SwiftTerm | Create two panes, focus pane A, type a marker command, focus pane B, type a different marker command, return to pane A, verify command input goes only to focused pane. |
| Process cleanup smoke | No leaked shell processes | Requires observing real child processes after UI close/app quit | Create two panes, record shell PIDs if exposed by debug evidence, close one pane, verify its PID is gone, quit app, verify remaining gridOS child shells are gone. |
| Session restore smoke | Layout/directories restore, processes fresh | Requires relaunching app | Create two panes in different directories, quit, relaunch, verify layout and directories restore with fresh shell processes. |
| Command Intelligence active-pane smoke | Phase 6 integration preservation | Requires UI overlay and terminal insertion behavior | Open Command Intelligence from pane B, insert deterministic fixture text, close palette, verify insertion/focus returns to pane B only. |

## Recommended Source Checks

```bash
rg 'TerminalPaneLayout|TerminalPaneID|TerminalWorkspaceSnapshot|TerminalWorkspaceController' Sources/TerminalCore Tests/TerminalCoreTests
rg 'Split Right|Split Down|Duplicate Pane|Close Pane|Focus Next Pane|Focus Previous Pane' Sources/GridOSApp Sources/TerminalCore
rg 'activePaneID|selectedTextInActivePane|insertInActivePane|runInActivePane|focusActivePane' Sources/TerminalCore Sources/GridOSApp Tests
rg 'session-v1.json|recent-directories-v1.json|Application Support|Running shell processes are not restored after relaunch' Sources docs .planning
! rg 'import SwiftTerm' Sources/GridOSApp
! rg 'shell history|environment variables|UserDefaults.*output|UserDefaults.*history' Sources/GridOSApp Sources/TerminalCore Sources/GridOSKit
```

## Validation Sign-Off

- [x] All planned work has automated verification or explicit manual evidence.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers missing pane/session model, routing, persistence, and smoke coverage.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 210 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending Phase 7 execution evidence.
