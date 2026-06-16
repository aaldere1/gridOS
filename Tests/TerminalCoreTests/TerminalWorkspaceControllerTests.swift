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

    func testCopyPasteSelectAllClearResetTargetOnlyActivePane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")
        workspace.copyActivePaneSelection()
        workspace.pasteIntoActivePane()
        workspace.selectAllInActivePane()
        workspace.clearActivePane()
        workspace.resetActivePane()

        XCTAssertEqual(primary.copySelectionCount, 0)
        XCTAssertEqual(primary.pasteCount, 0)
        XCTAssertEqual(primary.selectAllCount, 0)
        XCTAssertEqual(primary.clearCount, 0)
        XCTAssertEqual(primary.resetCount, 0)
        XCTAssertEqual(secondary.copySelectionCount, 1)
        XCTAssertEqual(secondary.pasteCount, 1)
        XCTAssertEqual(secondary.selectAllCount, 1)
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

    func testUpdateTerminalFontSizeAppliesToExistingPanes() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        workspace.updateTerminalFontSize(19)

        XCTAssertEqual(workspace.state.panesByID["primary"]?.configuration.fontSize, 19)
        XCTAssertEqual(workspace.state.panesByID["pane-b"]?.configuration.fontSize, 19)
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

    func testActivePaneProcessRunningReflectsAttachedTerminal() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        XCTAssertFalse(workspace.isActivePaneProcessRunning())

        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "pane-b").attach(secondary)

        XCTAssertTrue(workspace.isActivePaneProcessRunning())

        workspace.terminateActivePane()

        XCTAssertFalse(workspace.isActivePaneProcessRunning())
    }

    func testHasRunningProcessesChecksRegisteredPanes() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "pane-b").attach(secondary)

        XCTAssertTrue(workspace.hasRunningProcesses())

        workspace.terminateAllPanes()

        XCTAssertFalse(workspace.hasRunningProcesses())
    }

    func testOpenDirectoryInNewPaneStartsPaneInSelectedDirectory() {
        let workspace = fixtureWorkspace()

        workspace.openDirectoryInNewPane("/Users/test/Project", newPaneID: "project-pane")

        XCTAssertEqual(workspace.activePaneID, "project-pane")
        XCTAssertEqual(workspace.state.panesByID["project-pane"]?.configuration.workingDirectory, "/Users/test/Project")
        XCTAssertEqual(workspace.state.panesByID["project-pane"]?.lastWorkingDirectory, "/Users/test/Project")
        XCTAssertEqual(workspace.state.recentDirectories.first, "/Users/test/Project")
    }

    func testResizeActivePaneAdjustsMatchingSplitFraction() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        workspace.resizeActivePaneRight()

        guard case .split(.horizontal, let fraction, _, _) = workspace.state.layout else {
            return XCTFail("Expected horizontal split")
        }

        XCTAssertEqual(fraction, 0.55, accuracy: 0.001)
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
    private(set) var selectAllCount = 0
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

    func selectAll() {
        selectAllCount += 1
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

    func terminateEnsuringProcessExit() {
        terminate()
    }

    func isProcessRunning() -> Bool {
        terminateCount == 0
    }
}
