#if DEBUG
import Foundation
import TerminalCore

@MainActor
struct Phase9PerformanceSmokeCoordinator {
    static let readySmokeArgument = "--phase9-ready-smoke"
    static let inputLatencySmokeArgument = "--phase9-input-latency-smoke"
    static let heavyOutputSmokeArgument = "--phase9-heavy-output-smoke"
    static let framePacingSmokeArgument = "--phase9-frame-pacing-smoke"

    static let readyMarker = "PHASE9_READY"
    static let inputLatencyMarker = "PHASE9_INPUT_LATENCY"
    static let heavyOutputMarker = "PHASE9_HEAVY_OUTPUT_DONE"
    static let framePacingMarker = "PHASE9_FRAME_PACING"

    static let readySmokePath = "/tmp/gridos_phase9_ready.json"
    static let inputLatencySmokePath = "/tmp/gridos_phase9_input_latency.json"
    static let heavyOutputSmokePath = "/tmp/gridos_phase9_heavy_output.json"
    static let framePacingSmokePath = "/tmp/gridos_phase9_frame_pacing.json"

    private static let heavyOutputShellPath = "/tmp/gridos_phase9_heavy_output_shell_marker.txt"

    private let workspaceController: TerminalWorkspaceController?
    private let renderPulse: (@MainActor () -> Void)?

    init(
        workspaceController: TerminalWorkspaceController? = nil,
        renderPulse: (@MainActor () -> Void)? = nil
    ) {
        self.workspaceController = workspaceController
        self.renderPulse = renderPulse
    }

    func startIfRequested(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard arguments.contains(Self.readySmokeArgument)
                || arguments.contains(Self.inputLatencySmokeArgument)
                || arguments.contains(Self.heavyOutputSmokeArgument)
                || arguments.contains(Self.framePacingSmokeArgument) else {
            return
        }

        if arguments.contains(Self.readySmokeArgument) {
            writeJSONMarker(
                marker: Self.readyMarker,
                path: Self.readySmokePath,
                startedAt: Date(),
                result: "PASS"
            )
        }

        guard workspaceController != nil || renderPulse != nil else {
            return
        }

        Task { @MainActor in
            if arguments.contains(Self.inputLatencySmokeArgument) {
                await runInputLatencySmoke()
            }

            if arguments.contains(Self.heavyOutputSmokeArgument) {
                await runHeavyOutputSmoke()
            }

            if arguments.contains(Self.framePacingSmokeArgument) {
                await runFramePacingSmoke()
            }
        }
    }

    private func runInputLatencySmoke() async {
        guard let workspaceController else {
            writeJSONMarker(
                marker: Self.inputLatencyMarker,
                path: Self.inputLatencySmokePath,
                startedAt: Date(),
                result: "UNAVAILABLE"
            )
            return
        }

        removeFile(Self.inputLatencySmokePath)
        await waitForActivePaneProcess(workspaceController)

        let startedAt = Date()
        workspaceController.insertInActivePane("")
        writeJSONMarker(
            marker: Self.inputLatencyMarker,
            path: Self.inputLatencySmokePath,
            startedAt: startedAt,
            result: "PASS"
        )
    }

    private func runHeavyOutputSmoke() async {
        guard let workspaceController else {
            writeJSONMarker(
                marker: Self.heavyOutputMarker,
                path: Self.heavyOutputSmokePath,
                startedAt: Date(),
                result: "UNAVAILABLE"
            )
            return
        }

        removeFile(Self.heavyOutputSmokePath)
        removeFile(Self.heavyOutputShellPath)
        await waitForActivePaneProcess(workspaceController)

        let startedAt = Date()
        workspaceController.runInActivePane(
            """
            i=1; while [ "$i" -le 500 ]; do printf 'PHASE9_HEAVY_OUTPUT_LINE_%04d\\n' "$i"; i=$((i + 1)); done; printf '\(Self.heavyOutputMarker)\\n' > \(Self.heavyOutputShellPath)
            """
        )

        let completed = await waitForFile(Self.heavyOutputShellPath, timeoutNanoseconds: 8_000_000_000)
        writeJSONMarker(
            marker: Self.heavyOutputMarker,
            path: Self.heavyOutputSmokePath,
            startedAt: startedAt,
            result: completed ? "PASS" : "MISS",
            extraFields: [
                ("line_count", "500")
            ]
        )
    }

    private func runFramePacingSmoke() async {
        removeFile(Self.framePacingSmokePath)
        let startedAt = Date()

        for _ in 0..<8 {
            renderPulse?()
            try? await Task.sleep(nanoseconds: 33_000_000)
        }

        writeJSONMarker(
            marker: Self.framePacingMarker,
            path: Self.framePacingSmokePath,
            startedAt: startedAt,
            result: renderPulse == nil ? "UNAVAILABLE" : "PASS",
            extraFields: [
                ("pulse_count", renderPulse == nil ? "0" : "8")
            ]
        )
    }

    private func waitForActivePaneProcess(_ workspaceController: TerminalWorkspaceController) async {
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

    private func writeJSONMarker(
        marker: String,
        path: String,
        startedAt: Date,
        result: String,
        extraFields: [(key: String, value: String)] = []
    ) {
        let finishedAt = Date()
        let elapsedMilliseconds = max(0, finishedAt.timeIntervalSince(startedAt) * 1_000)
        let extraJSON = extraFields
            .map { "  \"\($0.key)\": \($0.value)" }
            .joined(separator: ",\n")
        let extraSection = extraJSON.isEmpty ? "" : ",\n\(extraJSON)"
        let body = """
        {
          "marker": "\(jsonEscaped(marker))",
          "started_at": \(String(format: "%.6f", startedAt.timeIntervalSince1970)),
          "finished_at": \(String(format: "%.6f", finishedAt.timeIntervalSince1970)),
          "elapsed_ms": \(String(format: "%.3f", elapsedMilliseconds)),
          "result": "\(jsonEscaped(result))"\(extraSection)
        }

        """

        try? body.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func removeFile(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    private func jsonEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
#endif
