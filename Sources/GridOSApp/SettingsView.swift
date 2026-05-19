import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Foundation") {
                Text("Settings surface reserved for Phase 1.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
    }
}
