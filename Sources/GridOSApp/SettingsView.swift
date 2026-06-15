import CommandIntelligence
import GridOSKit
import RenderCore
import SwiftUI
import TerminalCore

struct SettingsView: View {
    @AppStorage("terminal.shellPath") private var shellPath = GridOSAppPreferences.defaultShellPath
    @AppStorage("terminal.fontSize") private var terminalFontSize = GridOSAppPreferences.defaultTerminalFontSize
    @AppStorage("appearance.reducedMotion") private var reducedMotion = GridOSAppPreferences.defaultValue.reducedMotion
    @AppStorage("appearance.visualIntensity") private var visualIntensity = GridOSAppPreferences.defaultVisualIntensity
    @AppStorage(GridOSAppPreferences.visualModeStorageKey) private var visualModeRawValue = GridOSAppPreferences.defaultVisualModeRawValue
    @AppStorage(GridOSAppPreferences.installSeedStorageKey) private var installSeedRawValue = GridOSAppPreferences.defaultInstallSeedRawValue
    @AppStorage(GridOSAppPreferences.showMenuBarExtraStorageKey)
    private var showMenuBarExtra = GridOSAppPreferences.defaultShowMenuBarExtra
    @AppStorage(GridOSAppPreferences.notificationsEnabledStorageKey)
    private var notificationsEnabled = GridOSAppPreferences.defaultNotificationsEnabled
    @AppStorage(GridOSAppPreferences.indexWorkspaceMetadataStorageKey)
    private var indexWorkspaceMetadata = GridOSAppPreferences.defaultIndexWorkspaceMetadata
    @AppStorage(GridOSAppPreferences.privacySafetyLaunchAcceptedStorageKey)
    private var privacySafetyLaunchAccepted = GridOSAppPreferences.defaultPrivacySafetyLaunchAccepted

    @State private var commandIntelligenceSettingsHighlighted = false
    @State private var isPrivacySafetyLaunchPresented = false
    @FocusState private var commandIntelligenceSettingsFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                Section("Terminal") {
                    TextField("Shell", text: $shellPath)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Shell")
                        .accessibilityValue(shellPath)

                    Stepper(
                        value: $terminalFontSize,
                        in: GridOSAppPreferences.fontSizeRange,
                        step: 1
                    ) {
                        Text("Font size: \(Int(terminalFontSize))")
                    }
                    .accessibilityLabel("Font size")
                    .accessibilityValue("\(Int(terminalFontSize)) points")
                }

                Section("Appearance") {
                    Picker("Visual mode", selection: $visualModeRawValue) {
                        ForEach(VisualMode.allCases) { mode in
                            Text(mode.displayName)
                                .tag(mode.rawValue)
                        }
                    }
                    .accessibilityLabel("Visual mode")
                    .accessibilityValue(visualModeDisplayName)

                    Toggle("Reduce motion", isOn: $reducedMotion)
                        .accessibilityLabel("Reduce motion")
                        .accessibilityValue(reducedMotion ? "On" : "Off")

                    Slider(
                        value: $visualIntensity,
                        in: GridOSAppPreferences.visualIntensityRange
                    ) {
                        Text("Visual intensity")
                    }
                    .accessibilityLabel("Visual intensity")
                    .accessibilityValue("\(Int(visualIntensity * 100)) percent")
                }

                MacIntegrationsSettingsView()

                SoftwareUpdateSettingsView()

