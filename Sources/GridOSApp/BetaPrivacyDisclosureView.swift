import SwiftUI

struct BetaPrivacyDisclosureView: View {
    let onContinue: () -> Void
    let onOpenPrivacySettings: () -> Void

    private let facts = [
        "Terminal sessions stay local to this Mac.",
        "Command Intelligence is opt-in and sends context only after preview approval.",
        "API keys are stored in Keychain.",
        "Risky commands are inserted for review instead of run automatically.",
        "Notifications and workspace indexing are off until you enable them.",
        "Diagnostics are local, sanitized, and user-reviewed."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Beta Privacy")
                    .font(.title2.weight(.semibold))

                Text("Review these defaults before using this Beta build.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(facts, id: \.self) { fact in
                    Label(fact, systemImage: "checkmark.shield")
                        .labelStyle(.titleAndIcon)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .contain)

            HStack {
                Button("Open Privacy Settings") {
                    onOpenPrivacySettings()
                }

                Spacer()

                Button("Continue") {
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
