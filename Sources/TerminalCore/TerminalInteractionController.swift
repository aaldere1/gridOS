import AppKit
import Combine
import Foundation

@MainActor
protocol TerminalInteractionControllingTerminal: AnyObject {
    func getSelection() -> String?
    func sendText(_ text: String)
    func focusTerminal()
    func copySelection()
    func paste()
    func pasteText(_ text: String)
    func selectAll()
    func clear()
    func reset()
    func terminate()
    func terminateEnsuringProcessExit()
    func isProcessRunning() -> Bool
}

@MainActor
protocol TerminalClipboard: AnyObject {
    func readString() -> String?
    func writeString(_ string: String)
}

@MainActor
final class SystemTerminalClipboard: TerminalClipboard {
    static let shared = SystemTerminalClipboard()

    private init() {}

    func readString() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    func writeString(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}

@MainActor
public final class TerminalInteractionController: ObservableObject {
    private var terminal: (any TerminalInteractionControllingTerminal)?
    private let clipboard: any TerminalClipboard

    public convenience init() {
        self.init(clipboard: SystemTerminalClipboard.shared)
    }

    init(clipboard: any TerminalClipboard) {
        self.clipboard = clipboard
    }

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

    @discardableResult
    public func copySelection() -> Bool {
        guard let selection = terminal?.getSelection(),
              !selection.isEmpty else {
            return false
        }

        clipboard.writeString(selection)
        return true
    }

    @discardableResult
    public func paste() -> Bool {
        guard let text = clipboard.readString(),
              !text.isEmpty else {
            terminal?.paste()
            return false
        }

        terminal?.pasteText(text)
        return true
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
