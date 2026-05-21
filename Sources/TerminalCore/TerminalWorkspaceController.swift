import Combine
import Foundation

@MainActor
public final class TerminalWorkspaceController: ObservableObject {
    @Published public private(set) var state: TerminalWorkspaceState

    private var controllersByPaneID: [TerminalPaneID: TerminalInteractionController]

    public var activePaneID: TerminalPaneID {
        state.activePaneID
    }

    public init(state: TerminalWorkspaceState) {
        self.state = state
        self.controllersByPaneID = [:]
    }

    public func controller(for paneID: TerminalPaneID) -> TerminalInteractionController {
        if let controller = controllersByPaneID[paneID] {
            return controller
        }

        let controller = TerminalInteractionController()
        controllersByPaneID[paneID] = controller
        return controller
    }

    public func activatePane(_ paneID: TerminalPaneID) {
        guard state.layout.contains(paneID),
              state.panesByID[paneID] != nil else {
            return
        }

        state.activePaneID = paneID
    }

    public func splitActivePane(axis: TerminalSplitAxis, newPaneID: TerminalPaneID = .generated()) {
        state.splitActivePane(axis: axis, newPaneID: newPaneID)
        _ = controller(for: state.activePaneID)
    }

    public func duplicateActivePane(newPaneID: TerminalPaneID = .generated()) {
        state.duplicateActivePane(newPaneID: newPaneID)
        _ = controller(for: state.activePaneID)
    }

    @discardableResult
    public func closeActivePane() -> Bool {
        guard state.panesByID.count > 1 else {
            return false
        }

        let closingPaneID = state.activePaneID
        controllersByPaneID[closingPaneID]?.terminate()
        guard state.closeActivePane() == closingPaneID else {
            return false
        }

        controllersByPaneID.removeValue(forKey: closingPaneID)
        return true
    }

    public func focusNextPane() {
        state.focusNextPane()
        focusActivePane()
    }

    public func focusPreviousPane() {
        state.focusPreviousPane()
        focusActivePane()
    }

    public func selectedTextInActivePane() -> String? {
        controller(for: activePaneID).selectedText()
    }

    public func insertInActivePane(_ text: String) {
        controller(for: activePaneID).insert(text)
    }

    public func runInActivePane(_ command: String) {
        controller(for: activePaneID).run(command)
    }

    public func focusActivePane() {
        controller(for: activePaneID).focusTerminal()
    }

    public func copyActivePaneSelection() {
        controller(for: activePaneID).copySelection()
    }

    public func pasteIntoActivePane() {
        controller(for: activePaneID).paste()
    }

    public func clearActivePane() {
        controller(for: activePaneID).clear()
    }

    public func resetActivePane() {
        controller(for: activePaneID).reset()
    }

    public func terminateActivePane() {
        controller(for: activePaneID).terminate()
    }

    public func terminateAllPanes() {
        for controller in controllersByPaneID.values {
            controller.terminate()
        }
    }

    public func handleActivity(_ event: TerminalActivityEvent, from paneID: TerminalPaneID) {
        guard case .workingDirectoryChanged(let directory) = event else {
            return
        }

        state.updateWorkingDirectory(directory, for: paneID)
    }

    public func snapshot() -> TerminalWorkspaceSnapshot {
        state.snapshot()
    }
}
