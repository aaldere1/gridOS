public enum TerminalActivityEvent: Equatable, Sendable {
    case focused
    case input(byteCount: Int)
    case output(byteCount: Int)
    case resized(columns: Int, rows: Int)
    case titleChanged(String)
    case workingDirectoryChanged(String?)
    case processStarted(shell: String)
    case processTerminated(exitCode: Int32?)
}
