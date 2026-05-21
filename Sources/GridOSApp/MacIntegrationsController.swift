import AppKit
import Foundation
import Integrations
import SystemMetrics
import TerminalCore

@MainActor
final class MacIntegrationsController: ObservableObject {
    @Published var status = MenuBarStatusSnapshot()
    @Published var recentDirectories: [MenuBarRecentDirectory] = []

    private let metricsSampler: any SystemMetricsSampler
    private let snapshotStore: TerminalWorkspaceSnapshotStore

    init(
        metricsSampler: any SystemMetricsSampler = LiveSystemMetricsSampler(),
        snapshotStore: TerminalWorkspaceSnapshotStore = TerminalWorkspaceSnapshotStore()
    ) {
        self.metricsSampler = metricsSampler
        self.snapshotStore = snapshotStore
    }

    func refresh() {
        refreshRecentDirectories()

        Task {
            let snapshot = await metricsSampler.snapshot(isActive: false)
            await MainActor.run {
                status = Self.statusSnapshot(from: snapshot)
            }
        }
    }

    func openGridOS() {
        if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .gridOSMenuBarOpenGridOS, object: nil)
    }

    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openRecentDirectory(_ directory: MenuBarRecentDirectory) {
        guard !directory.path.isEmpty else {
            return
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: directory.path, isDirectory: true))
    }

    func quitGridOS() {
        NSApp.terminate(nil)
    }

    private func refreshRecentDirectories() {
        let directories = (try? snapshotStore.loadRecentDirectories()) ?? []
        recentDirectories = directories.map { MenuBarRecentDirectory(path: $0) }
    }

    private static func statusSnapshot(from snapshot: SystemMetricsSnapshot) -> MenuBarStatusSnapshot {
        MenuBarStatusSnapshot(
            activeWorkspaceLabel: "Active workspace",
            shellDisplayName: TerminalSessionConfiguration.default.shellDisplayName,
            cpuText: "CPU \(percentText(snapshot.cpu.value?.usagePercent))",
            memoryText: "MEM \(percentText(snapshot.memory.value?.usagePercent))",
            networkText: "NET \(networkText(snapshot.network.value))",
            batteryText: "BAT \(batteryText(snapshot.battery))",
            thermalText: "THERM \(thermalText(snapshot.thermal))",
            isStale: snapshot.samplingState.isStale
        )
    }

    private static func percentText(_ value: Double?) -> String {
        guard let value else {
            return "unavailable"
        }

        return "\(Int(value.rounded()))%"
    }

    private static func networkText(_ metrics: NetworkMetrics?) -> String {
        guard let metrics else {
            return "unavailable"
        }

        if metrics.stateText == "Network idle" {
            return "idle"
        }

        let totalBytesPerSecond = metrics.receivedBytesPerSecond + metrics.sentBytesPerSecond
        return "\(byteRateText(totalBytesPerSecond))/s"
    }

    private static func batteryText(_ availability: SystemMetricAvailability<BatteryMetrics>) -> String {
        switch availability {
        case .available(let metrics), .stale(let metrics, _):
            if let level = metrics.levelPercent {
                return percentText(level)
            }
            return metrics.stateText
        case .unavailable:
            return "unavailable"
        }
    }

    private static func thermalText(_ availability: SystemMetricAvailability<ThermalMetrics>) -> String {
        switch availability {
        case .available(let metrics), .stale(let metrics, _):
            return metrics.stateText
        case .unavailable:
            return "unavailable"
        }
    }

    private static func byteRateText(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1_000_000 {
            return String(format: "%.1f MB", bytesPerSecond / 1_000_000)
        }

        if bytesPerSecond >= 1_000 {
            return String(format: "%.0f KB", bytesPerSecond / 1_000)
        }

        return "\(Int(bytesPerSecond.rounded())) B"
    }
}

extension Notification.Name {
    static let gridOSMenuBarOpenGridOS = Notification.Name("gridOS.menuBar.openGridOS")
}
