import GridOSKit
import SwiftUI

struct MacIntegrationsSettingsView: View {
    @AppStorage(GridOSAppPreferences.showMenuBarExtraStorageKey)
    private var showMenuBarExtra = GridOSAppPreferences.defaultShowMenuBarExtra

    @AppStorage(GridOSAppPreferences.notificationsEnabledStorageKey)
    private var notificationsEnabled = GridOSAppPreferences.defaultNotificationsEnabled

    @AppStorage(GridOSAppPreferences.indexWorkspaceMetadataStorageKey)
    private var indexWorkspaceMetadata = GridOSAppPreferences.defaultIndexWorkspaceMetadata

    @State private var notificationStatus = "Notifications are off. Terminal work continues normally."

    var body: some View {
        Section("macOS Integrations") {
            Toggle("Show Menu Bar Extra", isOn: $showMenuBarExtra)
                .accessibilityLabel("Show Menu Bar Extra")
                .accessibilityValue(showMenuBarExtra ? "On" : "Off")

            Toggle("Notify when long-running work finishes", isOn: $notificationsEnabled)
                .accessibilityLabel("Notify when long-running work finishes")
                .accessibilityValue(notificationsEnabled ? "On" : "Off")

            VStack(alignment: .leading, spacing: 8) {
                Button("Enable Notifications") {
                    notificationStatus = "Notifications are off. Terminal work continues normally."
                }
                .accessibilityLabel("Enable Notifications")

                Text(notificationStatus)
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
    }
}
