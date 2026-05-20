import Combine
import Foundation

@MainActor
protocol TerminalInteractionControllingTerminal: AnyObject {
    func getSelection() -> String?
    func sendText(_ text: String)
    func focusTerminal()
}

@MainActor
public final class TerminalInteractionController: ObservableObject {
    private weak var terminal: (any TerminalInteractionControllingTerminal)?

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

    func attach(_ terminal: any TerminalInteractionControllingTerminal) {
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
