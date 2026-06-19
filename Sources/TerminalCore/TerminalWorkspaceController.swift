import Combine
import Foundation

@MainActor
public final class TerminalWorkspaceController: ObservableObject {
    @Published public private(set) var state: TerminalWorkspaceState

    private var controllersByPaneID: [TerminalPaneID: TerminalInteractionController]
    private let clipboard: any TerminalClipboard

    public var activePaneID: TerminalPaneID {
        state.activePaneID
    }

    public convenience init(state: TerminalWorkspaceState) {
        self.init(state: state, clipboard: SystemTerminalClipboard.shared)
    }

    init(state: TerminalWorkspaceState, clipboard: any TerminalClipboard) {
        self.state = state
        self.controllersByPaneID = [:]
        self.clipboard = clipboard
    }

    public func controller(for paneID: TerminalPaneID) -> TerminalInteractionController {
        if let controller = controllersByPaneID[paneID] {
            return controller
        }

        let controller = TerminalInteractionController(clipboard: clipboard)
        controllersByPaneID[paneID] = controller
        return controller
    }

    public func activatePane(_ paneID: TerminalPaneID) {
        guard state.layout.contains(paneID),
              state.panesByID[paneID] != nil,
              state.activePaneID != paneID else {
            return
        }

        objectWillChange.send()
        state.activePaneID = paneID
    }

    public func splitActivePane(axis: TerminalSplitAxis, newPaneID: TerminalPaneID = .generated()) {
        objectWillChange.send()
        state.splitActivePane(axis: axis, newPaneID: newPaneID)
        _ = controller(for: state.activePaneID)
    }

    public func duplicateActivePane(newPaneID: TerminalPaneID = .generated()) {
        objectWillChange.send()
        state.duplicateActivePane(newPaneID: newPaneID)
        _ = controller(for: state.activePaneID)
    }

    public func openDirectoryInNewPane(_ directory: String, newPaneID: TerminalPaneID = .generated()) {
        objectWillChange.send()
        state.openDirectoryInNewPane(directory, newPaneID: newPaneID)
        _ = controller(for: state.activePaneID)
    }

    @discardableResult
    public func movePane(
        _ sourcePaneID: TerminalPaneID,
        relativeTo targetPaneID: TerminalPaneID,
        placement: TerminalPanePlacement
    ) -> Bool {
        objectWillChange.send()
        guard state.movePane(sourcePaneID, relativeTo: targetPaneID, placement: placement) else {
            return false
        }

        focusActivePane()
        return true
    }

    @discardableResult
    public func closeActivePane() -> Bool {
        guard state.panesByID.count > 1 else {
            return false
        }

        objectWillChange.send()
        let closingPaneID = state.activePaneID
        controllersByPaneID[closingPaneID]?.terminate()
        guard state.closeActivePane() == closingPaneID else {
            return false
        }

        controllersByPaneID.removeValue(forKey: closingPaneID)
        return true
    }

    public func focusNextPane() {
        objectWillChange.send()
        state.focusNextPane()
        focusActivePane()
    }

    public func focusPreviousPane() {
        objectWillChange.send()
        state.focusPreviousPane()
        focusActivePane()
    }

    public func resizeActivePaneLeft() {
        resizeActivePane(axis: .horizontal, direction: .negative)
    }

    public func resizeActivePaneRight() {
        resizeActivePane(axis: .horizontal, direction: .positive)
    }

    public func resizeActivePaneUp() {
        resizeActivePane(axis: .vertical, direction: .negative)
    }

