import Foundation

public enum TerminalCommandCenter {
    @available(*, deprecated, message: "Use TerminalWorkspaceController focused command routing.")
    public static func copy() {
        post(.gridOSTerminalCopy)
    }

    @available(*, deprecated, message: "Use TerminalWorkspaceController focused command routing.")
    public static func paste() {
        post(.gridOSTerminalPaste)
    }

    @available(*, deprecated, message: "Use TerminalWorkspaceController focused command routing.")
    public static func clear() {
        post(.gridOSTerminalClear)
    }

    @available(*, deprecated, message: "Use TerminalWorkspaceController focused command routing.")
    public static func reset() {
        post(.gridOSTerminalReset)
    }

    private static func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}

extension Notification.Name {
    @available(*, deprecated, message: "Use TerminalWorkspaceController focused command routing.")
    static let gridOSTerminalCopy = Notification.Name("gridOS.terminal.copy")
    @available(*, deprecated, message: "Use TerminalWorkspaceController focused command routing.")
    static let gridOSTerminalPaste = Notification.Name("gridOS.terminal.paste")
    @available(*, deprecated, message: "Use TerminalWorkspaceController focused command routing.")
    static let gridOSTerminalClear = Notification.Name("gridOS.terminal.clear")
    @available(*, deprecated, message: "Use TerminalWorkspaceController focused command routing.")
    static let gridOSTerminalReset = Notification.Name("gridOS.terminal.reset")
}
