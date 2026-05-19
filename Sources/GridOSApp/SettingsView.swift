import SwiftUI
import TerminalCore

struct SettingsView: View {
    @State private var shellPath = TerminalSessionConfiguration.default.shellPath
    @State private var fontSize = TerminalSessionConfiguration.default.fontSize

    var body: some View {
        Form {
            Section("Terminal") {
                TextField("Shell", text: $shellPath)
                    .textFieldStyle(.roundedBorder)

                Stepper(value: $fontSize, in: 10...24, step: 1) {
                    Text("Font size: \(Int(fontSize))")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
    }
}