    public func resizeActivePaneDown() {
        resizeActivePane(axis: .vertical, direction: .positive)
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

    public func isActivePaneProcessRunning() -> Bool {
        controller(for: activePaneID).isProcessRunning()
    }

    public func hasRunningProcesses() -> Bool {
        state.layout.paneIDsInVisualOrder.contains { paneID in
            controller(for: paneID).isProcessRunning()
        }
    }

    @discardableResult
    public func copyActivePaneSelection() -> Bool {
        if controller(for: activePaneID).copySelection() {
            return true
        }

        for paneID in state.layout.paneIDsInVisualOrder where paneID != activePaneID {
            if controller(for: paneID).copySelection() {
                return true
            }
        }

        return false
    }

    @discardableResult
    public func copySelection(from sourcePaneID: TerminalPaneID) -> Bool {
        if state.layout.contains(sourcePaneID),
           controller(for: sourcePaneID).copySelection() {
            return true
        }

        if sourcePaneID != activePaneID,
           controller(for: activePaneID).copySelection() {
            return true
        }

        for paneID in state.layout.paneIDsInVisualOrder
            where paneID != sourcePaneID && paneID != activePaneID {
            if controller(for: paneID).copySelection() {
                return true
            }
        }

        return false
    }

    @discardableResult
    public func pasteIntoActivePane() -> Bool {
        controller(for: activePaneID).paste()
    }

    public func selectAllInActivePane() {
        controller(for: activePaneID).selectAll()
    }

    public func clearActivePane() {
        controller(for: activePaneID).clear()
    }

    public func resetActivePane() {
        controller(for: activePaneID).reset()
    }

    public func updateTerminalFontSize(_ fontSize: Double) {
        objectWillChange.send()
        state.updateTerminalFontSize(fontSize)
    }

    public func terminateActivePane() {
        controller(for: activePaneID).terminate()
    }

    public func terminateAllPanes() {
        for controller in controllersByPaneID.values {
            controller.terminate()
        }
        controllersByPaneID.removeAll()
    }

    public func handleActivity(_ event: TerminalActivityEvent, from paneID: TerminalPaneID) {
        switch event {
        case .focused:
            activatePane(paneID)
        case .copyRequested:
            copySelection(from: paneID)
        case .pasteRequested:
            pasteIntoActivePane()
        case .selectAllRequested:
            selectAllInActivePane()
        case .splitRightRequested:
            activatePane(paneID)
            splitActivePane(axis: .horizontal)
            focusActivePane()
        case .workingDirectoryChanged(let directory):
            objectWillChange.send()
            state.updateWorkingDirectory(directory, for: paneID)
        default:
            return
        }
    }

    public func snapshot() -> TerminalWorkspaceSnapshot {
        state.snapshot()
    }

    private func resizeActivePane(axis: TerminalSplitAxis, direction: SplitResizeDirection) {
        objectWillChange.send()
        state.layout = state.layout.resizingSplit(
            containing: activePaneID,
            axis: axis,
            direction: direction
        )
    }
}

private enum SplitResizeDirection {
    case negative
    case positive

    var delta: Double {
        switch self {
        case .negative:
            return -0.05
        case .positive:
            return 0.05
        }
    }
}

private extension TerminalPaneLayout {
    func resizingSplit(
        containing paneID: TerminalPaneID,
        axis targetAxis: TerminalSplitAxis,
        direction: SplitResizeDirection
    ) -> TerminalPaneLayout {
        resizedSplit(containing: paneID, axis: targetAxis, direction: direction).layout
    }

    func resizedSplit(
        containing paneID: TerminalPaneID,
        axis targetAxis: TerminalSplitAxis,
        direction: SplitResizeDirection
    ) -> (layout: TerminalPaneLayout, didResize: Bool) {
        switch self {
        case .pane:
            return (self, false)
        case .split(let axis, let fraction, let first, let second):
            if first.contains(paneID) {
                let resizedFirst = first.resizedSplit(containing: paneID, axis: targetAxis, direction: direction)
                if resizedFirst.didResize {
                    return (
                        .split(axis: axis, fraction: fraction, first: resizedFirst.layout, second: second),
                        true
                    )
                }
            }

            if second.contains(paneID) {
                let resizedSecond = second.resizedSplit(containing: paneID, axis: targetAxis, direction: direction)
                if resizedSecond.didResize {
                    return (
                        .split(axis: axis, fraction: fraction, first: first, second: resizedSecond.layout),
                        true
                    )
                }
            }

            guard axis == targetAxis,
                  contains(paneID) else {
                return (self, false)
            }

            return (
                .split(
                    axis: axis,
                    fraction: TerminalPaneLayout.clampedFraction(fraction + direction.delta),
                    first: first,
                    second: second
                ),
                true
            )
        }
    }
}
