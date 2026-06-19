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

@MainActor
final class TerminalWorkspaceCommandCenter: ObservableObject {
    static let shared = TerminalWorkspaceCommandCenter()

    @Published private(set) var commands: TerminalWorkspaceCommandsValue?

    private init() {}

    func install(_ commands: TerminalWorkspaceCommandsValue) {
        self.commands = commands
    }

    func uninstall() {
        commands = nil
    }

    func splitRight() {
        commands?.splitRight()
    }

    func splitDown() {
        commands?.splitDown()
    }

    func duplicatePane() {
        commands?.duplicatePane()
    }

    func openFolder() {
        commands?.openFolder()
    }

    func closePane() {
        commands?.closePane()
    }

    func focusNextPane() {
        commands?.focusNextPane()
    }

    func focusPreviousPane() {
        commands?.focusPreviousPane()
    }

    func resizePaneLeft() {
        commands?.resizePaneLeft()
    }

    func resizePaneRight() {
        commands?.resizePaneRight()
    }

    func resizePaneUp() {
        commands?.resizePaneUp()
    }

    func resizePaneDown() {
        commands?.resizePaneDown()
    }

    func copy() {
        commands?.copy()
    }

    func paste() {
        commands?.paste()
    }

    func selectAll() {
        commands?.selectAll()
    }

    func clear() {
        commands?.clear()
    }

    func reset() {
        commands?.reset()
    }
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
