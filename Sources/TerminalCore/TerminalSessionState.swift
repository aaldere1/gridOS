import Foundation

public enum TerminalSessionState: Equatable, Sendable {
    case idle
    case running
    case terminated(exitCode: Int32?)

    public var isActive: Bool {
        if case .running = self {
            return true
        }

        return false
    }
}
