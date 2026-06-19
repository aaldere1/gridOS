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
    @AppStorage(GridOSAppPreferences.privacySafetyLaunchAcceptedStorageKey)
    private var privacySafetyLaunchAccepted = GridOSAppPreferences.defaultPrivacySafetyLaunchAccepted

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
    @State private var commandPaletteProviderStatusTask: Task<Void, Never>?
    @State private var commandPaletteProviderStatus: CommandPaletteProviderStatus = .unknown
    @ObservedObject private var softwareUpdateController = SoftwareUpdateController.shared

    init(
        processConfiguration: TerminalSessionConfiguration = Self.defaultProcessConfiguration,
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

    private static var defaultProcessConfiguration: TerminalSessionConfiguration {
        #if DEBUG
        return .fromProcessArguments(allowsStartupCommand: true)
        #else
        return .fromProcessArguments()
        #endif
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
                    visualSignature: visualIdentity.displaySignature,
                    version: GridOSProduct.version,
                    reducedMotion: effectiveReducedMotion,
                    theme: visualTheme,
                    availableUpdate: softwareUpdateController.availability.availableUpdate,
                    canCheckForUpdates: softwareUpdateController.canCheckForUpdates,
                    onShowUpdate: softwareUpdateController.checkForUpdates,
                    onCycleVisualMode: cycleVisualMode
                )

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 12) {
                        SystemStripView(snapshot: systemSnapshot, theme: visualTheme)
                        TerminalWorkspaceView(
                            workspaceController: workspaceController,
                            theme: visualTheme,
                            terminalFontSize: terminalFontSize,
                            canDecreaseFontSize: terminalFontSize > GridOSAppPreferences.fontSizeRange.lowerBound,
                            canIncreaseFontSize: terminalFontSize < GridOSAppPreferences.fontSizeRange.upperBound,
                            onActivity: { paneID, activity in
                                handleTerminalActivity(activity, from: paneID)
                            },
                            onWorkspaceChange: scheduleWorkspaceSave,
                            onDecreaseFontSize: decreaseTerminalFontSize,
                            onIncreaseFontSize: increaseTerminalFontSize,
                            onResetFontSize: resetTerminalFontSize
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    ActivityContextPanel(
                        snapshot: systemSnapshot,
                        visualSignature: visualIdentity.displaySignature,
                        visualModeName: visualIdentity.mode.displayName,
                        theme: visualTheme
                    )
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
                    },
                    providerStatus: commandPaletteProviderStatus
                )
                .padding(48)
                .transition(commandPaletteTransition)
            }
        }
        .background(
            WindowFrameController(autosaveName: "gridOS.main") { _ in
                confirmTerminatingRunningShells()
            }
        )
        .sheet(isPresented: privacySafetyLaunchPresented) {
            PrivacySafetyLaunchView(
                visualSignature: visualIdentity.displaySignature,
                visualModeName: visualIdentity.mode.displayName,
                onContinue: {
                    privacySafetyLaunchAccepted = true
                },
                onOpenPrivacySettings: {
                    openSettingsWindow()
                }
            )
            .interactiveDismissDisabled(true)
        }
        .onAppear {
            ensureInstallSeed()
            applyTerminalFontSizePreference(terminalFontSize)
            AppTerminationGuard.shared.shouldTerminateHandler = {
                confirmTerminatingRunningShells()
            }
        }
        .onChange(of: terminalFontSize) { _, newValue in
            applyTerminalFontSizePreference(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridOSCommandIntelligenceOpen)) { _ in
            isCommandPalettePresented = true
            refreshCommandPaletteProviderStatus()
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
            AppTerminationGuard.shared.shouldTerminateHandler = nil
            commandPaletteProviderStatusTask?.cancel()
            commandPaletteProviderStatusTask = nil
            saveWorkspaceNow()
            workspaceController.terminateAllPanes()
        }
        .task {
            ensureInstallSeed()
            softwareUpdateController.refreshAvailabilityIfNeeded()
            #if DEBUG
            startPhase7SmokeIfNeeded()
            startPhase8SmokeIfNeeded()
            startPhase9SmokeIfNeeded()
            startPhase11SmokeIfNeeded()
            startCommandPaletteSmokeIfNeeded()
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
            reducedMotion: reducedMotion,
            privacySafetyLaunchAccepted: privacySafetyLaunchAccepted
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
            GridOSAppPreferences.normalizedCommandIntelligenceModelID(
                commandIntelligenceModelRawValue,
                providerID: commandIntelligenceProviderID.rawValue
            )
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

    private var privacySafetyLaunchPresented: Binding<Bool> {
        Binding(
            get: {
                !privacySafetyLaunchAccepted
            },
            set: { _ in }
        )
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
        SettingsWindowController.shared.open(focusCommandIntelligence: true)
        dismissCommandPalette()
    }

    @MainActor private func openSettingsWindow() {
        SettingsWindowController.shared.open()
    }

    @MainActor private func cycleVisualMode() {
        visualModeRawValue = GridOSAppPreferences.nextVisualModeRawValue(after: visualModeRawValue)
    }

    @MainActor private func decreaseTerminalFontSize() {
        terminalFontSize = GridOSAppPreferences.clampedFontSize(terminalFontSize - 1)
    }

    @MainActor private func increaseTerminalFontSize() {
        terminalFontSize = GridOSAppPreferences.clampedFontSize(terminalFontSize + 1)
    }

    @MainActor private func resetTerminalFontSize() {
        terminalFontSize = GridOSAppPreferences.defaultTerminalFontSize
    }

    @MainActor private func applyTerminalFontSizePreference(_ fontSize: Double) {
        let clampedFontSize = GridOSAppPreferences.clampedFontSize(fontSize)
        if terminalFontSize != clampedFontSize {
            terminalFontSize = clampedFontSize
        }

        workspaceController.updateTerminalFontSize(clampedFontSize)
        scheduleWorkspaceSave()
    }

    @MainActor private func confirmTerminatingRunningShells() -> Bool {
        guard workspaceController.hasRunningProcesses() else {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Terminate open shell sessions?"
        alert.informativeText = "gridOS still has terminal panes with running shell processes. Closing now will stop those sessions, including editors, SSH, package installs, or local servers."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Terminate Sessions")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
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

    @MainActor private func refreshCommandPaletteProviderStatus() {
        let providerID = commandIntelligenceProviderID
        let providerName = CommandIntelligenceModelCatalog.descriptor(for: providerID).displayName

        commandPaletteProviderStatusTask?.cancel()
        commandPaletteProviderStatusTask = Task { @MainActor in
            do {
                let hasKey = try await KeychainCommandCredentialStore().apiKey(for: providerID) != nil
                guard !Task.isCancelled, providerID == commandIntelligenceProviderID else {
                    return
                }

                commandPaletteProviderStatus = hasKey ? .configured : .missing(providerName: providerName)
            } catch {
                guard !Task.isCancelled, providerID == commandIntelligenceProviderID else {
                    return
                }

                commandPaletteProviderStatus = .unknown
            }

            commandPaletteProviderStatusTask = nil
        }
    }

    private func commandIntelligenceProvider() -> any LLMCommandProvider {
        #if DEBUG
        if isCommandIntelligenceSmokeFixtureEnabled {
            return DebugCommandIntelligenceFixtureProvider()
        }
        #endif

        switch commandIntelligenceProviderID {
        case .openAI:
            return OpenAICommandProvider()
        case .deepSeek:
            return DeepSeekCommandProvider()
        case .xAI:
            return XAICommandProvider()
        default:
            return AnthropicCommandProvider()
        }
    }

    private func handleTerminalActivity(_ activity: TerminalActivityEvent, from paneID: TerminalPaneID) {
        workspaceController.handleActivity(activity, from: paneID)

        switch activity {
        case .focused, .splitRightRequested, .workingDirectoryChanged:
            scheduleWorkspaceSave()
        default:
            break
        }

        if case .splitRightRequested = activity {
            focusActivePaneAfterRender()
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
        case .focused, .copyRequested, .pasteRequested, .selectAllRequested, .splitRightRequested,
             .titleChanged, .workingDirectoryChanged:
            return nil
        }
    }

    private func focusActivePaneAfterRender() {
        workspaceController.focusActivePane()

        let delays: [TimeInterval] = [0, 0.05, 0.20]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [workspaceController] in
                workspaceController.focusActivePane()
            }
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

    @MainActor private func startCommandPaletteSmokeIfNeeded(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        guard arguments.contains("--command-palette-open-smoke") else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            isCommandPalettePresented = true
            refreshCommandPaletteProviderStatus()
        }
    }
    #endif
}

private struct AppFrameHeader: View {
    let productName: String
    let shellDisplayName: String
    let visualModeName: String
    let visualSignature: String
    let version: String
    let reducedMotion: Bool
    let theme: VisualTheme
    let availableUpdate: SoftwareUpdateInfo?
    let canCheckForUpdates: Bool
    let onShowUpdate: @MainActor () -> Void
    let onCycleVisualMode: @MainActor () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(productName)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.94))

                Text("local signal")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.62))
            }

            HeaderChip(label: "shell", value: shellDisplayName, theme: theme)
            HeaderChip(label: "sig", value: visualSignature, theme: theme)

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

            Button {
                onCycleVisualMode()
            } label: {
                Image(systemName: "paintpalette")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 26, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.72))
            .help("Cycle Visual Style")
            .accessibilityLabel("Cycle Visual Style")

            if let availableUpdate {
                HeaderUpdateButton(
                    update: availableUpdate,
                    canCheckForUpdates: canCheckForUpdates,
                    theme: theme,
                    action: onShowUpdate
                )
            }

            Text("v\(version)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.56))
                .lineLimit(1)
        }
        .padding(.leading, 72)
    }
}

