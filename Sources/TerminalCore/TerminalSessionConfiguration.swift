import Foundation

public struct TerminalSessionConfiguration: Codable, Equatable, Sendable {
    public var shellPath: String
    public var shellArguments: [String]
    public var workingDirectory: String?
    public var fontName: String?
    public var fontSize: Double
    public var startupCommand: String?

    public init(
        shellPath: String,
        shellArguments: [String] = [],
        workingDirectory: String? = nil,
        fontName: String? = nil,
        fontSize: Double = 13,
        startupCommand: String? = nil
    ) {
        self.shellPath = shellPath
        self.shellArguments = shellArguments
        self.workingDirectory = workingDirectory
        self.fontName = fontName
        self.fontSize = fontSize
        self.startupCommand = startupCommand
    }

    public static var `default`: TerminalSessionConfiguration {
        TerminalSessionConfiguration(
            shellPath: resolvedDefaultShell(),
            workingDirectory: FileManager.default.homeDirectoryForCurrentUser.path
        )
    }

    public var shellDisplayName: String {
        URL(fileURLWithPath: shellPath).lastPathComponent
    }

    public var loginShellName: String {
        "-" + shellDisplayName
    }

    public static func resolvedDefaultShell(environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        guard let shell = environment["SHELL"], shell.starts(with: "/"), !shell.isEmpty else {
            return "/bin/zsh"
        }

        return shell
    }

    public static func fromProcessArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> TerminalSessionConfiguration {
        var configuration = TerminalSessionConfiguration.default

        if let commandIndex = arguments.firstIndex(of: "--cmd"),
           arguments.indices.contains(commandIndex + 1) {
            configuration.startupCommand = arguments[(commandIndex + 1)...]
                .joined(separator: " ")
        }

        return configuration
    }
}