                CommandIntelligenceSettingsView()
                    .id("command-intelligence-settings")
                    .accessibilityIdentifier("command-intelligence-settings")
                    .focusable()
                    .focused($commandIntelligenceSettingsFocused)
                    .overlay {
                        if commandIntelligenceSettingsHighlighted {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.accentColor.opacity(0.62), lineWidth: 2)
                                .accessibilityHidden(true)
                        }
                    }

                Section("Privacy & Safety") {
                    Text("Terminal sessions stay local to this Mac.")
                        .foregroundStyle(.secondary)

                    Text("AI Command Helper is opt-in and sends context only after preview approval.")
                        .foregroundStyle(.secondary)

                    Text("API keys are stored in Keychain.")
                        .foregroundStyle(.secondary)

                    Text("Risky commands are inserted for review instead of run automatically.")
                        .foregroundStyle(.secondary)

                    Text("Notifications and workspace indexing are off until you enable them.")
                        .foregroundStyle(.secondary)

                    Text("Diagnostics are local, sanitized, and user-reviewed.")
                        .foregroundStyle(.secondary)

                    Text("Support: operations@cineconcerts.com")
                        .foregroundStyle(.secondary)

                    Text("Feedback is reviewed by support before any diagnostic detail is shared.")
                        .foregroundStyle(.secondary)

                    Button("Review Privacy Defaults") {
                        isPrivacySafetyLaunchPresented = true
                    }
                    .accessibilityLabel("Review Privacy Defaults")
                    .accessibilityValue(privacySafetyLaunchAccepted ? "Reviewed" : "Not reviewed")
                }

                Section("Recovery") {
                    Text("Pane layout and directories are restored on relaunch.")
                        .foregroundStyle(.secondary)

                    Text("Running shell processes are not restored after relaunch.")
                        .foregroundStyle(.secondary)

                    Text("Directory unavailable. Starting in your default directory.")
                        .foregroundStyle(.secondary)

                    Button("Reset Saved Session") {
                        resetSavedSession()
                    }
                    .accessibilityLabel("Reset Saved Session")
                    .accessibilityValue("Deletes saved pane layout and recent directory files")

                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .accessibilityLabel("Reset to Defaults")
                    .accessibilityValue("Restores shell, font size, visual mode, reduced motion, and visual intensity")
                }
            }
            .formStyle(.grouped)
            .frame(
                minWidth: 560,
                idealWidth: 660,
                maxWidth: .infinity,
                minHeight: 560,
                idealHeight: 720,
                maxHeight: .infinity
            )
            .padding()
            .background(SettingsWindowConfigurator())
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gridOS.commandIntelligence.openSettings"))) { _ in
                focusCommandIntelligenceSettings(proxy)
            }
            .sheet(isPresented: $isPrivacySafetyLaunchPresented) {
                PrivacySafetyLaunchView(
                    visualSignature: visualIdentity.displaySignature,
                    visualModeName: visualIdentity.mode.displayName,
                    onContinue: {
                        privacySafetyLaunchAccepted = true
                        isPrivacySafetyLaunchPresented = false
                    },
                    onOpenPrivacySettings: {
                        privacySafetyLaunchAccepted = true
                        isPrivacySafetyLaunchPresented = false
                    }
                )
            }
        }
    }

    private var visualModeDisplayName: String {
        let normalizedRawValue = GridOSAppPreferences.normalizedVisualModeRawValue(visualModeRawValue)
        return VisualMode(rawValue: normalizedRawValue)?.displayName ?? VisualMode.defaultMode.displayName
    }

    private var visualIdentity: VisualIdentity {
        let normalizedMode = GridOSAppPreferences.normalizedVisualModeRawValue(visualModeRawValue)
        let mode = VisualMode(rawValue: normalizedMode) ?? .defaultMode
        let installSeed = GridOSAppPreferences.normalizedInstallSeedRawValue(installSeedRawValue)
        return VisualIdentity(mode: mode, installSeed: installSeed.isEmpty ? "gridOS.settings.bootstrap" : installSeed)
    }

    private func resetToDefaults() {
        let defaults = GridOSAppPreferences.defaultValue
        shellPath = defaults.shellPath
        terminalFontSize = defaults.terminalFontSize
        visualModeRawValue = GridOSAppPreferences.defaultVisualModeRawValue
        reducedMotion = defaults.reducedMotion
        visualIntensity = defaults.visualIntensity
        showMenuBarExtra = GridOSAppPreferences.defaultShowMenuBarExtra
        notificationsEnabled = GridOSAppPreferences.defaultNotificationsEnabled
        indexWorkspaceMetadata = GridOSAppPreferences.defaultIndexWorkspaceMetadata
        privacySafetyLaunchAccepted = GridOSAppPreferences.defaultPrivacySafetyLaunchAccepted
    }

    private func resetSavedSession() {
        try? TerminalWorkspaceSnapshotStore().deleteStoredSession()
        NotificationCenter.default.post(name: .gridOSWorkspaceSessionReset, object: nil)
    }

    private func focusCommandIntelligenceSettings(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.18)) {
            proxy.scrollTo("command-intelligence-settings", anchor: .center)
            commandIntelligenceSettingsHighlighted = true
        }

        commandIntelligenceSettingsFocused = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            commandIntelligenceSettingsHighlighted = false
        }
    }
}
