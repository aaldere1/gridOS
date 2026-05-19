import Foundation

public enum TerminalCommandCenter {
    public static func copy() {
        post(.gridOSTerminalCopy)
    }

    public static func paste() {
        post(.gridOSTerminalPaste)
    }

    public static func clear() {
        post(.gridOSTerminalClear)
    }

    public static func reset() {
        post(.gridOSTerminalReset)
    }

    private static func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}

extension Notification.Name {
    static let gridOSTerminalCopy = Notification.Name("gridOS.terminal.copy")
    static let gridOSTerminalPaste = Notification.Name("gridOS.terminal.paste")
    static let gridOSTerminalClear = Notification.Name("gridOS.terminal.clear")
    static let gridOSTerminalReset = Notification.Name("gridOS.terminal.reset")
}
