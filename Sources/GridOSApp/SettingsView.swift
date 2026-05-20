import GridOSKit
import SwiftUI

struct SettingsView: View {
    @AppStorage("terminal.shellPath") private var shellPath = GridOSAppPreferences.defaultShellPath
    @AppStorage("terminal.fontSize") private var terminalFontSize = GridOSAppPreferences.defaultTerminalFontSize
    @AppStorage("appearance.reducedMotion") private var reducedMotion = GridOSAppPreferences.defaultValue.reducedMotion
    @AppStorage("appearance.visualIntensity") private var visualIntensity = GridOSAppPreferences.defaultVisualIntensity

    var body: some View {
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

            Section("Recovery") {
                Text("Running shell processes are not restored after relaunch.")
                    .foregroundStyle(.secondary)

                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .accessibilityLabel("Reset to Defaults")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
    }

    private func resetToDefaults() {
        let defaults = GridOSAppPreferences.defaultValue
        shellPath = defaults.shellPath
        terminalFontSize = defaults.terminalFontSize
        reducedMotion = defaults.reducedMotion
        visualIntensity = defaults.visualIntensity
    }
}
