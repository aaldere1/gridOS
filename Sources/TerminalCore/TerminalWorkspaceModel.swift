import Foundation

public struct TerminalPaneID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static func generated() -> TerminalPaneID {
        TerminalPaneID(rawValue: UUID().uuidString.lowercased())
    }
}

public enum TerminalSplitAxis: String, Codable, Equatable, Sendable {
    /// Left/right panes.
    case horizontal
    /// Top/bottom panes.
    case vertical
}

public indirect enum TerminalPaneLayout: Codable, Equatable, Sendable {
    case pane(TerminalPaneID)
    case split(axis: TerminalSplitAxis, fraction: Double, first: TerminalPaneLayout, second: TerminalPaneLayout)

    public var paneIDsInVisualOrder: [TerminalPaneID] {
        switch self {
        case .pane(let id):
            return [id]
        case .split(_, _, let first, let second):
            return first.paneIDsInVisualOrder + second.paneIDsInVisualOrder
        }
    }

    public func contains(_ paneID: TerminalPaneID) -> Bool {
        switch self {
        case .pane(let id):
            return id == paneID
        case .split(_, _, let first, let second):
            return first.contains(paneID) || second.contains(paneID)
        }
    }

    public func replacingPane(_ paneID: TerminalPaneID, with replacement: TerminalPaneLayout) -> TerminalPaneLayout {
        switch self {
        case .pane(let id):
            return id == paneID ? replacement : self
        case .split(let axis, let fraction, let first, let second):
            return .split(
                axis: axis,
                fraction: Self.clampedFraction(fraction),
                first: first.replacingPane(paneID, with: replacement),
                second: second.replacingPane(paneID, with: replacement)
            )
        }
    }

    public func removingPane(_ paneID: TerminalPaneID) -> TerminalPaneLayout? {
        switch self {
        case .pane(let id):
            return id == paneID ? nil : self
        case .split(let axis, let fraction, let first, let second):
            let updatedFirst = first.removingPane(paneID)
            let updatedSecond = second.removingPane(paneID)

            switch (updatedFirst, updatedSecond) {
            case let (.some(first), .some(second)):
                return .split(
                    axis: axis,
                    fraction: Self.clampedFraction(fraction),
                    first: first,
                    second: second
                )
            case let (.some(first), .none):
                return first
            case let (.none, .some(second)):
                return second
            case (.none, .none):
                return nil
            }
        }
    }

    public static func clampedFraction(_ fraction: Double) -> Double {
        min(0.80, max(0.20, fraction))
    }
}

public struct TerminalPaneDescriptor: Codable, Equatable, Identifiable, Sendable {
    public var id: TerminalPaneID
    public var configuration: TerminalSessionConfiguration
    public var title: String?
    public var lastWorkingDirectory: String?
    public var isRestored: Bool

    public init(
        id: TerminalPaneID,
        configuration: TerminalSessionConfiguration,
        title: String? = nil,
        lastWorkingDirectory: String? = nil,
        isRestored: Bool = false
    ) {
        self.id = id
        self.configuration = configuration
        self.title = title
        self.lastWorkingDirectory = lastWorkingDirectory
        self.isRestored = isRestored
    }
}

