import SwiftUI

struct BetaPrivacyDisclosureView: View {
    let visualSignature: String
    let visualModeName: String
    let onContinue: () -> Void
    let onOpenPrivacySettings: () -> Void

    init(
        visualSignature: String = "LOCAL",
        visualModeName: String = "Tron",
        onContinue: @escaping () -> Void,
        onOpenPrivacySettings: @escaping () -> Void
    ) {
        self.visualSignature = visualSignature
        self.visualModeName = visualModeName
        self.onContinue = onContinue
        self.onOpenPrivacySettings = onOpenPrivacySettings
    }

    private let facts = [
        "Terminal sessions stay local to this Mac.",
        "Command Intelligence is opt-in and sends context only after preview approval.",
        "API keys are stored in Keychain.",
        "Risky commands are inserted for review instead of run automatically.",
        "Notifications and workspace indexing are off until you enable them.",
        "Diagnostics are local, sanitized, and user-reviewed."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            identityPlate

            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy & Safety Defaults")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))

                Text("Review these defaults before using gridOS.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(facts, id: \.self) { fact in
                    Label(fact, systemImage: "checkmark.shield")
                        .labelStyle(.titleAndIcon)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.white.opacity(0.82))
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
        .padding(26)
        .frame(width: 560)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.030, green: 0.038, blue: 0.046),
                    Color(red: 0.010, green: 0.012, blue: 0.016)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.dark)
    }

    private var identityPlate: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("gridOS")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.cyan.opacity(0.88))

                Spacer()

                Text(visualModeName.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.52))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("LOCAL VISUAL SIGNATURE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.48))

                Text(visualSignature)
                    .font(.system(size: 34, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                    .textSelection(.enabled)
            }

            Text("Generated on this Mac. Not tracked, uploaded, or shared.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.58))
        }
        .padding(18)
        .background(Color.white.opacity(0.045))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Local visual signature")
        .accessibilityValue("\(visualSignature), \(visualModeName)")
    }
}
