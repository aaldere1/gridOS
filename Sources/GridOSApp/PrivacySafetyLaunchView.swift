import SwiftUI

struct PrivacySafetyLaunchView: View {
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

    private let guarantees = [
        PrivacySafetyGuarantee(
            symbol: "terminal",
            title: "Terminal stays yours",
            body: "Shell sessions, panes, and terminal output remain local to this Mac."
        ),
        PrivacySafetyGuarantee(
            symbol: "sparkles.rectangle.stack",
            title: "AI help is previewed",
            body: "Context is redacted and shown before any provider request leaves gridOS."
        ),
        PrivacySafetyGuarantee(
            symbol: "lock.shield",
            title: "Risk is classified locally",
            body: "Generated commands are inserted for review unless local policy allows a run."
        )
    ]

    private let facts = [
        "Provider keys are stored in Keychain.",
        "Notifications and indexing are off until enabled.",
        "Diagnostics are local, sanitized, and user-reviewed."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            identityPlate

            VStack(alignment: .leading, spacing: 8) {
                Text("Launch briefing")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.94))

                Text("gridOS is a local-first command surface. Review the operating defaults once, then get to work.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: 12) {
                ForEach(guarantees, id: \.title) { guarantee in
                    guaranteeCard(guarantee)
                }
            }
            .accessibilityElement(children: .contain)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(facts, id: \.self) { fact in
                    Label(fact, systemImage: "checkmark.shield")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .contain)

            HStack(alignment: .center, spacing: 12) {
                Button("Review Privacy Settings") {
                    onOpenPrivacySettings()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.white.opacity(0.74))

                Spacer(minLength: 18)

                Button("Enter gridOS") {
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .frame(width: 640)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.026, green: 0.032, blue: 0.040),
                        Color(red: 0.006, green: 0.008, blue: 0.012)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.15),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 520
                )
            }
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
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.94))
                    .textSelection(.enabled)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            Text("Generated on this Mac. Not tracked, uploaded, or shared.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.58))
        }
        .padding(18)
        .background(Color.white.opacity(0.050))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Local visual signature")
        .accessibilityValue("\(visualSignature), \(visualModeName)")
    }

    private func guaranteeCard(_ guarantee: PrivacySafetyGuarantee) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: guarantee.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.cyan.opacity(0.86))
                .frame(width: 28, height: 28, alignment: .leading)

            Text(guarantee.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.90))

            Text(guarantee.body)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.038))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.105), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct PrivacySafetyGuarantee {
    let symbol: String
    let title: String
    let body: String
}
