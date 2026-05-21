import Foundation
@preconcurrency import UserNotifications

public struct UserNotificationSettingsSnapshot: Equatable, Sendable {
    public let authorizationStatus: UNAuthorizationStatus

    public init(authorizationStatus: UNAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }
}

public protocol UserNotificationCenterClient: Sendable {
    func notificationSettings() async -> UserNotificationSettingsSnapshot
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

public struct LiveUserNotificationCenterClient: UserNotificationCenterClient {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.center = center
    }

    public func notificationSettings() async -> UserNotificationSettingsSnapshot {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(
                    returning: UserNotificationSettingsSnapshot(
                        authorizationStatus: settings.authorizationStatus
                    )
                )
            }
        }
    }

    public func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: options) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    public func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

public struct LocalNotificationClient: Sendable {
    private let center: any UserNotificationCenterClient

    public init(center: any UserNotificationCenterClient = LiveUserNotificationCenterClient()) {
        self.center = center
    }

    public func authorizationState() async -> NotificationAuthorizationState {
        let settings = await center.notificationSettings()
        return Self.authorizationState(from: settings.authorizationStatus)
    }

    public func requestAuthorization() async -> NotificationAuthorizationState {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            return await authorizationState()
        } catch {
            return .denied
        }
    }

    public func deliver(_ request: NotificationDeliveryRequest) async -> NotificationDeliveryResult {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        let notificationRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(notificationRequest)
            return .delivered
        } catch {
            return .failed("Integration unavailable. Check macOS permissions and try again.")
        }
    }

    private static func authorizationState(from status: UNAuthorizationStatus) -> NotificationAuthorizationState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        @unknown default:
            return .denied
        }
    }
}
