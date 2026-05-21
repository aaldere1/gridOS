import AppKit
import CommandIntelligence
import Foundation
import GridOSKit
import RenderCore
import SwiftUI
import SystemMetrics
import TerminalCore

struct RootView: View {
    private let processConfiguration: TerminalSessionConfiguration
    private let metricsSampler: any SystemMetricsSampler
    private let snapshotStore: TerminalWorkspaceSnapshotStore
    private let workspaceSaveDelaySeconds = 0.5

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("terminal.shellPath") private var shellPath = GridOSAppPreferences.defaultShellPath
    @AppStorage("terminal.fontSize") private var terminalFontSize = GridOSAppPreferences.defaultTerminalFontSize
    @AppStorage("appearance.reducedMotion") private var reducedMotion = GridOSAppPreferences.defaultValue.reducedMotion
    @AppStorage("appearance.visualIntensity") private var visualIntensity = GridOSAppPreferences.defaultVisualIntensity
    @AppStorage(GridOSAppPreferences.visualModeStorageKey) private var visualModeRawValue = GridOSAppPreferences.defaultVisualModeRawValue
    @AppStorage(GridOSAppPreferences.installSeedStorageKey) private var installSeedRawValue = GridOSAppPreferences.defaultInstallSeedRawValue
    @AppStorage(GridOSAppPreferences.commandIntelligenceProviderStorageKey)
    private var commandIntelligenceProviderRawValue = GridOSAppPreferences.defaultCommandIntelligenceProviderID
    @AppStorage(GridOSAppPreferences.commandIntelligenceModelStorageKey)
    private var commandIntelligenceModelRawValue = GridOSAppPreferences.defaultCommandIntelligenceModelID

    @State private var renderSequence: UInt64 = 0
    @StateObject private var workspaceController: TerminalWorkspaceController
    @State private var isCommandPalettePresented = false
    @State private var renderEvent = RenderEvent(
        sequence: 0,
        kind: .startup,
        magnitude: 0.26
    )
    @State private var systemSnapshot: SystemMetricsSnapshot = SystemMetricsPreviewData.snapshot
    @State private var workspaceSaveTask: Task<Void, Never>?

    init(
        processConfiguration: TerminalSessionConfiguration = .fromProcessArguments(),
        metricsSampler: any SystemMetricsSampler = LiveSystemMetricsSampler(),
        snapshotStore: TerminalWorkspaceSnapshotStore = TerminalWorkspaceSnapshotStore()
    ) {
        self.processConfiguration = processConfiguration
        self.metricsSampler = metricsSampler
        self.snapshotStore = snapshotStore

        _workspaceController = StateObject(
            wrappedValue: TerminalWorkspaceController(
                state: Self.initialWorkspaceState(
                    fallbackConfiguration: processConfiguration,
                    snapshotStore: snapshotStore
                )
            )
        )
    }

