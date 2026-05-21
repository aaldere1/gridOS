import Foundation

public enum TerminalWorkspacePersistenceError: Error, Equatable {
    case unreadableSnapshot
}

public struct TerminalWorkspaceSnapshotStore: @unchecked Sendable {
    private static let sessionFilename = "session-v1.json"
    private static let recentDirectoriesFilename = "recent-directories-v1.json"
    private static let corruptSessionFilename = "session-v1.corrupt.json"

    private let baseDirectory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(baseDirectory: URL = Self.defaultBaseDirectory(), fileManager: FileManager = .default) {
        self.baseDirectory = baseDirectory
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    public static func defaultBaseDirectory(fileManager: FileManager = .default) -> URL {
        let applicationSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support", isDirectory: true)

        return applicationSupportDirectory.appendingPathComponent("gridOS", isDirectory: true)
    }

    public func loadSnapshot(
        fallbackConfiguration: TerminalSessionConfiguration,
        directoryExists: (String) -> Bool
    ) throws -> TerminalWorkspaceSnapshot? {
        let url = sessionURL
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let snapshot = try decoder.decode(TerminalWorkspaceSnapshot.self, from: data)
            let restoredState = TerminalWorkspaceState(
                snapshot: snapshot,
                fallbackConfiguration: fallbackConfiguration,
                directoryExists: directoryExists
            )
            return restoredState.snapshot()
        } catch {
            try moveCorruptSnapshotAside()
            return nil
        }
    }

    public func saveSnapshot(_ snapshot: TerminalWorkspaceSnapshot) throws {
        try ensureBaseDirectoryExists()
        let data = try encoder.encode(snapshot)
        try data.write(to: sessionURL, options: .atomic)
    }

    public func loadRecentDirectories() throws -> [String] {
        let url = recentDirectoriesURL
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        let directories = try decoder.decode([String].self, from: data)
        return Self.normalizedStoredRecentDirectories(directories)
    }

    public func saveRecentDirectories(_ directories: [String]) throws {
        try ensureBaseDirectoryExists()
        let normalizedDirectories = Self.normalizedStoredRecentDirectories(directories)
        let data = try encoder.encode(normalizedDirectories)
        try data.write(to: recentDirectoriesURL, options: .atomic)
    }

    public func deleteStoredSession() throws {
        try removeFileIfPresent(sessionURL)
        try removeFileIfPresent(recentDirectoriesURL)
        try removeFileIfPresent(corruptSessionURL)
    }

    private var sessionURL: URL {
        baseDirectory.appendingPathComponent(Self.sessionFilename, isDirectory: false)
    }

    private var recentDirectoriesURL: URL {
        baseDirectory.appendingPathComponent(Self.recentDirectoriesFilename, isDirectory: false)
    }

    private var corruptSessionURL: URL {
        baseDirectory.appendingPathComponent(Self.corruptSessionFilename, isDirectory: false)
    }

    private func ensureBaseDirectoryExists() throws {
        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )
    }

    private func moveCorruptSnapshotAside() throws {
        try ensureBaseDirectoryExists()
        try removeFileIfPresent(corruptSessionURL)
        try fileManager.moveItem(at: sessionURL, to: corruptSessionURL)
    }

    private func removeFileIfPresent(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        try fileManager.removeItem(at: url)
    }

    private static func normalizedStoredRecentDirectories(_ directories: [String]) -> [String] {
        var result: [String] = []

        for directory in directories {
            let normalizedDirectory = TerminalWorkspaceSnapshot.normalizedDirectory(directory)
            guard !normalizedDirectory.isEmpty,
                  !result.contains(normalizedDirectory) else {
                continue
            }

            result.append(normalizedDirectory)
            if result.count == 10 {
                break
            }
        }

        return result
    }
}