private struct HeaderUpdateButton: View {
    let update: SoftwareUpdateInfo
    let canCheckForUpdates: Bool
    let theme: VisualTheme
    let action: @MainActor () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true)

                Text("UPDATE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))

                Text("v\(update.displayVersion)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
            }
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(theme.palette.statusAccent).opacity(canCheckForUpdates ? 0.82 : 0.30))
            )
            .overlay {
                Capsule()
                    .stroke(Color(theme.palette.statusAccent).opacity(0.90), lineWidth: 1)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(theme.palette.background).opacity(canCheckForUpdates ? 0.94 : 0.58))
        .disabled(!canCheckForUpdates)
        .help("Update to gridOS \(update.displayName)")
        .accessibilityLabel("Update available")
        .accessibilityValue("gridOS \(update.displayName)")
    }
}

private struct HeaderChip: View {
    let label: String
    let value: String
    let theme: VisualTheme

    var body: some View {
        HStack(spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.62))

            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.80))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(theme.palette.background).opacity(theme.panel.backgroundOpacity + 0.10))
        .overlay {
            Capsule()
                .stroke(Color(theme.palette.primaryAccent).opacity(theme.panel.borderOpacity), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(Capsule())
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
                return percentText(level)
            }

            return metrics.stateText
        case .unavailable(let reason):
            return reason == "Battery unavailable" || reason.isEmpty ? "No battery" : reason
        }
    }

    private var thermalText: String {
        switch snapshot.thermal {
        case .available(let metrics), .stale(let metrics, _):
            return metrics.stateText
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
    let visualSignature: String
    let visualModeName: String
    let theme: VisualTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            identityReadout

            Rectangle()
                .fill(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))
                .frame(height: 1)
                .accessibilityHidden(true)

            systemPulseReadout

            Rectangle()
                .fill(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))
                .frame(height: 1)
                .accessibilityHidden(true)

            HUDSignalStack(snapshot: snapshot, visualModeName: visualModeName, theme: theme)

            Rectangle()
                .fill(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))
                .frame(height: 1)
                .accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Activity")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.74))

                if snapshot.topProcesses.isStale {
                    Text("recent")
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

    private var systemPulseReadout: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("System pulse")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.74))

            VStack(spacing: 7) {
                PulseMetricRow(label: "CPU", value: cpuText, theme: theme)
                PulseMetricRow(label: "MEM", value: memoryText, theme: theme)
                PulseMetricRow(label: "NET", value: networkText, theme: theme)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System pulse")
        .accessibilityValue("CPU \(cpuText), memory \(memoryText), network \(networkText)")
    }

    private var identityReadout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(Color(theme.palette.statusAccent).opacity(0.78))
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)

                Text("Signal")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.74))

                Spacer(minLength: 4)
            }

            Text(visualSignature)
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            HStack(spacing: 7) {
                Text(visualModeName)
                Text("local")
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.66))
        }
        .padding(11)
        .background(Color(theme.palette.primaryAccent).opacity(0.045))
        .overlay {
            RoundedRectangle(cornerRadius: max(4, theme.panel.cornerRadius), style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(theme.panel.borderOpacity), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: max(4, theme.panel.cornerRadius), style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Local visual signal")
        .accessibilityValue("\(visualSignature), \(visualModeName)")
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
                return "idle"
            }

            let totalBytesPerSecond = metrics.receivedBytesPerSecond + metrics.sentBytesPerSecond
            return "\(byteRateText(totalBytesPerSecond))/s"
        }
    }
}

