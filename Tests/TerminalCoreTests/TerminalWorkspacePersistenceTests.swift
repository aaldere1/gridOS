import XCTest
@testable import TerminalCore

final class TerminalWorkspacePersistenceTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridos-persistence-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        temporaryDirectory = nil
        try super.tearDownWithError()
    }

    func testSnapshotStoreRoundTripsWorkspace() throws {
        let store = fixtureStore()
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        state.updateWorkingDirectory(temporaryDirectory.path, for: "pane-b")

        try store.saveSnapshot(state.snapshot())
        let snapshot = try XCTUnwrap(store.loadSnapshot(
            fallbackConfiguration: fixtureConfiguration(workingDirectory: "/fallback"),
            directoryExists: { FileManager.default.fileExists(atPath: $0) }
        ))

        let restored = TerminalWorkspaceState(
            snapshot: snapshot,
            fallbackConfiguration: fixtureConfiguration(workingDirectory: "/fallback"),
            directoryExists: { FileManager.default.fileExists(atPath: $0) }
        )

        XCTAssertEqual(restored.layout.paneIDsInVisualOrder, ["primary", "pane-b"])
        XCTAssertEqual(restored.activePaneID, "pane-b")
        XCTAssertEqual(restored.panesByID["pane-b"]?.configuration.workingDirectory, temporaryDirectory.path)
    }

    func testMissingSnapshotReturnsNil() throws {
        let store = fixtureStore()

        let snapshot = try store.loadSnapshot(
            fallbackConfiguration: fixtureConfiguration(),
            directoryExists: { _ in true }
        )

        XCTAssertNil(snapshot)
    }

    func testRecentDirectoriesRoundTrip() throws {
        let store = fixtureStore()

        try store.saveRecentDirectories([" /tmp/a ", "/tmp/b", "/tmp/a", " "])

        XCTAssertEqual(try store.loadRecentDirectories(), ["/tmp/a", "/tmp/b"])
    }

    func testDeleteStoredSessionRemovesFiles() throws {
        let store = fixtureStore()
        try store.saveSnapshot(TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration()).snapshot())
        try store.saveRecentDirectories(["/tmp/a"])

        try store.deleteStoredSession()

        XCTAssertNil(try store.loadSnapshot(fallbackConfiguration: fixtureConfiguration(), directoryExists: { _ in true }))
        XCTAssertEqual(try store.loadRecentDirectories(), [])
    }

    func testCorruptSnapshotDoesNotCrash() throws {
        let store = fixtureStore()
        let sessionURL = temporaryDirectory.appendingPathComponent("session-v1.json")
        try Data("not json".utf8).write(to: sessionURL)

        let snapshot = try store.loadSnapshot(
            fallbackConfiguration: fixtureConfiguration(),
            directoryExists: { _ in true }
        )

        XCTAssertNil(snapshot)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sessionURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: temporaryDirectory.appendingPathComponent("session-v1.corrupt.json").path))
    }

    func testPersistenceDoesNotEncodeProcessIdentifiers() throws {
        let store = fixtureStore()
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        try store.saveSnapshot(state.snapshot())

        let json = try String(contentsOf: temporaryDirectory.appendingPathComponent("session-v1.json"), encoding: .utf8)
        for token in forbiddenPrivacyTokens {
            XCTAssertFalse(json.contains(token), token)
        }
    }

    private var forbiddenPrivacyTokens: [String] {
        [
            "shell" + "Pid",
            "process" + "ID",
            "child" + "fd",
            "command" + "Output",
            "shell" + "History",
            "env" + "ironment"
        ]
    }

    private func fixtureStore() -> TerminalWorkspaceSnapshotStore {
        TerminalWorkspaceSnapshotStore(baseDirectory: temporaryDirectory)
    }

    private func fixtureConfiguration(workingDirectory: String? = "/Users/test") -> TerminalSessionConfiguration {
        TerminalSessionConfiguration(
            shellPath: "/bin/zsh",
            shellArguments: ["-l"],
            workingDirectory: workingDirectory,
            fontName: "Menlo",
            fontSize: 14,
            startupCommand: nil
        )
    }
}
