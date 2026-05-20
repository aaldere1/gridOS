import GridOSKit
import RenderCore
import SwiftUI
import TerminalCore

struct RootView: View {
    private let configuration = TerminalSessionConfiguration.fromProcessArguments()
    private let visualIdentity = VisualIdentity.default

    @State private var renderSequence: UInt64 = 0
    @State private var renderEvent = RenderEvent(
        sequence: 0,
        kind: .startup,
        magnitude: 0.26
    )

    var body: some View {
        ZStack {
            MetalBackgroundView(identity: visualIdentity, event: renderEvent)
                .ignoresSafeArea()

            Color.black.opacity(0.18)
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

                    HStack(spacing: 8) {
                        Circle()
                            .fill(.cyan.opacity(0.72))
                            .frame(width: 7, height: 7)

                        Text(visualIdentity.mode.displayName)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Text("v\(GridOSProduct.version)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.56))
                }

                TerminalSurface(configuration: configuration, onActivity: handleTerminalActivity)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.cyan.opacity(0.18), lineWidth: 1)
                    }
            }
            .padding(18)
        }
    }

    private func handleTerminalActivity(_ activity: TerminalActivityEvent) {
        guard let parameters = renderEventParameters(for: activity) else {
            return
        }

        renderSequence &+= 1
        renderEvent = RenderEvent(
            sequence: renderSequence,
            kind: parameters.kind,
            magnitude: parameters.magnitude
        )
    }

    private func renderEventParameters(for activity: TerminalActivityEvent) -> (kind: RenderEventKind, magnitude: Double)? {
        switch activity {
        case .input(let byteCount):
            return (.terminalInput, max(0.16, min(1, Double(byteCount) / 96)))
        case .output(let byteCount):
            return (.terminalOutput, max(0.10, min(1, Double(byteCount) / 8_192)))
        case .resized:
            return (.terminalResize, 0.34)
        case .processStarted, .processTerminated:
            return (.processLifecycle, 0.44)
        case .titleChanged, .workingDirectoryChanged:
            return nil
        }
    }
}

#Preview {
    RootView()
}