private struct HUDSignalStack: View {
    let snapshot: SystemMetricsSnapshot
    let visualModeName: String
    let theme: VisualTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Signal stack")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.74))

                Spacer(minLength: 4)

                Text(visualModeName.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.70))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            VStack(spacing: 7) {
                HUDSignalRow(label: "LOAD", value: loadText, fraction: loadFraction, theme: theme)
                HUDSignalRow(label: "LINK", value: linkText, fraction: linkFraction, theme: theme)
                HUDSignalRow(label: "PROC", value: processText, fraction: processFraction, theme: theme)
            }

            HUDNodeGrid(activeCount: activeNodeCount, theme: theme)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Signal stack")
        .accessibilityValue("Load \(loadText), link \(linkText), processes \(processText)")
    }

    private var loadText: String {
        "\(Int((loadFraction * 100).rounded()))%"
    }

    private var linkText: String {
        switch snapshot.network {
        case .available(let metrics), .stale(let metrics, _):
            let totalBytesPerSecond = metrics.receivedBytesPerSecond + metrics.sentBytesPerSecond
            return totalBytesPerSecond <= 1 ? "idle" : "\(byteRateText(totalBytesPerSecond))/s"
        case .unavailable:
            return "n/a"
        }
    }

    private var processText: String {
        switch snapshot.topProcesses {
        case .available(let processes), .stale(let processes, _):
            return "\(processes.count)"
        case .unavailable:
            return "n/a"
        }
    }

    private var loadFraction: Double {
        let cpu = cpuPercent
        let memory = memoryPercent

        switch (cpu, memory) {
        case let (.some(cpu), .some(memory)):
            return min(1, max(0.08, ((cpu + memory) / 2) / 100))
        case let (.some(cpu), .none):
            return min(1, max(0.08, cpu / 100))
        case let (.none, .some(memory)):
            return min(1, max(0.08, memory / 100))
        case (.none, .none):
            return 0.12
        }
    }

    private var linkFraction: Double {
        switch snapshot.network {
        case .available(let metrics), .stale(let metrics, _):
            let totalBytesPerSecond = metrics.receivedBytesPerSecond + metrics.sentBytesPerSecond
            return min(1, max(0.08, totalBytesPerSecond / 2_000_000))
        case .unavailable:
            return 0.10
        }
    }

    private var processFraction: Double {
        switch snapshot.topProcesses {
        case .available(let processes), .stale(let processes, _):
            return min(1, max(0.12, Double(processes.count) / 5))
        case .unavailable:
            return 0.10
        }
    }

    private var activeNodeCount: Int {
        min(16, max(2, Int((loadFraction * 8 + linkFraction * 4 + processFraction * 4).rounded())))
    }

    private var cpuPercent: Double? {
        switch snapshot.cpu {
        case .available(let metrics), .stale(let metrics, _):
            return metrics.usagePercent
        case .unavailable:
            return nil
        }
    }

    private var memoryPercent: Double? {
        switch snapshot.memory {
        case .available(let metrics), .stale(let metrics, _):
            return metrics.usagePercent
        case .unavailable:
            return nil
        }
    }
}

