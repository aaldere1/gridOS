#if DEBUG
import Foundation
import TerminalCore

@MainActor
struct Phase7MultiPaneSmokeCoordinator {
    static let multiPaneArgument = "--phase7-multipane-smoke"
    static let sessionRestoreArgument = "--phase7-session-restore-smoke"

    static let paneAMarker = "PHASE7_PANE_A"
    static let paneBMarker = "PHASE7_PANE_B"
    static let closeCleanupMarker = "PHASE7_CLOSE_CLEANUP"
    static let restoreMarker = "PHASE7_RESTORE"

    private let workspaceController: TerminalWorkspaceController
    private let saveWorkspace: @MainActor () -> Void

    init(
        workspaceController: TerminalWorkspaceController,
        saveWorkspace: @escaping @MainActor () -> Void
    ) {
        self.workspaceController = workspaceController
        self.saveWorkspace = saveWorkspace
    }

    func startIfRequested(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard arguments.contains(Self.multiPaneArgument) || arguments.contains(Self.sessionRestoreArgument) else {
            return
        }

        Task { @MainActor in
            if arguments.contains(Self.multiPaneArgument) {
                await runMultiPaneSmoke()
            }

            if arguments.contains(Self.sessionRestoreArgument) {
                await runSessionRestoreSmoke()
            }
        }
    }

    private func runMultiPaneSmoke() async {
        workspaceController.activatePane("primary")
        workspaceController.runInActivePane(markerCommand(Self.paneAMarker, path: "/tmp/gridos_phase7_pane_a.txt"))
        await pauseForShell()

        workspaceController.splitActivePane(axis: .horizontal, newPaneID: "phase7-pane-b")
        workspaceController.runInActivePane(markerCommand(Self.paneBMarker, path: "/tmp/gridos_phase7_pane_b.txt"))
        await pauseForShell()

        _ = workspaceController.closeActivePane()
        writeMarker(Self.closeCleanupMarker, path: "/tmp/gridos_phase7_close_cleanup.txt")
        saveWorkspace()
    }

    private func runSessionRestoreSmoke() async {
        workspaceController.runInActivePane(markerCommand(Self.restoreMarker, path: "/tmp/gridos_phase7_restore.txt"))
        await pauseForShell()
        saveWorkspace()
    }

    private func markerCommand(_ marker: String, path: String) -> String {
        "printf '\(marker)\\n' > \(path)"
    }

    private func writeMarker(_ marker: String, path: String) {
        try? "\(marker)\n".write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func pauseForShell() async {
        try? await Task.sleep(nanoseconds: 700_000_000)
    }
}
#endif
