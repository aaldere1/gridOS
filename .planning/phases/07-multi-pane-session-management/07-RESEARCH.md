# Phase 07: multi-pane-session-management - Research

**Researched:** 2026-05-20
**Domain:** Native macOS multi-pane terminal workspace, SwiftTerm lifecycle routing, local session persistence, active-pane command targeting
**Confidence:** HIGH

<user_constraints>
## User Constraints from CONTEXT.md

### Locked Decisions
- Multi-pane support starts inside the existing primary gridOS window, not with a full tabs/windows overhaul.
- Horizontal and vertical splits are required; a simple tree/grid model is acceptable if it supports active pane identity and readable proportions.
- Every pane owns its own terminal session, SwiftTerm surface, PTY process, interaction controller, activity stream, working directory, and lifecycle state.
- Terminal menu actions and Command Intelligence target the active pane only.
- Session restoration restores layout, pane metadata, profile settings, last known directories, and active pane identity; it does not resurrect running processes.
- Recent directories are local-only app state. Do not persist shell history, command output, environment variables, hidden file scans, or secrets.
- Pane close and app quit must terminate child shell processes cleanly, with evidence proving no orphaned shell processes remain.
- `TerminalCore` owns pane/session/process abstractions. `GridOSApp` composes the workspace and must not import SwiftTerm.

### Deferred Ideas
- Full tabs/window management.
- Live process resurrection.
- Deep tmux-style session restore.
- Cross-device session sync.
- Remote SSH workspace management.
- Public workspace/plugin APIs.
- Process actions from the metrics/activity panel.
</user_constraints>

## Summary

Phase 7 should be planned as a TerminalCore-first session model plus a SwiftUI workspace composition. The implementation should not start by sprinkling pane arrays through `RootView`; it needs pure, testable pane layout and snapshot types first, then a routing layer that makes "active pane" deterministic for Terminal menu commands and Command Intelligence.

The current single-shell implementation already has the right primitives: `TerminalSessionConfiguration` carries shell, working directory, font, and startup command; `TerminalSurface` starts and terminates a SwiftTerm `LocalProcessTerminalView`; `TerminalInteractionController` exposes selected text, insert, run, and focus without SwiftTerm leakage. Phase 7 should keep those boundaries and scale them to multiple pane identities.

The highest-risk change is the existing global `NotificationCenter` command bridge. Today every `TerminalSurface.Coordinator` registers for copy/paste/clear/reset. With multiple panes, that can become broadcast behavior or last-attached-terminal behavior. The safer direction is to make command routing active-pane aware through a workspace controller and focused command handlers, while keeping SwiftTerm-specific operations inside each pane's `TerminalInteractionController`.

**Primary recommendation:** implement in five slices:

1. Pure TerminalCore pane/session models and persistence contracts.
2. Active-pane interaction routing plus per-pane process cleanup hooks.
3. SwiftUI multi-pane workspace and native pane command menus.
4. Local session restore, recent directories, Settings/Recovery copy, and release docs.
5. Deterministic DEBUG smoke fixture and final evidence.

## Current Implementation Facts

### Existing gridOS code

| Area | Current state | Phase 7 implication |
|------|---------------|---------------------|
| `TerminalSessionConfiguration` | Stores shell path, args, working directory, font, font size, startup command | Can seed each pane descriptor and restored fresh shell |
| `TerminalSurface` | Owns one SwiftTerm `LocalProcessTerminalView`, starts shell, records activity, terminates in `dismantleNSView`/`shutdown` | Must be instantiated once per pane and receive pane identity |
| `TerminalInteractionController` | Holds a weak current terminal and exposes `selectedText`, `insert`, `run`, `focusTerminal` | Needs per-pane instances plus active-pane router |
| `TerminalCommandCenter` | Static notification bridge for copy/paste/clear/reset | Must stop behaving like a global broadcast when multiple panes exist |
| `RootView` | Tracks one `currentWorkingDirectory`, one terminal controller, one `TerminalWorkspaceView` | Needs a workspace model with per-pane directories and active pane |
| `CommandPaletteView` | Uses closures from `RootView` for selected text, working directory, insert, run | Closures should point at active-pane router only |
| `SettingsView` | Says running shell processes are not restored after relaunch | Copy should evolve to mention pane layout/directories are restored, processes are not |