public struct TerminalWorkspaceSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var layout: TerminalPaneLayout
    public var panes: [TerminalPaneDescriptor]
    public var activePaneID: TerminalPaneID
    public var recentDirectories: [String]

    public init(
        schemaVersion: Int = Self.currentSchemaVersion,
        layout: TerminalPaneLayout,
        panes: [TerminalPaneDescriptor],
        activePaneID: TerminalPaneID,
        recentDirectories: [String] = []
    ) {
        self.schemaVersion = schemaVersion
        self.layout = layout
        self.panes = panes
        self.activePaneID = activePaneID
        self.recentDirectories = Self.normalizedRecentDirectories(recentDirectories)
    }

    public static func normalizedRecentDirectories(_ directories: [String]) -> [String] {
        directories.reduce(into: [String]()) { result, directory in
            let normalizedDirectory = normalizedDirectory(directory)
            guard !normalizedDirectory.isEmpty else {
                return
            }

            result.removeAll { $0 == normalizedDirectory }
            result.insert(normalizedDirectory, at: 0)
            if result.count > 10 {
                result.removeLast(result.count - 10)
            }
        }
    }

    public static func normalizedDirectory(_ directory: String?) -> String {
        directory?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

public struct TerminalWorkspaceState: Equatable, Sendable {
    public var layout: TerminalPaneLayout
    public var panesByID: [TerminalPaneID: TerminalPaneDescriptor]
    public var activePaneID: TerminalPaneID
    public var recentDirectories: [String]

    public init(defaultConfiguration: TerminalSessionConfiguration) {
        let paneID = TerminalPaneID(rawValue: "primary")
        let descriptor = TerminalPaneDescriptor(
            id: paneID,
            configuration: defaultConfiguration,
            lastWorkingDirectory: defaultConfiguration.workingDirectory
        )

        self.layout = .pane(paneID)
        self.panesByID = [paneID: descriptor]
        self.activePaneID = paneID
        self.recentDirectories = TerminalWorkspaceSnapshot.normalizedRecentDirectories(
            [defaultConfiguration.workingDirectory].compactMap { $0 }
        )
    }

    public init(
        snapshot: TerminalWorkspaceSnapshot,
        fallbackConfiguration: TerminalSessionConfiguration,
        directoryExists: (String) -> Bool
    ) {
        guard snapshot.schemaVersion == TerminalWorkspaceSnapshot.currentSchemaVersion,
              !snapshot.panes.isEmpty else {
            self = Self(defaultConfiguration: fallbackConfiguration)
            return
        }

        let layoutIDs = Set(snapshot.layout.paneIDsInVisualOrder)
        var restoredPanes = [TerminalPaneID: TerminalPaneDescriptor]()

        for var pane in snapshot.panes where layoutIDs.contains(pane.id) {
            if let restoredDirectory = pane.lastWorkingDirectory,
               !restoredDirectory.isEmpty,
               directoryExists(restoredDirectory) {
                pane.configuration.workingDirectory = restoredDirectory
            } else {
                pane.lastWorkingDirectory = nil
                pane.configuration.workingDirectory = fallbackConfiguration.workingDirectory
            }
            pane.isRestored = true
            restoredPanes[pane.id] = pane
        }

        let visualOrder = snapshot.layout.paneIDsInVisualOrder.filter { restoredPanes[$0] != nil }
        guard let firstPaneID = visualOrder.first else {
            self = Self(defaultConfiguration: fallbackConfiguration)
            return
        }

        self.layout = snapshot.layout
        self.panesByID = restoredPanes
        self.activePaneID = restoredPanes[snapshot.activePaneID] == nil ? firstPaneID : snapshot.activePaneID
        self.recentDirectories = TerminalWorkspaceSnapshot.normalizedRecentDirectories(snapshot.recentDirectories)
    }

    public func snapshot() -> TerminalWorkspaceSnapshot {
        let orderedPanes = layout.paneIDsInVisualOrder.compactMap { panesByID[$0] }
        return TerminalWorkspaceSnapshot(
            layout: layout,
            panes: orderedPanes,
            activePaneID: activePaneID,
            recentDirectories: recentDirectories
        )
    }

    public mutating func splitActivePane(axis: TerminalSplitAxis, newPaneID: TerminalPaneID = .generated()) {
        guard let activePane = panesByID[activePaneID] else {
            return
        }

        let newDescriptor = duplicatedDescriptor(from: activePane, id: newPaneID)
        let replacement = TerminalPaneLayout.split(
            axis: axis,
            fraction: TerminalPaneLayout.clampedFraction(0.50),
            first: .pane(activePaneID),
            second: .pane(newPaneID)
        )

        layout = layout.replacingPane(activePaneID, with: replacement)
        panesByID[newPaneID] = newDescriptor
        activePaneID = newPaneID

        if let directory = newDescriptor.lastWorkingDirectory {
            recordRecentDirectory(directory)
        }
    }

    public mutating func duplicateActivePane(newPaneID: TerminalPaneID = .generated()) {
        splitActivePane(axis: .horizontal, newPaneID: newPaneID)
    }

    public mutating func openDirectoryInNewPane(_ directory: String, newPaneID: TerminalPaneID = .generated()) {
        guard let activePane = panesByID[activePaneID] else {
            return
        }

        let normalizedDirectory = TerminalWorkspaceSnapshot.normalizedDirectory(directory)
        guard !normalizedDirectory.isEmpty else {
            return
        }

        var configuration = activePane.configuration
        configuration.workingDirectory = normalizedDirectory
        let descriptor = TerminalPaneDescriptor(
            id: newPaneID,
            configuration: configuration,
            lastWorkingDirectory: normalizedDirectory,
            isRestored: false
        )
        let replacement = TerminalPaneLayout.split(
            axis: .horizontal,
            fraction: TerminalPaneLayout.clampedFraction(0.50),
            first: .pane(activePaneID),
            second: .pane(newPaneID)
        )

        layout = layout.replacingPane(activePaneID, with: replacement)
        panesByID[newPaneID] = descriptor
        activePaneID = newPaneID
        recordRecentDirectory(normalizedDirectory)
    }

    @discardableResult
    public mutating func closeActivePane() -> TerminalPaneID? {
        guard panesByID.count > 1,
              let updatedLayout = layout.removingPane(activePaneID) else {
            return nil
        }

        let closedPaneID = activePaneID
        panesByID.removeValue(forKey: closedPaneID)
        layout = updatedLayout
        activePaneID = layout.paneIDsInVisualOrder.first ?? panesByID.keys.sorted { $0.rawValue < $1.rawValue }.first ?? "primary"
        return closedPaneID
    }

    public mutating func focusNextPane() {
        focus(offset: 1)
    }

    public mutating func focusPreviousPane() {
        focus(offset: -1)
    }

    public mutating func updateWorkingDirectory(_ directory: String?, for paneID: TerminalPaneID) {
        let normalizedDirectory = TerminalWorkspaceSnapshot.normalizedDirectory(directory)
        guard !normalizedDirectory.isEmpty,
              var pane = panesByID[paneID] else {
            return
        }

        pane.lastWorkingDirectory = normalizedDirectory
        pane.configuration.workingDirectory = normalizedDirectory
        panesByID[paneID] = pane
        recordRecentDirectory(normalizedDirectory)
    }

    public mutating func recordRecentDirectory(_ directory: String?) {
        let normalizedDirectory = TerminalWorkspaceSnapshot.normalizedDirectory(directory)
        guard !normalizedDirectory.isEmpty else {
            return
        }

        recentDirectories.removeAll { $0 == normalizedDirectory }
        recentDirectories.insert(normalizedDirectory, at: 0)

        if recentDirectories.count > 10 {
            recentDirectories.removeLast(recentDirectories.count - 10)
        }
    }

    private func duplicatedDescriptor(from descriptor: TerminalPaneDescriptor, id: TerminalPaneID) -> TerminalPaneDescriptor {
        var configuration = descriptor.configuration
        if let lastWorkingDirectory = descriptor.lastWorkingDirectory {
            configuration.workingDirectory = lastWorkingDirectory
        }

        return TerminalPaneDescriptor(
            id: id,
            configuration: configuration,
            title: descriptor.title,
            lastWorkingDirectory: descriptor.lastWorkingDirectory ?? configuration.workingDirectory,
            isRestored: false
        )
    }

    private mutating func focus(offset: Int) {
        let paneIDs = layout.paneIDsInVisualOrder
        guard let currentIndex = paneIDs.firstIndex(of: activePaneID), !paneIDs.isEmpty else {
            return
        }

        let nextIndex = (currentIndex + offset + paneIDs.count) % paneIDs.count
        activePaneID = paneIDs[nextIndex]
    }
}
