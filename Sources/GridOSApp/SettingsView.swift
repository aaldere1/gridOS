import CommandIntelligence
import GridOSKit
import RenderCore
import SwiftUI

struct SettingsView: View {
    @AppStorage("terminal.shellPath") private var shellPath = GridOSAppPreferences.defaultShellPath
    @AppStorage("terminal.fontSize") private var terminalFontSize = GridOSAppPreferences.defaultTerminalFontSize
    @AppStorage("appearance.reducedMotion") private var reducedMotion = GridOSAppPreferences.defaultValue.reducedMotion
    @AppStorage("appearance.visualIntensity") private var visualIntensity = GridOSAppPreferences.defaultVisualIntensity
    @AppStorage(GridOSAppPreferences.visualModeStorageKey) private var visualModeRawValue = GridOSAppPreferences.defaultVisualModeRawValue

    @State private var commandIntelligenceSettingsHighlighted = false
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

                Section("Recovery") {
                    Text("Running shell processes are not restored after relaunch.")
                        .foregroundStyle(.secondary)

                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .accessibilityLabel("Reset to Defaults")
                    .accessibilityValue("Restores shell, font size, visual mode, reduced motion, and visual intensity")
                }
            }
            .formStyle(.grouped)
            .frame(width: 420)
            .padding()
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gridOS.commandIntelligence.openSettings"))) { _ in
                focusCommandIntelligenceSettings(proxy)
            }
        }
    }

    private var visualModeDisplayName: String {
        let normalizedRawValue = GridOSAppPreferences.normalizedVisualModeRawValue(visualModeRawValue)
        return VisualMode(rawValue: normalizedRawValue)?.displayName ?? VisualMode.defaultMode.displayName
    }

    private func resetToDefaults() {
        let defaults = GridOSAppPreferences.defaultValue
        shellPath = defaults.shellPath
        terminalFontSize = defaults.terminalFontSize
        visualModeRawValue = GridOSAppPreferences.defaultVisualModeRawValue
        reducedMotion = defaults.reducedMotion
        visualIntensity = defaults.visualIntensity
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