    var body: some View {
        ZStack {
            MetalBackgroundView(
                identity: visualIdentity,
                event: renderEvent,
                effectConfiguration: effectConfiguration
            )
                .ignoresSafeArea()
                .accessibilityHidden(true)

            Color(visualTheme.palette.background)
                .opacity(max(0.12, visualTheme.panel.backgroundOpacity * 0.48))
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                AppFrameHeader(
                    productName: GridOSProduct.name,
                    shellDisplayName: terminalConfiguration.shellDisplayName,
                    visualModeName: visualIdentity.mode.displayName,
                    version: GridOSProduct.version,
                    reducedMotion: effectiveReducedMotion,
                    theme: visualTheme
                )

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 12) {
                        SystemStripView(snapshot: systemSnapshot, theme: visualTheme)
                        TerminalWorkspaceView(
                            workspaceController: workspaceController,
                            theme: visualTheme,
                            onActivity: { paneID, activity in
                                handleTerminalActivity(activity, from: paneID)
                            },
                            onWorkspaceChange: scheduleWorkspaceSave
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    ActivityContextPanel(snapshot: systemSnapshot, theme: visualTheme)
                        .frame(width: 204)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 18)

            if isCommandPalettePresented {
                Color.black
                    .opacity(0.34)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .onTapGesture {
                        dismissCommandPalette()
                    }

                // Phase 7 routes palette actions to the current active pane at action time.
                CommandPaletteView(
                    theme: visualTheme,
                    selectedTextProvider: {
                        workspaceController.selectedTextInActivePane()
                    },
                    workingDirectoryProvider: {
                        commandPaletteWorkingDirectory
                    },
                    onClose: dismissCommandPalette,
                    onOpenCommandIntelligenceSettings: openCommandIntelligenceSettingsFromPalette,
                    onInsertCommand: { command in
                        workspaceController.insertInActivePane(command)
                    },
                    onRunCommand: { command in
                        workspaceController.runInActivePane(command)
                    },
                    onSendRequest: { preview in
                        await completeCommandIntelligenceRequest(preview)
                    }
                )
                .padding(48)
                .transition(commandPaletteTransition)
            }
        }
        .background(WindowFrameController(autosaveName: "gridOS.main"))
        .onReceive(NotificationCenter.default.publisher(for: .gridOSCommandIntelligenceOpen)) { _ in
            isCommandPalettePresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridOSWorkspaceSessionReset)) { _ in
            workspaceSaveTask?.cancel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridOSMenuBarOpenGridOS)) { _ in
            DispatchQueue.main.async {
                workspaceController.focusActivePane()
            }
        }
        .onDisappear {
            saveWorkspaceNow()
            workspaceController.terminateAllPanes()
        }
        .task {
            ensureInstallSeed()
            #if DEBUG
            startPhase7SmokeIfNeeded()
            startPhase8SmokeIfNeeded()
            startPhase9SmokeIfNeeded()
            startPhase11SmokeIfNeeded()
            #endif
            await runMetricsLoop()
        }
    }

    private var visualMode: VisualMode {
        let normalizedRawValue = GridOSAppPreferences.normalizedVisualModeRawValue(visualModeRawValue)
        return VisualMode(rawValue: normalizedRawValue) ?? .defaultMode
    }

    private var visualTheme: VisualTheme {
        visualMode.theme
    }

    private var installSeed: String {
        GridOSAppPreferences.normalizedInstallSeedRawValue(installSeedRawValue)
    }

    private var visualIdentity: VisualIdentity {
        VisualIdentity(mode: visualMode, installSeed: installSeed.isEmpty ? "gridOS.phase5.bootstrap" : installSeed)
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

    private var commandPaletteWorkingDirectory: String? {
        let activePane = workspaceController.state.panesByID[workspaceController.activePaneID]
        return activePane?.lastWorkingDirectory ?? activePane?.configuration.workingDirectory ?? terminalConfiguration.workingDirectory
    }

    private var commandIntelligenceProviderID: LLMProviderID {
        #if DEBUG
        if isCommandIntelligenceSmokeFixtureEnabled {
            return .debugSmokeFixture
        }
        #endif

        return LLMProviderID(
            GridOSAppPreferences.normalizedCommandIntelligenceProviderID(commandIntelligenceProviderRawValue)
        )
    }

    private var commandIntelligenceModelID: LLMModelID {
        LLMModelID(
            GridOSAppPreferences.normalizedCommandIntelligenceModelID(commandIntelligenceModelRawValue)
        )
    }

    #if DEBUG
    private var isCommandIntelligenceSmokeFixtureEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("--command-intelligence-smoke-fixture")
    }
    #endif

    private var effectiveReducedMotion: Bool {
        accessibilityReduceMotion || preferences.reducedMotion
    }

    private var effectConfiguration: VisualEffectConfiguration {
        VisualEffectConfiguration(
            intensity: preferences.visualIntensity,
            reducedMotion: effectiveReducedMotion
        )
    }

    private var commandPaletteTransition: AnyTransition {
        if effectiveReducedMotion {
            return .opacity
        }

        return .opacity.combined(with: .scale(scale: 0.98))
    }

    @MainActor private func ensureInstallSeed() {
        guard GridOSAppPreferences.normalizedInstallSeedRawValue(installSeedRawValue).isEmpty else {
            return
        }

        installSeedRawValue = UUID().uuidString.lowercased()
    }

    @MainActor private func dismissCommandPalette() {
        isCommandPalettePresented = false
        workspaceController.focusActivePane()
    }

    @MainActor private func openCommandIntelligenceSettingsFromPalette() {
        CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
        openCommandIntelligenceSettingsWindow()
        DispatchQueue.main.async {
            CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
        }
        dismissCommandPalette()
    }

    @MainActor private func openCommandIntelligenceSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor private func completeCommandIntelligenceRequest(
        _ preview: CommandContextPreview
    ) async -> CommandIntelligenceServiceResult {
        let provider = commandIntelligenceProvider()
        let service = CommandIntelligenceService(
            credentialStore: KeychainCommandCredentialStore(),
            provider: provider,
            riskClassifier: CommandRiskClassifier()
        )

        return await service.completeApprovedRequest(
            preview: preview,
            providerID: commandIntelligenceProviderID,
            modelID: commandIntelligenceModelID
        )
    }

    private func commandIntelligenceProvider() -> any LLMCommandProvider {
        #if DEBUG
        if isCommandIntelligenceSmokeFixtureEnabled {
            return DebugCommandIntelligenceFixtureProvider()
        }
        #endif

        return AnthropicCommandProvider()
    }

    private func handleTerminalActivity(_ activity: TerminalActivityEvent, from paneID: TerminalPaneID) {
        workspaceController.handleActivity(activity, from: paneID)
        if case .workingDirectoryChanged = activity {
            scheduleWorkspaceSave()
        }

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
                systemSnapshot = snapshot
            }

            let refreshInterval = max(0.2, snapshot.samplingState.nextRefreshAfter)
            let nanoseconds = UInt64(refreshInterval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    }

    private static func initialWorkspaceState(
        fallbackConfiguration: TerminalSessionConfiguration,
        snapshotStore: TerminalWorkspaceSnapshotStore
    ) -> TerminalWorkspaceState {
        if let snapshot = try? snapshotStore.loadSnapshot(
            fallbackConfiguration: fallbackConfiguration,
            directoryExists: directoryExists
        ) {
            var state = TerminalWorkspaceState(
                snapshot: snapshot,
                fallbackConfiguration: fallbackConfiguration,
                directoryExists: directoryExists
            )
            if let recentDirectories = try? snapshotStore.loadRecentDirectories(), !recentDirectories.isEmpty {
                state.recentDirectories = recentDirectories
            }
            return state
        }

        var state = TerminalWorkspaceState(defaultConfiguration: fallbackConfiguration)
        if let recentDirectories = try? snapshotStore.loadRecentDirectories(), !recentDirectories.isEmpty {
            state.recentDirectories = recentDirectories
        }
        return state
    }

    private static func directoryExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    @MainActor private func scheduleWorkspaceSave() {
        workspaceSaveTask?.cancel()

        let snapshot = workspaceController.snapshot()
        let recentDirectories = workspaceController.state.recentDirectories
        let snapshotStore = snapshotStore
        let delayNanoseconds = UInt64(workspaceSaveDelaySeconds * 1_000_000_000)

        workspaceSaveTask = Task {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else {
                return
            }

            try? snapshotStore.saveSnapshot(snapshot)
            try? snapshotStore.saveRecentDirectories(recentDirectories)
        }
    }

    @MainActor private func saveWorkspaceNow() {
        workspaceSaveTask?.cancel()
        let snapshot = workspaceController.snapshot()
        let recentDirectories = workspaceController.state.recentDirectories
        try? snapshotStore.saveSnapshot(snapshot)
        try? snapshotStore.saveRecentDirectories(recentDirectories)
    }

    #if DEBUG
    @MainActor private func startPhase7SmokeIfNeeded() {
        Phase7MultiPaneSmokeCoordinator(
            workspaceController: workspaceController,
            saveWorkspace: saveWorkspaceNow
        )
        .startIfRequested()
    }

    @MainActor private func startPhase8SmokeIfNeeded() {
        Phase8MacIntegrationsSmokeCoordinator()
            .startIfRequested()
    }

    @MainActor private func startPhase9SmokeIfNeeded() {
        Phase9PerformanceSmokeCoordinator(
            workspaceController: workspaceController,
            renderPulse: {
                handleTerminalActivity(.output(byteCount: 4_096), from: workspaceController.activePaneID)
            }
        )
        .startIfRequested()
    }

    @MainActor private func startPhase11SmokeIfNeeded() {
        Phase11AlphaSmokeCoordinator(
            workspaceController: workspaceController,
            saveWorkspace: saveWorkspaceNow
        )
        .startIfRequested()
    }
    #endif
}

