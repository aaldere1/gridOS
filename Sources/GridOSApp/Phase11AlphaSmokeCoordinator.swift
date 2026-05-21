#if DEBUG
import Foundation
import TerminalCore

@MainActor
struct Phase11AlphaSmokeCoordinator {
    static let smokeArgument = "--phase11-alpha-smoke"

    static let terminalReadyMarker = "PHASE11_ALPHA_TERMINAL_READY"
    static let workspaceReadyMarker = "PHASE11_ALPHA_WORKSPACE_READY"
    static let privacyReadyMarker = "PHASE11_ALPHA_PRIVACY_READY"

    static let terminalReadyPath = "/tmp/gridos_phase11_alpha_terminal_ready.txt"
    static let workspaceReadyPath = "/tmp/gridos_phase11_alpha_workspace_ready.txt"
    static let privacyReadyPath = "/tmp/gridos_phase11_alpha_privacy_ready.txt"

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
        guard arguments.contains(Self.smokeArgument) else {
            return
        }

        removeMarkerFiles()
        Task { @MainActor in
            await runAlphaSmoke()
        }
    }

    private func runAlphaSmoke() async {
        workspaceController.activatePane("primary")
        workspaceController.focusActivePane()
        await waitForActivePaneProcess()

        workspaceController.runInActivePane(
            markerCommand(Self.terminalReadyMarker, path: Self.terminalReadyPath)
        )
        _ = await waitForFile(Self.terminalReadyPath, timeoutNanoseconds: 5_000_000_000)

        workspaceController.splitActivePane(axis: .horizontal, newPaneID: "phase11-alpha-workspace")
        await waitForActivePaneProcess()
        workspaceController.runInActivePane(
            markerCommand(Self.workspaceReadyMarker, path: Self.workspaceReadyPath)
        )
        _ = await waitForFile(Self.workspaceReadyPath, timeoutNanoseconds: 5_000_000_000)

        _ = workspaceController.closeActivePane()
        saveWorkspace()
        writeMarker(Self.privacyReadyMarker, path: Self.privacyReadyPath)
    }

    private func markerCommand(_ marker: String, path: String) -> String {
        "printf '\(marker)\\n' > \(path)"
    }

    private func writeMarker(_ marker: String, path: String) {
        try? "\(marker)\n".write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func waitForActivePaneProcess() async {
        for _ in 0..<24 {
            if workspaceController.isActivePaneProcessRunning() {
                return
            }

            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    private func waitForFile(_ path: String, timeoutNanoseconds: UInt64) async -> Bool {
        let startedAt = DispatchTime.now().uptimeNanoseconds

        while DispatchTime.now().uptimeNanoseconds - startedAt < timeoutNanoseconds {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }

            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        return FileManager.default.fileExists(atPath: path)
    }

    private func removeMarkerFiles() {
        for path in [Self.terminalReadyPath, Self.workspaceReadyPath, Self.privacyReadyPath] {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}
#endif
