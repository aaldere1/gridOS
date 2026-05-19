import GridOSKit
import SwiftUI
import TerminalCore

struct RootView: View {
    private let configuration = TerminalSessionConfiguration.fromProcessArguments()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.015, green: 0.018, blue: 0.024),
                    Color(red: 0.025, green: 0.040, blue: 0.045)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Text(GridOSProduct.name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(configuration.shellDisplayName)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.72))

                    Spacer()

                    Text("v\(GridOSProduct.version)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.56))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.08), in: Capsule())
                }

                TerminalSurface(configuration: configuration)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.cyan.opacity(0.18), lineWidth: 1)
                    }
            }
            .padding(18)
        }
    }
}

#Preview {
    RootView()
}