private struct AppFrameHeader: View {
    let productName: String
    let shellDisplayName: String
    let visualModeName: String
    let version: String
    let reducedMotion: Bool
    let theme: VisualTheme

    var body: some View {
        HStack(spacing: 12) {
            Text(productName)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.92))

            Text(shellDisplayName)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.78))

            Spacer(minLength: 16)

            HStack(spacing: 8) {
                Circle()
                    .fill(
                        Color(reducedMotion ? theme.palette.secondaryAccent : theme.palette.statusAccent)
                            .opacity(reducedMotion ? 0.56 : 0.82)
                    )
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)

                Text(visualModeName)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.68))
            }
            .accessibilityLabel("Visual mode indicator")
            .accessibilityValue(visualModeName)

            Text("v\(version)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.56))
        }
        .padding(.leading, 72)
        .accessibilityElement(children: .combine)
    }
}

private struct SystemStripView: View {
    let snapshot: SystemMetricsSnapshot
    let theme: VisualTheme

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(theme.palette.statusAccent).opacity(0.76))
                .frame(width: 4, height: 16)
                .accessibilityHidden(true)

            MetricReadout(label: "CPU", value: cpuText, theme: theme)
            MetricDivider(theme: theme)
            MetricReadout(label: "MEM", value: memoryText, theme: theme)
            MetricDivider(theme: theme)
            MetricReadout(label: "NET", value: networkText, theme: theme)
            MetricDivider(theme: theme)
            MetricReadout(label: "BAT", value: batteryText, theme: theme)
            MetricDivider(theme: theme)
            MetricReadout(label: "THERM", value: thermalText, theme: theme)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(theme.palette.background).opacity(theme.panel.backgroundOpacity))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))
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
    let theme: VisualTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Activity")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.74))

                if snapshot.topProcesses.isStale {
                    Text("Stale")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.58))
                }
            }

            Rectangle()
                .fill(Color(theme.palette.statusAccent).opacity(theme.panel.separatorOpacity))
                .frame(height: 1)
                .accessibilityHidden(true)

            topProcessContent

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(Color(theme.palette.background).opacity(theme.panel.backgroundOpacity))
        .overlay {
            RoundedRectangle(cornerRadius: theme.panel.cornerRadius, style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(theme.panel.borderOpacity), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.panel.cornerRadius, style: .continuous))
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
                        TopProcessRow(process: process, theme: theme)
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
            .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.58))
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
    let theme: VisualTheme

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.56))

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(value == "Stale" ? 0.62 : 0.84))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

private struct MetricDivider: View {
    let theme: VisualTheme

    var body: some View {
        Rectangle()
            .fill(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))
            .frame(width: 1, height: 14)
            .accessibilityHidden(true)
    }
}

private struct TopProcessRow: View {
    let process: TopProcessMetrics
    let theme: VisualTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(process.name)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.78))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 4)

                Text(percentText(process.cpuPercent))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.82))
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                Text("pid \(process.pid)")
                Text(byteCountText(process.residentMemoryBytes))
            }
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.56))
            .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(process.name)
        .accessibilityValue("\(percentText(process.cpuPercent)) CPU, \(byteCountText(process.residentMemoryBytes)) memory")
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

// SwiftUI bridge for Color(_ visualColor: VisualColor) token use in this file.
private extension Color {
    init(_ visualColor: VisualColor) {
        self.init(
            red: visualColor.red,
            green: visualColor.green,
            blue: visualColor.blue,
            opacity: visualColor.alpha
        )
    }
}

extension Notification.Name {
    static let gridOSWorkspaceSessionReset = Notification.Name("gridOS.workspaceSession.reset")
}
