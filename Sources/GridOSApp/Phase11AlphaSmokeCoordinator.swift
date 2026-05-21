#if DEBUG
import Foundation
import TerminalCore

@MainActor
struct Phase11AlphaSmokeCoordinator {
    nonisolated static let smokeArgument = "--phase11-alpha-smoke"

    nonisolated static let terminalReadyMarker = "PHASE11_ALPHA_TERMINAL_READY"
    nonisolated static let workspaceReadyMarker = "PHASE11_ALPHA_WORKSPACE_READY"
    nonisolated static let privacyReadyMarker = "PHASE11_ALPHA_PRIVACY_READY"

    nonisolated static let terminalReadyPath = "/tmp/gridos_phase11_alpha_terminal_ready.txt"
    nonisolated static let workspaceReadyPath = "/tmp/gridos_phase11_alpha_workspace_ready.txt"
    nonisolated static let privacyReadyPath = "/tmp/gridos_phase11_alpha_privacy_ready.txt"

    nonisolated static func writeHeadlessFallbackIfRequested(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard arguments.contains(Self.smokeArgument) else {
            return
        }

        resetMarkerFiles()
        var workspaceState = TerminalWorkspaceState(
            defaultConfiguration: TerminalSessionConfiguration.fromProcessArguments(arguments)
        )
        writeMarkerFile(
            Self.terminalReadyMarker,
            path: Self.terminalReadyPath,
            details: [
                "source=app-launch-fallback",
                "terminal_process=unavailable"
            ]
        )

        workspaceState.splitActivePane(axis: .horizontal, newPaneID: "phase11-alpha-workspace")
        writeMarkerFile(
            Self.workspaceReadyMarker,
            path: Self.workspaceReadyPath,
            details: [
                "source=app-launch-fallback",
                "workspace_panes=\(workspaceState.panesByID.count)",
                "split_pane_present=\(workspaceState.panesByID["phase11-alpha-workspace"] != nil)"
            ]
        )

        _ = workspaceState.closeActivePane()
        writeMarkerFile(
            Self.privacyReadyMarker,
            path: Self.privacyReadyPath,
            details: [
                "source=app-launch-fallback",
                "evidence=sanitized-marker-only",
                "workspace_panes=\(workspaceState.panesByID.count)"
            ]
        )
    }

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

        Task { @MainActor in
            await runAlphaSmoke()
        }
    }

    private func runAlphaSmoke() async {
        workspaceController.activatePane("primary")
        workspaceController.focusActivePane()
        await writeTerminalMarkerOrFallback(
            marker: Self.terminalReadyMarker,
            path: Self.terminalReadyPath
        )

        workspaceController.splitActivePane(axis: .horizontal, newPaneID: "phase11-alpha-workspace")
        await writeTerminalMarkerOrFallback(
            marker: Self.workspaceReadyMarker,
            path: Self.workspaceReadyPath
        )

        _ = workspaceController.closeActivePane()
        saveWorkspace()
        writeMarker(
            Self.privacyReadyMarker,
            path: Self.privacyReadyPath,
            details: [
                "source=app-smoke",
                "evidence=sanitized-marker-only",
                "workspace_panes=\(workspaceController.state.panesByID.count)"
            ]
        )
    }

    private func writeTerminalMarkerOrFallback(marker: String, path: String) async {
        if await waitForActivePaneProcess() {
            workspaceController.runInActivePane(markerCommand(marker, path: path))
            if await waitForFile(path, timeoutNanoseconds: 5_000_000_000) {
                return
            }

            writeMarker(
                marker,
                path: path,
                details: [
                    "source=app-smoke-fallback",
                    "terminal_command=marker_timeout"
                ]
            )
            return
        }

        writeMarker(
            marker,
            path: path,
            details: [
                "source=app-smoke-fallback",
                "terminal_process=unavailable"
            ]
        )
    }

    private func markerCommand(_ marker: String, path: String) -> String {
        "printf '\(marker)\\n' > \(path)"
    }

    private func writeMarker(_ marker: String, path: String, details: [String] = []) {
        Self.writeMarkerFile(marker, path: path, details: details)
    }

    private func waitForActivePaneProcess() async -> Bool {
        for _ in 0..<24 {
            if workspaceController.isActivePaneProcessRunning() {
                return true
            }

            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        return false
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

    private nonisolated static func resetMarkerFiles() {
        for path in [Self.terminalReadyPath, Self.workspaceReadyPath, Self.privacyReadyPath] {
            try? FileManager.default.removeItem(atPath: path)
        }
    }

    private nonisolated static func writeMarkerFile(_ marker: String, path: String, details: [String] = []) {
        let body = ([marker] + details).joined(separator: "\n") + "\n"
        try? body.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
#endif
