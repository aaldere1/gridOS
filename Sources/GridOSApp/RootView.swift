import CommandIntelligence
import GridOSKit
import RenderCore
import SwiftUI
import SystemMetrics
import TerminalCore

struct RootView: View {
    private let modules = [
        TerminalCoreStatus.module,
        RenderCoreStatus.module,
        SystemMetricsStatus.module,
        CommandIntelligenceStatus.module
    ]

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

            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(GridOSProduct.name)
                            .font(.system(size: 56, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Foundation online")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.78))
                    }

                    Spacer()

                    Text("v\(GridOSProduct.version)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.56))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.08), in: Capsule())
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(modules) { module in
                        ModuleStatusRow(module: module)
                    }
                }

                Spacer()

                Text(GridOSProduct.productionPromise)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .padding(44)
        }
    }
}

private struct ModuleStatusRow: View {
    let module: FoundationModuleStatus

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: module.state.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(module.state.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(module.title)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))

                Text(module.detail)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(1)
            }

            Spacer()

            Text(module.state.rawValue.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(module.state.tint)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private extension FoundationModuleStatus.State {
    var symbolName: String {
        switch self {
        case .scaffolded:
            "checkmark.seal"
        case .pending:
            "circle.dashed"
        }
    }

    var tint: Color {
        switch self {
        case .scaffolded:
            .cyan
        case .pending:
            .white.opacity(0.42)
        }
    }
}

#Preview {
    RootView()
}
