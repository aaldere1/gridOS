import XCTest
@testable import TerminalCore

@MainActor
final class TerminalWorkspaceControllerTests: XCTestCase {
    func testInsertTargetsOnlyActivePane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("primary")
        workspace.insertInActivePane("echo primary")
        workspace.activatePane("pane-b")
        workspace.insertInActivePane("echo secondary")

        XCTAssertEqual(primary.sentTexts, ["echo primary"])
        XCTAssertEqual(secondary.sentTexts, ["echo secondary"])
    }

    func testRunTargetsOnlyActivePane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")
        workspace.runInActivePane("pwd")

        XCTAssertTrue(primary.sentTexts.isEmpty)
        XCTAssertEqual(secondary.sentTexts, ["pwd\n"])
    }

    func testCopyPasteClearResetTargetOnlyActivePane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")
        workspace.copyActivePaneSelection()
        workspace.pasteIntoActivePane()
        workspace.clearActivePane()
        workspace.resetActivePane()

        XCTAssertEqual(primary.copySelectionCount, 0)
        XCTAssertEqual(primary.pasteCount, 0)
        XCTAssertEqual(primary.clearCount, 0)
        XCTAssertEqual(primary.resetCount, 0)
        XCTAssertEqual(secondary.copySelectionCount, 1)
        XCTAssertEqual(secondary.pasteCount, 1)
        XCTAssertEqual(secondary.clearCount, 1)
        XCTAssertEqual(secondary.resetCount, 1)
    }

    func testCloseActivePaneTerminatesOnlyClosedPane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        XCTAssertTrue(workspace.closeActivePane())

        XCTAssertEqual(primary.terminateCount, 0)
        XCTAssertEqual(secondary.terminateCount, 1)
        XCTAssertNil(workspace.state.panesByID["pane-b"])
        XCTAssertEqual(workspace.activePaneID, "primary")
        XCTAssertFalse(workspace.closeActivePane())
        XCTAssertEqual(primary.terminateCount, 0)
    }

    func testTerminateAllPanesTerminatesEveryRegisteredPane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.terminateAllPanes()

        XCTAssertEqual(primary.terminateCount, 1)
        XCTAssertEqual(secondary.terminateCount, 1)
    }

    func testWorkingDirectoryActivityUpdatesOnlySourcePane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        workspace.handleActivity(.workingDirectoryChanged("/Users/test/pane-b"), from: "pane-b")
        workspace.handleActivity(.output(byteCount: 128), from: "primary")

        XCTAssertEqual(workspace.state.panesByID["primary"]?.lastWorkingDirectory, "/Users/test")
        XCTAssertEqual(workspace.state.panesByID["pane-b"]?.lastWorkingDirectory, "/Users/test/pane-b")
        XCTAssertEqual(workspace.state.recentDirectories.first, "/Users/test/pane-b")
    }

    func testFocusNextChangesActivePaneAndRequestsFocus() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.focusNextPane()

        XCTAssertEqual(workspace.activePaneID, "primary")
        XCTAssertEqual(primary.focusRequestCount, 1)
        XCTAssertEqual(secondary.focusRequestCount, 0)
    }

    private func fixtureWorkspace() -> TerminalWorkspaceController {
        TerminalWorkspaceController(
            state: TerminalWorkspaceState(
                defaultConfiguration: TerminalSessionConfiguration(
                    shellPath: "/bin/zsh",
                    shellArguments: ["-l"],
                    workingDirectory: "/Users/test",
                    fontName: "Menlo",
                    fontSize: 14,
                    startupCommand: nil
                )
            )
        )
    }
}

@MainActor
private final class TerminalRoutingSpy: TerminalInteractionControllingTerminal {
    private(set) var sentTexts: [String] = []
    private(set) var focusRequestCount = 0
    private(set) var copySelectionCount = 0
    private(set) var pasteCount = 0
    private(set) var clearCount = 0
    private(set) var resetCount = 0
    private(set) var terminateCount = 0

    func getSelection() -> String? {
        nil
    }

    func sendText(_ text: String) {
        sentTexts.append(text)
    }

    func focusTerminal() {
        focusRequestCount += 1
    }

    func copySelection() {
        copySelectionCount += 1
    }

    func paste() {
        pasteCount += 1
    }

    func clear() {
        clearCount += 1
    }

    func reset() {
        resetCount += 1
    }

    func terminate() {
        terminateCount += 1
    }

    func isProcessRunning() -> Bool {
        terminateCount == 0
    }
}
