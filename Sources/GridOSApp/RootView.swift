import GridOSKit
import RenderCore
import SwiftUI
import TerminalCore

struct RootView: View {
    private let processConfiguration = TerminalSessionConfiguration.fromProcessArguments()
    private let visualIdentity = VisualIdentity.default

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("terminal.shellPath") private var shellPath = GridOSAppPreferences.defaultShellPath
    @AppStorage("terminal.fontSize") private var terminalFontSize = GridOSAppPreferences.defaultTerminalFontSize
    @AppStorage("appearance.reducedMotion") private var reducedMotion = GridOSAppPreferences.defaultValue.reducedMotion
    @AppStorage("appearance.visualIntensity") private var visualIntensity = GridOSAppPreferences.defaultVisualIntensity

    @State private var renderSequence: UInt64 = 0
    @State private var renderEvent = RenderEvent(
        sequence: 0,
        kind: .startup,
        magnitude: 0.26
    )

    var body: some View {
        ZStack {
            MetalBackgroundView(
                identity: visualIdentity,
                event: renderEvent,
                effectConfiguration: effectConfiguration
            )
                .ignoresSafeArea()
                .accessibilityHidden(true)

            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                AppFrameHeader(
                    productName: GridOSProduct.name,
                    shellDisplayName: terminalConfiguration.shellDisplayName,
                    visualModeName: visualIdentity.mode.displayName,
                    version: GridOSProduct.version,
                    reducedMotion: effectiveReducedMotion
                )

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 12) {
                        SystemStripView()
                        TerminalWorkspaceView(
                            configuration: terminalConfiguration,
                            onActivity: handleTerminalActivity
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    ActivityContextPanel()
                        .frame(width: 184)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(WindowFrameController(autosaveName: "gridOS.main"))
    }

    private var preferences: GridOSAppPreferences {
        GridOSAppPreferences(
            shellPath: shellPath,
            terminalFontSize: terminalFontSize,
            visualIntensity: visualIntensity,
            reducedMotion: reducedMotion
        )
    }

    private var terminalConfiguration: TerminalSessionConfiguration {
        let baseConfiguration = processConfiguration
        let appPreferences = preferences

        return TerminalSessionConfiguration(
            shellPath: appPreferences.shellPath,
            shellArguments: baseConfiguration.shellArguments,
            workingDirectory: baseConfiguration.workingDirectory,
            fontName: baseConfiguration.fontName,
            fontSize: appPreferences.terminalFontSize,
            startupCommand: baseConfiguration.startupCommand
        )
    }

    private var effectiveReducedMotion: Bool {
        accessibilityReduceMotion || preferences.reducedMotion
    }

    private var effectConfiguration: VisualEffectConfiguration {
        VisualEffectConfiguration(
            intensity: preferences.visualIntensity,
            reducedMotion: effectiveReducedMotion
        )
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

private struct AppFrameHeader: View {
    let productName: String
    let shellDisplayName: String
    let visualModeName: String
    let version: String
    let reducedMotion: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(productName)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text(shellDisplayName)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.cyan.opacity(0.72))

            Spacer(minLength: 16)

            HStack(spacing: 8) {
                Circle()
                    .fill(reducedMotion ? .white.opacity(0.42) : .cyan.opacity(0.72))
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)

                Text(visualModeName)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.62))
                    .accessibilityLabel("Visual mode")
                    .accessibilityValue(visualModeName)
            }

            Text("v\(version)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.56))
        }
        .padding(.leading, 72)
        .accessibilityElement(children: .combine)
    }
}

private struct SystemStripView: View {
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.cyan.opacity(0.72))
                .frame(width: 4, height: 16)
                .accessibilityHidden(true)

            Text("Systems ready")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.72))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.28))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("System strip")
        .accessibilityValue("Systems ready")
    }
}

private struct ActivityContextPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.74))

            Rectangle()
                .fill(.cyan.opacity(0.16))
                .frame(height: 1)
                .accessibilityHidden(true)

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(.black.opacity(0.24))
        .overlay {
            Rectangle()
                .stroke(.white.opacity(0.08), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Activity panel")
        .accessibilityValue("Activity")
    }
}

private struct TerminalWorkspaceView: View {
    let configuration: TerminalSessionConfiguration
    let onActivity: TerminalSurface.ActivityHandler

    var body: some View {
        TerminalSurface(configuration: configuration, onActivity: onActivity)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.cyan.opacity(0.18), lineWidth: 1)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Terminal workspace")
    }
}

#Preview {
    RootView()
}
