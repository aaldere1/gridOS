import Combine
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
        XCTAssertEqual(secondary.copySelectionCount, 0)
        XCTAssertEqual(secondary.pasteCount, 1)
        XCTAssertEqual(secondary.selectAllCount, 1)
        XCTAssertEqual(secondary.clearCount, 1)
        XCTAssertEqual(secondary.resetCount, 1)
    }

    func testCopyFromOnePanePastesClipboardIntoAnotherPane() {
        let clipboard = TerminalClipboardSpy()
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy(selection: "echo from primary")
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("primary")
        workspace.copyActivePaneSelection()
        workspace.activatePane("pane-b")
        workspace.pasteIntoActivePane()

        XCTAssertEqual(clipboard.string, "echo from primary")
        XCTAssertTrue(primary.sentTexts.isEmpty)
        XCTAssertEqual(secondary.sentTexts, ["echo from primary"])
        XCTAssertEqual(secondary.pasteCount, 0)
    }

    func testCopyFallsBackToSelectedTextInInactivePane() {
        let clipboard = TerminalClipboardSpy()
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy(selection: "echo selected elsewhere")
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")

        XCTAssertTrue(workspace.copyActivePaneSelection())
        XCTAssertEqual(workspace.activePaneID, "pane-b")
        XCTAssertEqual(clipboard.string, "echo selected elsewhere")

        XCTAssertTrue(workspace.pasteIntoActivePane())
        XCTAssertTrue(primary.sentTexts.isEmpty)
        XCTAssertEqual(secondary.sentTexts, ["echo selected elsewhere"])
    }

    func testCopyPrefersActivePaneSelectionBeforeOtherPaneSelections() {
        let clipboard = TerminalClipboardSpy()
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy(selection: "stale primary selection")
        let secondary = TerminalRoutingSpy(selection: "fresh active selection")
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")

        XCTAssertTrue(workspace.copyActivePaneSelection())
        XCTAssertEqual(clipboard.string, "fresh active selection")
    }

    func testCopyRequestPrefersSourcePaneSelectionBeforeActivePaneSelection() {
        let clipboard = TerminalClipboardSpy()
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy(selection: "copy this from source")
        let secondary = TerminalRoutingSpy(selection: "do not copy active")
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")
        workspace.handleActivity(.copyRequested, from: "primary")

        XCTAssertEqual(workspace.activePaneID, "pane-b")
        XCTAssertEqual(clipboard.string, "copy this from source")
    }

    func testSelectAllRequestTargetsSourcePaneBeforeActivePane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")
        workspace.handleActivity(.selectAllRequested, from: "primary")

        XCTAssertEqual(workspace.activePaneID, "pane-b")
        XCTAssertEqual(primary.selectAllCount, 1)
        XCTAssertEqual(secondary.selectAllCount, 0)
    }

    func testPasteRequestTargetsSourcePaneBeforeActivePane() {
        let clipboard = TerminalClipboardSpy(string: "echo source paste")
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")
        workspace.handleActivity(.pasteRequested, from: "primary")

        XCTAssertEqual(primary.sentTexts, ["echo source paste"])
        XCTAssertTrue(secondary.sentTexts.isEmpty)
    }

    func testPasteRequestFromThirdPaneSurvivesStaleActivePaneAfterSwitching() {
        let clipboard = TerminalClipboardSpy(string: "echo pane c")
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        workspace.activatePane("primary")
        workspace.splitActivePane(axis: .vertical, newPaneID: "pane-c")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        let tertiary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)
        workspace.controller(for: "pane-c").attach(tertiary)

        workspace.activatePane("pane-b")
        workspace.handleActivity(.pasteRequested, from: "pane-c")

        XCTAssertEqual(workspace.activePaneID, "pane-b")
        XCTAssertTrue(primary.sentTexts.isEmpty)
        XCTAssertTrue(secondary.sentTexts.isEmpty)
        XCTAssertEqual(tertiary.sentTexts, ["echo pane c"])
    }

    func testPasteRequestFromMovedPaneTargetsMovedSourcePane() {
        let clipboard = TerminalClipboardSpy(string: "echo moved pane")
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        workspace.activatePane("primary")
        workspace.splitActivePane(axis: .vertical, newPaneID: "pane-c")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        let tertiary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)
        workspace.controller(for: "pane-c").attach(tertiary)

        XCTAssertTrue(workspace.movePane("pane-c", relativeTo: "pane-b", placement: .after))
        workspace.activatePane("pane-b")
        workspace.handleActivity(.pasteRequested, from: "pane-c")

        XCTAssertEqual(workspace.activePaneID, "pane-b")
        XCTAssertTrue(primary.sentTexts.isEmpty)
        XCTAssertTrue(secondary.sentTexts.isEmpty)
        XCTAssertEqual(tertiary.sentTexts, ["echo moved pane"])
    }

    func testPasteRequestFromMissingSourceFallsBackToActivePane() {
        let clipboard = TerminalClipboardSpy(string: "echo active fallback")
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        workspace.activatePane("pane-b")
        workspace.handleActivity(.pasteRequested, from: "missing-pane")

        XCTAssertTrue(primary.sentTexts.isEmpty)
        XCTAssertEqual(secondary.sentTexts, ["echo active fallback"])
    }

    func testRapidPasteRequestsEachTargetTheirSourcePane() {
        let clipboard = TerminalClipboardSpy(string: "first")
        let workspace = fixtureWorkspace(clipboard: clipboard)
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        workspace.activatePane("primary")
        workspace.splitActivePane(axis: .vertical, newPaneID: "pane-c")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        let tertiary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)
        workspace.controller(for: "pane-c").attach(tertiary)

        workspace.activatePane("primary")
        workspace.handleActivity(.pasteRequested, from: "pane-b")
        clipboard.string = "second"
        workspace.handleActivity(.pasteRequested, from: "pane-c")

        XCTAssertEqual(workspace.activePaneID, "primary")
        XCTAssertTrue(primary.sentTexts.isEmpty)
        XCTAssertEqual(secondary.sentTexts, ["first"])
        XCTAssertEqual(tertiary.sentTexts, ["second"])
    }

    func testFocusedActivityActivatesSourcePaneForMenuCommands() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        workspace.activatePane("primary")
        workspace.handleActivity(.focused, from: "pane-b")

        XCTAssertEqual(workspace.activePaneID, "pane-b")

        workspace.handleActivity(.focused, from: "missing-pane")

        XCTAssertEqual(workspace.activePaneID, "pane-b")
    }

    func testSplitRightActivityCreatesPaneFromSourcePane() {
        let workspace = fixtureWorkspace()

        workspace.handleActivity(.splitRightRequested, from: "primary")

        XCTAssertEqual(workspace.state.panesByID.count, 2)
        XCTAssertNotEqual(workspace.activePaneID, "primary")

        guard case .split(.horizontal, _, .pane("primary"), .pane(let newPaneID)) = workspace.state.layout else {
            return XCTFail("Expected primary to split right from terminal shortcut activity")
        }

        XCTAssertEqual(workspace.activePaneID, newPaneID)
    }

    func testSplitPublishesWorkspaceChangeForSwiftUIRendering() {
        let workspace = fixtureWorkspace()
        var didPublish = false
        let cancellable = workspace.objectWillChange.sink {
            didPublish = true
        }

        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        XCTAssertTrue(didPublish)
        withExtendedLifetime(cancellable) {}
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
        let secondaryController = workspace.controller(for: "pane-b")

        workspace.terminateAllPanes()

        XCTAssertEqual(primary.terminateCount, 1)
        XCTAssertEqual(secondary.terminateCount, 1)
        XCTAssertFalse(workspace.controller(for: "pane-b") === secondaryController)
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

    func testMovePaneUpdatesLayoutAndFocusesMovedPane() {
        let workspace = fixtureWorkspace()
        workspace.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let primary = TerminalRoutingSpy()
        let secondary = TerminalRoutingSpy()
        workspace.controller(for: "primary").attach(primary)
        workspace.controller(for: "pane-b").attach(secondary)

        XCTAssertTrue(workspace.movePane("primary", relativeTo: "pane-b", placement: .after))

        XCTAssertEqual(workspace.state.layout.paneIDsInVisualOrder, ["pane-b", "primary"])
        XCTAssertEqual(workspace.activePaneID, "primary")
        XCTAssertEqual(primary.focusRequestCount, 1)
        XCTAssertEqual(secondary.focusRequestCount, 0)
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

    private func fixtureWorkspace(clipboard: any TerminalClipboard = TerminalClipboardSpy()) -> TerminalWorkspaceController {
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
            ),
            clipboard: clipboard
        )
    }
}

@MainActor
private final class TerminalRoutingSpy: TerminalInteractionControllingTerminal {
    private let selection: String?
    private(set) var sentTexts: [String] = []
    private(set) var focusRequestCount = 0
    private(set) var copySelectionCount = 0
    private(set) var pasteCount = 0
    private(set) var selectAllCount = 0
    private(set) var clearCount = 0
    private(set) var resetCount = 0
    private(set) var terminateCount = 0

    init(selection: String? = nil) {
        self.selection = selection
    }

    func getSelection() -> String? {
        selection
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

@MainActor
private final class TerminalClipboardSpy: TerminalClipboard {
    var string: String?

    init(string: String? = nil) {
        self.string = string
    }

    func readString() -> String? {
        string
    }

    func writeString(_ string: String) {
        self.string = string
    }
}