private struct HUDSignalRow: View {
    let label: String
    let value: String
    let fraction: Double
    let theme: VisualTheme

    var body: some View {
        HStack(alignment: .center, spacing: 7) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.66))
                .frame(width: 34, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(theme.palette.primaryAccent).opacity(0.07))

                    Rectangle()
                        .fill(Color(theme.palette.primaryAccent).opacity(0.50))
                        .frame(width: proxy.size.width * min(1, max(0, fraction)))

                    Rectangle()
                        .fill(Color(theme.palette.statusAccent).opacity(0.72))
                        .frame(width: 2)
                        .offset(x: max(0, proxy.size.width * min(1, max(0, fraction)) - 1))
                }
            }
            .frame(height: 5)
            .accessibilityHidden(true)

            Text(value)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .frame(width: 48, alignment: .trailing)
        }
    }
}

private struct HUDNodeGrid: View {
    let activeCount: Int
    let theme: VisualTheme

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(8), spacing: 4), count: 8),
            alignment: .leading,
            spacing: 4
        ) {
            ForEach(0..<16, id: \.self) { index in
                Rectangle()
                    .fill(nodeColor(for: index))
                    .frame(width: 8, height: 4)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 12, alignment: .leading)
    }

    private func nodeColor(for index: Int) -> Color {
        let isActive = index < activeCount
        let baseColor = index % 5 == 0 ? theme.palette.statusAccent : theme.palette.primaryAccent
        return Color(baseColor).opacity(isActive ? 0.74 : 0.12)
    }
}

private struct PulseMetricRow: View {
    let label: String
    let value: String
    let theme: VisualTheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.62))
                .frame(width: 28, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(theme.palette.primaryAccent).opacity(0.08))

                    Capsule()
                        .fill(Color(theme.palette.statusAccent).opacity(0.60))
                        .frame(width: proxy.size.width * pulseFraction)
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)

            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 56, alignment: .trailing)
        }
    }

    private var pulseFraction: Double {
        let numericPrefix = value.prefix { character in
            character.isNumber || character == "."
        }

        guard let percent = Double(numericPrefix) else {
            return 0.18
        }

        return min(1, max(0.08, percent / 100))
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
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.84))
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
        return availableText(value)
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
