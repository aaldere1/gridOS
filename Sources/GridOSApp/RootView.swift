import Foundation
import GridOSKit
import RenderCore
import SwiftUI
import SystemMetrics
import TerminalCore

struct RootView: View {
    private let processConfiguration = TerminalSessionConfiguration.fromProcessArguments()
    private let visualIdentity = VisualIdentity.default
    private let metricsSampler: any SystemMetricsSampler = LiveSystemMetricsSampler()

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
    @State private var metricsSnapshot: SystemMetricsSnapshot = SystemMetricsPreviewData.snapshot

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
                        SystemStripView(snapshot: metricsSnapshot)
                        TerminalWorkspaceView(
                            configuration: terminalConfiguration,
                            onActivity: handleTerminalActivity
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    ActivityContextPanel(snapshot: metricsSnapshot)
                        .frame(width: 204)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(WindowFrameController(autosaveName: "gridOS.main"))
        .task {
            await runMetricsLoop()
        }
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

    private func runMetricsLoop() async {
        while !Task.isCancelled {
            let snapshot = await metricsSampler.snapshot(isActive: true)
            await MainActor.run {
                metricsSnapshot = snapshot
            }

            let refreshInterval = max(0.2, snapshot.samplingState.nextRefreshAfter)
            let nanoseconds = UInt64(refreshInterval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
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
            }
            .accessibilityLabel("Visual mode indicator")
            .accessibilityValue(visualModeName)

            Text("v\(version)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.56))
        }
        .padding(.leading, 72)
        .accessibilityElement(children: .combine)
    }
}

private struct SystemStripView: View {
    let snapshot: SystemMetricsSnapshot

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.cyan.opacity(0.72))
                .frame(width: 4, height: 16)
                .accessibilityHidden(true)

            MetricReadout(label: "CPU", value: cpuText)
            MetricDivider()
            MetricReadout(label: "MEM", value: memoryText)
            MetricDivider()
            MetricReadout(label: "NET", value: networkText)
            MetricDivider()
            MetricReadout(label: "BAT", value: batteryText)
            MetricDivider()
            MetricReadout(label: "THERM", value: thermalText)

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("System metrics")
        .accessibilityValue(accessibilitySummary)
    }

    private var cpuText: String {
        availabilityText(snapshot.cpu) { metrics in
            percentText(metrics.usagePercent)
        }
    }

    private var memoryText: String {
        availabilityText(snapshot.memory) { metrics in
            percentText(metrics.usagePercent)
        }
    }

    private var networkText: String {
        availabilityText(snapshot.network) { metrics in
            if metrics.stateText == "Network idle" {
                return "Network idle"
            }

            let totalBytesPerSecond = metrics.receivedBytesPerSecond + metrics.sentBytesPerSecond
            return "\(byteRateText(totalBytesPerSecond))/s"
        }
    }

    private var batteryText: String {
        switch snapshot.battery {
        case .available(let metrics), .stale(let metrics, _):
            if let level = metrics.levelPercent {
                return snapshot.battery.isStale ? "Stale \(percentText(level))" : percentText(level)
            }

            return snapshot.battery.isStale ? "Stale \(metrics.stateText)" : metrics.stateText
        case .unavailable(let reason):
            return reason.isEmpty ? "Battery unavailable" : reason
        }
    }

    private var thermalText: String {
        switch snapshot.thermal {
        case .available(let metrics), .stale(let metrics, _):
            return snapshot.thermal.isStale ? "Stale \(metrics.stateText)" : metrics.stateText
        case .unavailable(let reason):
            return reason.isEmpty ? "Thermal unavailable" : reason
        }
    }

    private var accessibilitySummary: String {
        [
            "CPU \(cpuText)",
            "MEM \(memoryText)",
            "NET \(networkText)",
            "BAT \(batteryText)",
            "THERM \(thermalText)"
        ].joined(separator: ", ")
    }
}

private struct ActivityContextPanel: View {
    let snapshot: SystemMetricsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Activity")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.74))

                if snapshot.topProcesses.isStale {
                    Text("Stale")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.52))
                }
            }

            Rectangle()
                .fill(.cyan.opacity(0.16))
                .frame(height: 1)
                .accessibilityHidden(true)

            topProcessContent

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(.black.opacity(0.24))
        .overlay {
            Rectangle()
                .stroke(.white.opacity(0.08), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Top processes")
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private var topProcessContent: some View {
        switch snapshot.topProcesses {
        case .available(let processes), .stale(let processes, _):
            if processes.isEmpty {
                unavailableText("No process data")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(processes.prefix(5)) { process in
                        TopProcessRow(process: process)
                    }
                }
            }
        case .unavailable(let reason):
            unavailableText(reason.isEmpty ? "No process data" : reason)
        }
    }

    private func unavailableText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(.white.opacity(0.58))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var accessibilityValue: String {
        switch snapshot.topProcesses {
        case .available(let processes), .stale(let processes, _):
            guard !processes.isEmpty else {
                return "No process data"
            }

            return processes.prefix(5).map { process in
                "\(process.name) \(percentText(process.cpuPercent)) CPU"
            }.joined(separator: ", ")
        case .unavailable(let reason):
            return reason.isEmpty ? "No process data" : reason
        }
    }
}

private struct MetricReadout: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.56))

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(value == "Stale" ? .white.opacity(0.62) : .white.opacity(0.84))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

private struct MetricDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.10))
            .frame(width: 1, height: 14)
            .accessibilityHidden(true)
    }
}

private struct TopProcessRow: View {
    let process: TopProcessMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(process.name)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 4)

                Text(percentText(process.cpuPercent))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.cyan.opacity(0.82))
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                Text("pid \(process.pid)")
                Text(byteCountText(process.residentMemoryBytes))
            }
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(.white.opacity(0.48))
            .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(process.name)
        .accessibilityValue("\(percentText(process.cpuPercent)) CPU, \(byteCountText(process.residentMemoryBytes)) memory")
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

private func availabilityText<Value: Equatable & Sendable>(
    _ availability: SystemMetricAvailability<Value>,
    availableText: (Value) -> String
) -> String {
    switch availability {
    case .available(let value):
        return availableText(value)
    case .stale(let value, _):
        return "Stale \(availableText(value))"
    case .unavailable(let reason):
        return reason
    }
}

private func percentText(_ percent: Double) -> String {
    "\(Int(percent.rounded()))%"
}

private func byteRateText(_ bytesPerSecond: Double) -> String {
    byteCountText(UInt64(max(0, bytesPerSecond)))
}

private func byteCountText(_ bytes: UInt64) -> String {
    let clampedBytes = min(bytes, UInt64(Int64.max))
    return ByteCountFormatter.string(
        fromByteCount: Int64(clampedBytes),
        countStyle: .memory
    )
}