### SwiftTerm local source facts

The local SwiftPM checkout confirms:

- `LocalProcess` exposes `running`, `shellPid`, `childfd`, `send(data:)`, `startProcess(...)`, and `terminate()`.
- SwiftTerm comments state `terminate` sends `SIGTERM` to the child process and `shellPid` can be used with `kill`.
- `LocalProcessTerminalView` wraps `LocalProcess`, exposes `startProcess(...)`, `terminate()`, `processDelegate`, and forwards `processTerminated`, `sizeChanged`, and `hostCurrentDirectoryUpdate`.
- `LocalProcessTerminalView.sizeChanged(...)` calls `PseudoTerminalHelpers.setWinSize(...)` when the process is running, so split-pane resize should continue to propagate through normal view resizing.
- `hostCurrentDirectoryUpdate(source:directory:)` is the existing safe path for recent-directory updates; do not add shell hooks for this phase.

## Architecture Patterns

### Pattern 1: Pure Pane Layout Tree

Use a small Codable/Equatable layout model independent of SwiftUI and SwiftTerm:

```swift
public enum TerminalSplitAxis: String, Codable, Equatable, Sendable {
    case horizontal
    case vertical
}

public struct TerminalPaneID: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String
}

public indirect enum TerminalPaneLayout: Codable, Equatable, Sendable {
    case pane(TerminalPaneID)
    case split(axis: TerminalSplitAxis, fraction: Double, first: TerminalPaneLayout, second: TerminalPaneLayout)
}
```

Keep operations pure and heavily tested:

- split a pane right/down
- close a pane and promote sibling
- duplicate a pane descriptor
- focus next/previous in stable traversal order
- clamp split fractions, for example `0.20...0.80`
- find pane IDs in visual order

### Pattern 2: Pane Descriptor and Restorable Snapshot

Use a descriptor for data that can survive relaunch:

```swift
public struct TerminalPaneDescriptor: Codable, Equatable, Identifiable, Sendable {
    public var id: TerminalPaneID
    public var configuration: TerminalSessionConfiguration
    public var title: String?
    public var lastWorkingDirectory: String?
}

public struct TerminalWorkspaceSnapshot: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var layout: TerminalPaneLayout
    public var panes: [TerminalPaneDescriptor]
    public var activePaneID: TerminalPaneID
    public var recentDirectories: [String]
}
```

Do not persist process IDs as restorable truth. A previous PID can be written to debug evidence if needed, but not stored as session state.

### Pattern 3: Active-Pane Interaction Routing

Use one `TerminalInteractionController` per pane and a workspace controller/router that owns active pane identity. The router exposes app-facing actions:

```swift
@MainActor
public final class TerminalWorkspaceController: ObservableObject {
    @Published public private(set) var activePaneID: TerminalPaneID

    public func activatePane(_ paneID: TerminalPaneID)
    public func selectedTextInActivePane() -> String?
    public func insertInActivePane(_ text: String)
    public func runInActivePane(_ command: String)
    public func focusActivePane()
    public func copyActivePaneSelection()
    public func pasteIntoActivePane()
    public func clearActivePane()
    public func resetActivePane()
}
```

The underlying per-pane controller can own the SwiftTerm terminal weak reference. `GridOSApp` calls only this router or closures backed by it.

### Pattern 4: Focused Command Handlers for SwiftUI Menus

SwiftUI command menus should target the focused workspace rather than global static notifications. Use a focused value or focused object that maps menu actions to the active pane:

```swift
struct TerminalWorkspaceCommandsValue {
    var splitRight: () -> Void
    var splitDown: () -> Void
    var closePane: () -> Void
    var duplicatePane: () -> Void
    var focusNextPane: () -> Void
    var focusPreviousPane: () -> Void
    var copy: () -> Void
    var paste: () -> Void
    var clear: () -> Void
    var reset: () -> Void
}
```

This avoids a `NotificationCenter` broadcast where every pane coordinator receives `clear` or `reset`.

### Pattern 5: Honest Session Restore

Persist snapshots in local app support, for example:

```text
~/Library/Application Support/gridOS/session-v1.json
~/Library/Application Support/gridOS/recent-directories-v1.json
```

