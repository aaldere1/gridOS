import GridOSKit
import Integrations
import SwiftUI

struct MacIntegrationsSettingsView: View {
    @State private var notificationAuthorizationState: NotificationAuthorizationState = .notDetermined
    @State private var isRequestingNotifications = false

    private let notificationClient: LocalNotificationClient

    init(notificationClient: LocalNotificationClient = LocalNotificationClient()) {
        self.notificationClient = notificationClient
    }

    var body: some View {
        Section("macOS Integrations") {
            if GridOSAppPreferences.menuBarExtraAvailable {
                integrationStatusRow(
                    title: "Menu Bar Extra",
                    detail: "The release build keeps the terminal workspace as the primary surface. Menu bar controls remain staged until they have a complete workflow."
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                integrationStatusRow(
                    title: "Long-running Work Alerts",
                    detail: "Notification support is staged for a later release. gridOS will not request notification permission or post local alerts in this version."
                )

                Button("Check Notification Permission") {
                    Task {
                        await checkNotificationPermission()
                    }
                }
                .disabled(isRequestingNotifications)
                .accessibilityLabel("Check Notification Permission")

                Text(notificationStatusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            integrationStatusRow(
                title: "Spotlight Workspace Indexing",
                detail: "Spotlight indexing is disabled in this release. Terminal output, command history, generated commands, prompts, secrets, and full paths are never indexed."
            )

            Button("Manage Stored Secrets") {
                CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
            }
            .accessibilityLabel("Manage Stored Secrets")
        }
        .task {
            await refreshNotificationStatus()
        }
    }

    private func integrationStatusRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var notificationStatusText: String {
        switch notificationAuthorizationState {
        case .authorized, .provisional, .ephemeral:
            return "macOS already allows gridOS notifications, but this release does not post local alerts."
        case .denied:
            return "Notifications are blocked in macOS Settings. Terminal work continues normally."
        case .notDetermined:
            return "gridOS has not requested notification permission. Terminal work continues normally."
        }
    }

    @MainActor
    private func refreshNotificationStatus() async {
        notificationAuthorizationState = await notificationClient.authorizationState()
    }

    @MainActor
    private func checkNotificationPermission() async {
        isRequestingNotifications = true
        defer { isRequestingNotifications = false }

        notificationAuthorizationState = await notificationClient.authorizationState()
    }
}
