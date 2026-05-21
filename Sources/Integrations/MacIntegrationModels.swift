import Foundation
import GridOSKit

public struct MacIntegrationPreferences: Equatable, Sendable {
    public var showMenuBarExtra: Bool
    public var notificationsEnabled: Bool
    public var indexWorkspaceMetadata: Bool

    public init(
        showMenuBarExtra: Bool = GridOSAppPreferences.defaultShowMenuBarExtra,
        notificationsEnabled: Bool = GridOSAppPreferences.defaultNotificationsEnabled,
        indexWorkspaceMetadata: Bool = GridOSAppPreferences.defaultIndexWorkspaceMetadata
    ) {
        self.showMenuBarExtra = showMenuBarExtra
        self.notificationsEnabled = notificationsEnabled
        self.indexWorkspaceMetadata = indexWorkspaceMetadata
    }

    public static let defaultValue = MacIntegrationPreferences()
}

public struct MenuBarStatusSnapshot: Equatable, Sendable {
    public var activeWorkspaceLabel: String
    public var shellDisplayName: String
    public var cpuText: String
    public var memoryText: String
    public var networkText: String
    public var batteryText: String
    public var thermalText: String
    public var isStale: Bool

    public init(
        activeWorkspaceLabel: String = "Active workspace",
        shellDisplayName: String = "",
        cpuText: String = "CPU unavailable",
        memoryText: String = "MEM unavailable",
        networkText: String = "NET unavailable",
        batteryText: String = "BAT unavailable",
        thermalText: String = "THERM unavailable",
        isStale: Bool = false
    ) {
        self.activeWorkspaceLabel = activeWorkspaceLabel
        self.shellDisplayName = shellDisplayName
        self.cpuText = cpuText
        self.memoryText = memoryText
        self.networkText = networkText
        self.batteryText = batteryText
        self.thermalText = thermalText
        self.isStale = isStale
    }
}

public struct MenuBarRecentDirectory: Equatable, Identifiable, Sendable {
    public var id: String { path }

    public let path: String
    public let displayName: String

    public init(path: String, displayName: String? = nil) {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        self.path = trimmedPath

        let basename = URL(fileURLWithPath: trimmedPath).lastPathComponent
        let resolvedDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let resolvedDisplayName, !resolvedDisplayName.isEmpty {
            self.displayName = resolvedDisplayName
        } else if !basename.isEmpty {
            self.displayName = basename
        } else {
            self.displayName = "Directory"
        }
    }
}

public enum MenuBarAction: String, CaseIterable, Equatable, Sendable {
    case openGridOS
    case openSettings
    case quitGridOS
    case openRecentDirectory
}

public enum NotificationAuthorizationState: String, Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

public struct NotificationDeliveryRequest: Equatable, Sendable {
    public let identifier: String
    public let title: String
    public let body: String

    public init(identifier: String, title: String, body: String) {
        self.identifier = identifier
        self.title = title
        self.body = body
    }

    public static func gridOSWorkFinished(
        identifier: String = "gridos.work-finished.\(UUID().uuidString.lowercased())"
    ) -> NotificationDeliveryRequest {
        NotificationDeliveryRequest(
            identifier: identifier,
            title: "gridOS work finished",
            body: "A long-running task completed in your workspace."
        )
    }
}

public struct NotificationDeliveryResult: Equatable, Sendable {
    public let delivered: Bool
    public let message: String

    public init(delivered: Bool, message: String) {
        self.delivered = delivered
        self.message = message
    }

    public static let delivered = NotificationDeliveryResult(
        delivered: true,
        message: "Notification delivered."
    )

    public static func failed(_ message: String) -> NotificationDeliveryResult {
        NotificationDeliveryResult(delivered: false, message: message)
    }
}