On launch:

- load snapshot if schema and panes are valid
- validate each last working directory with `FileManager.fileExists(atPath:isDirectory:)`
- start a fresh shell in that directory if valid
- fall back to home/default if missing
- keep the app usable if the file is corrupt by resetting to one default pane

On activity:

- update only the active pane or event source pane directory from `TerminalActivityEvent.workingDirectoryChanged`
- update recent directories after normalization
- debounce persistence so output-heavy sessions do not constantly write files

## UI and Interaction Guidance

### Layout

Use the existing terminal-first app frame:

- header and metrics strip stay stable
- right activity panel stays host-level/read-only
- multi-pane workspace replaces the single `TerminalWorkspaceView`
- active pane gets a subtle mode-aware border/indicator
- split handles must be visible enough to resize but not visually louder than terminal text

### Shortcuts

Recommended initial shortcuts:

| Action | Shortcut |
|--------|----------|
| Split Right | `Command-D` |
| Split Down | `Command-Shift-D` |
| Duplicate Pane | `Command-Option-D` |
| Close Pane | `Command-W` when more than one pane exists |
| Focus Next Pane | `Command-]` |
| Focus Previous Pane | `Command-[` |
| Resize Active Split | `Command-Control-Arrow` |

The planner may revise exact shortcuts if current menu conflicts are found, but the plan should include grep-verifiable shortcut strings.

### Close Behavior

Do not silently terminate multiple live panes with long-running work if the implementation can reasonably detect it. If SwiftTerm only exposes `running` and not foreground job details, use a conservative confirmation for close-pane/app-quit when there are multiple live panes, and keep copy honest: "Close this pane and terminate its shell?"

## Persistence and Privacy

Allowed to persist:

- pane layout tree
- pane IDs
- shell path and font profile fields already in preferences/configuration
- last known working directories
- active pane ID
- recent directories

Do not persist:

- shell output
- shell history
- environment variables
- commands typed by the user unless a later opt-in design exists
- process arguments
- API keys or provider context
- hidden file scans
- remote host inventory

## Validation Architecture

### Automated model coverage

Add `TerminalWorkspaceModelTests` or similarly named tests under `Tests/TerminalCoreTests` for:

- default one-pane workspace
- split right/down creates a split layout and a new descriptor
- close pane removes descriptor and promotes sibling layout
- duplicate pane copies configuration/working directory but gets a new pane ID
- focus next/previous follows stable visual order
- split fraction clamping
- snapshot encode/decode round trip
- missing directory fallback
- recent directory normalization/deduplication/max count
- active-pane routing with test spies

### Source gates

Add final source checks for:

```bash
rg "TerminalPaneLayout|TerminalPaneID|TerminalWorkspaceSnapshot|TerminalWorkspaceController" Sources/TerminalCore Tests/TerminalCoreTests
rg "splitRight|splitDown|duplicatePane|closePane|focusNextPane|focusPreviousPane" Sources/GridOSApp Sources/TerminalCore Tests
rg "activePaneID|selectedTextInActivePane|insertInActivePane|runInActivePane|focusActivePane" Sources/TerminalCore Sources/GridOSApp Tests
rg "session-v1.json|recent-directories-v1.json|Application Support|Running shell processes are not restored" Sources docs .planning
! rg "import SwiftTerm" Sources/GridOSApp
! rg "shell history|environment variables|UserDefaults.*output|UserDefaults.*history" Sources/GridOSApp Sources/TerminalCore Sources/GridOSKit
```

### Live smoke coverage

Add a DEBUG smoke path or deterministic launch arguments that can:

1. Launch the app.
2. Create at least two panes.
3. Run different marker commands in each active pane.
4. Switch focus and verify Command Intelligence insert/run closures target the active pane.
5. Close a pane and prove its shell PID no longer exists.
6. Relaunch and prove layout/directories restore while processes are fresh.

## Planning Implications

- Plan 01 should be pure model and persistence foundation; it can run fast and unblock later work.
- Plan 02 should refactor routing and process lifecycle before UI makes multiple panes visible.
- Plan 03 should add the workspace UI and native commands.
- Plan 04 should wire restore/recent directories/Settings/release docs.
- Plan 05 should add smoke fixture/evidence and final source checks.

