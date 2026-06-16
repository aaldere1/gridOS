import Combine
import Foundation

@MainActor
protocol TerminalInteractionControllingTerminal: AnyObject {
    func getSelection() -> String?
    func sendText(_ text: String)
    func focusTerminal()
    func copySelection()
    func paste()
    func selectAll()
    func clear()
    func reset()
    func terminate()
    func terminateEnsuringProcessExit()
    func isProcessRunning() -> Bool
}

@MainActor
public final class TerminalInteractionController: ObservableObject {
    private var terminal: (any TerminalInteractionControllingTerminal)?

    public init() {}

    public func selectedText() -> String? {
        guard let selection = terminal?.getSelection(),
              !selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return selection
    }

    public func insert(_ text: String) {
        terminal?.sendText(text)
    }

    public func run(_ command: String) {
        terminal?.sendText(command.removingTrailingNewlines() + "\n")
    }

    public func focusTerminal() {
        terminal?.focusTerminal()
    }

    public func copySelection() {
        terminal?.copySelection()
    }

    public func paste() {
        terminal?.paste()
    }

    public func selectAll() {
        terminal?.selectAll()
    }

    public func clear() {
        terminal?.clear()
    }

    public func reset() {
        terminal?.reset()
    }

    public func terminate() {
        terminal?.terminateEnsuringProcessExit()
    }

    public func isProcessRunning() -> Bool {
        terminal?.isProcessRunning() ?? false
    }

    func attachedTerminal<T: AnyObject>(as type: T.Type) -> T? {
        terminal as? T
    }

    func owns(_ terminal: any TerminalInteractionControllingTerminal) -> Bool {
        self.terminal === terminal
    }

    func attach(_ terminal: any TerminalInteractionControllingTerminal) {
        if let currentTerminal = self.terminal,
           currentTerminal !== terminal {
            currentTerminal.terminateEnsuringProcessExit()
        }

        self.terminal = terminal
    }

    func detach(_ terminal: any TerminalInteractionControllingTerminal) {
        guard self.terminal === terminal else {
            return
        }

        self.terminal = nil
    }
}

private extension String {
    func removingTrailingNewlines() -> String {
        var value = self
        while value.last?.isNewline == true {
            value.removeLast()
        }
        return value
    }
}
