import GridOSKit
import Integrations
import SwiftUI

struct MacIntegrationsSettingsView: View {
    @AppStorage(GridOSAppPreferences.showMenuBarExtraStorageKey)
    private var showMenuBarExtra = GridOSAppPreferences.defaultShowMenuBarExtra

    @AppStorage(GridOSAppPreferences.notificationsEnabledStorageKey)
    private var notificationsEnabled = GridOSAppPreferences.defaultNotificationsEnabled

    @AppStorage(GridOSAppPreferences.indexWorkspaceMetadataStorageKey)
    private var indexWorkspaceMetadata = GridOSAppPreferences.defaultIndexWorkspaceMetadata

    @State private var notificationAuthorizationState: NotificationAuthorizationState = .notDetermined
    @State private var isRequestingNotifications = false

    private let notificationClient: LocalNotificationClient

    init(notificationClient: LocalNotificationClient = LocalNotificationClient()) {
        self.notificationClient = notificationClient
    }

    var body: some View {
        Section("macOS Integrations") {
            Toggle("Show Menu Bar Extra", isOn: $showMenuBarExtra)
                .accessibilityLabel("Show Menu Bar Extra")
                .accessibilityValue(showMenuBarExtra ? "On" : "Off")

            Toggle("Notify when long-running work finishes", isOn: $notificationsEnabled)
                .accessibilityLabel("Notify when long-running work finishes")
                .accessibilityValue(notificationsEnabled ? "On" : "Off")
                .disabled(notificationAuthorizationState == .denied)

            VStack(alignment: .leading, spacing: 8) {
                Button("Enable Notifications") {
                    Task {
                        await enableNotifications()
                    }
                }
                .disabled(isRequestingNotifications)
                .accessibilityLabel("Enable Notifications")

                Text(notificationStatusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Toggle("Index saved workspace metadata", isOn: $indexWorkspaceMetadata)
                .accessibilityLabel("Index saved workspace metadata")
                .accessibilityValue(indexWorkspaceMetadata ? "On" : "Off")

            Text("Only saved workspace labels and directory names are indexed. Terminal output and command history are never indexed.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Manage Stored Secrets") {
                CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
            }
            .accessibilityLabel("Manage Stored Secrets")
        }
        .task {
            await refreshNotificationStatus()
        }
    }

    private var notificationStatusText: String {
        switch notificationAuthorizationState {
        case .authorized, .provisional, .ephemeral:
            return notificationsEnabled
                ? "Notifications are enabled for local gridOS alerts."
                : "Notifications are off. Terminal work continues normally."
        case .denied:
            return "Notifications are blocked in macOS Settings. Terminal work continues normally."
        case .notDetermined:
            return "Notifications are off. Terminal work continues normally."
        }
    }

    @MainActor
    private func refreshNotificationStatus() async {
        notificationAuthorizationState = await notificationClient.authorizationState()
        if notificationAuthorizationState == .denied {
            notificationsEnabled = false
        }
    }

    @MainActor
    private func enableNotifications() async {
        isRequestingNotifications = true
        defer { isRequestingNotifications = false }

        notificationAuthorizationState = await notificationClient.requestAuthorization()
        switch notificationAuthorizationState {
        case .authorized, .provisional, .ephemeral:
            notificationsEnabled = true
        case .denied, .notDetermined:
            notificationsEnabled = false
        }
    }
}
