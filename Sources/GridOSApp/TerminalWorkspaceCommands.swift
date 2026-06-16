import SwiftUI

struct TerminalWorkspaceCommandsValue {
    let splitRight: @MainActor () -> Void
    let splitDown: @MainActor () -> Void
    let duplicatePane: @MainActor () -> Void
    let openFolder: @MainActor () -> Void
    let closePane: @MainActor () -> Void
    let focusNextPane: @MainActor () -> Void
    let focusPreviousPane: @MainActor () -> Void
    let resizePaneLeft: @MainActor () -> Void
    let resizePaneRight: @MainActor () -> Void
    let resizePaneUp: @MainActor () -> Void
    let resizePaneDown: @MainActor () -> Void
    let copy: @MainActor () -> Void
    let paste: @MainActor () -> Void
    let selectAll: @MainActor () -> Void
    let clear: @MainActor () -> Void
    let reset: @MainActor () -> Void
}

private struct TerminalWorkspaceCommandsKey: FocusedValueKey {
    typealias Value = TerminalWorkspaceCommandsValue
}

extension FocusedValues {
    var terminalWorkspaceCommands: TerminalWorkspaceCommandsValue? {
        get { self[TerminalWorkspaceCommandsKey.self] }
        set { self[TerminalWorkspaceCommandsKey.self] = newValue }
    }
}
