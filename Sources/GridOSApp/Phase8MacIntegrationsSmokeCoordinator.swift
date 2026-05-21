#if DEBUG
import Foundation
import Integrations

@MainActor
struct Phase8MacIntegrationsSmokeCoordinator {
    static let notificationSmokeArgument = "--phase8-notification-smoke"
    static let notificationSmokeMarker = "PHASE8_NOTIFICATION_SMOKE"
    static let notificationSmokePath = "/tmp/gridos_phase8_notification_smoke.txt"
    static let notificationSmokeTitle = "gridOS work finished"
    static let notificationSmokeBody = "A long-running task completed in your workspace."

    private let notificationClient: LocalNotificationClient

    init(notificationClient: LocalNotificationClient = LocalNotificationClient()) {
        self.notificationClient = notificationClient
    }

    func startIfRequested(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard arguments.contains(Self.notificationSmokeArgument) else {
            return
        }

        Task {
            await runNotificationSmoke()
        }
    }

    private func runNotificationSmoke() async {
        let request = NotificationDeliveryRequest(
            identifier: "gridos.work-finished.phase8-smoke",
            title: Self.notificationSmokeTitle,
            body: Self.notificationSmokeBody
        )
        let result = await notificationClient.deliver(request)
        let markerBody = [
            Self.notificationSmokeMarker,
            request.title,
            request.body,
            result.message
        ].joined(separator: "\n") + "\n"

        try? markerBody.write(
            toFile: Self.notificationSmokePath,
            atomically: true,
            encoding: .utf8
        )
    }
}
#endif
