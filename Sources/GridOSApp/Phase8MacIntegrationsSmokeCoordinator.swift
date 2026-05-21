#if DEBUG
import Foundation
import Integrations

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

        writeNotificationSmokeMarker(resultMessage: "Notification smoke scheduled.")
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
        let result = await deliverWithTimeout(request)
        writeNotificationSmokeMarker(resultMessage: result.message)
    }

    private func deliverWithTimeout(_ request: NotificationDeliveryRequest) async -> NotificationDeliveryResult {
        let notificationClient = notificationClient

        return await withTaskGroup(of: NotificationDeliveryResult.self) { group in
            group.addTask {
                await notificationClient.deliver(request)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                return .failed("Notification smoke timed out before macOS returned delivery status.")
            }

            let result = await group.next() ?? .failed("Notification smoke did not return a delivery status.")
            group.cancelAll()
            return result
        }
    }

    private func writeNotificationSmokeMarker(resultMessage: String) {
        let markerBody = [
            Self.notificationSmokeMarker,
            Self.notificationSmokeTitle,
            Self.notificationSmokeBody,
            resultMessage
        ].joined(separator: "\n") + "\n"

        try? markerBody.write(
            toFile: Self.notificationSmokePath,
            atomically: true,
            encoding: .utf8
        )
    }
}
#endif
