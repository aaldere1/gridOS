import XCTest
@testable import TerminalCore

@MainActor
final class TerminalInteractionControllerTests: XCTestCase {
    func testInsertSendsTextWithoutNewline() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController()

        controller.attach(terminal)
        controller.insert("echo hi")

        XCTAssertEqual(terminal.sentTexts, ["echo hi"])
    }

    func testRunAppendsSingleNewline() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController()

        controller.attach(terminal)
        controller.run("echo hi")

        XCTAssertEqual(terminal.sentTexts, ["echo hi\n"])
    }

    func testBlankSelectionReturnsNil() {
        let terminal = TerminalInteractionTerminalSpy(selection: " \n\t ")
        let controller = TerminalInteractionController()

        controller.attach(terminal)

        XCTAssertNil(controller.selectedText())
    }

    func testNonEmptySelectionReturnsSelectedText() {
        let terminal = TerminalInteractionTerminalSpy(selection: "permission denied")
        let controller = TerminalInteractionController()

        controller.attach(terminal)

        XCTAssertEqual(controller.selectedText(), "permission denied")
    }

    func testFocusTerminalAsksTerminalToBecomeFirstResponder() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController()

        controller.attach(terminal)
        controller.focusTerminal()

        XCTAssertEqual(terminal.focusRequestCount, 1)
    }

    func testCopySelectionReturnsFalseWithoutSelection() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController()

        controller.attach(terminal)

        XCTAssertFalse(controller.copySelection())
        XCTAssertEqual(terminal.copySelectionCount, 0)
    }

    func testCopySelectionWritesSelectedTextToClipboard() {
        let terminal = TerminalInteractionTerminalSpy(selection: "echo copied")
        let clipboard = TerminalClipboardSpy()
        let controller = TerminalInteractionController(clipboard: clipboard)

        controller.attach(terminal)

        XCTAssertTrue(controller.copySelection())
        XCTAssertEqual(clipboard.string, "echo copied")
        XCTAssertEqual(terminal.copySelectionCount, 0)
    }

    func testCopySelectionDoesNotReplaceClipboardWithoutSelection() {
        let terminal = TerminalInteractionTerminalSpy(selection: "")
        let clipboard = TerminalClipboardSpy(string: "keep me")
        let controller = TerminalInteractionController(clipboard: clipboard)

        controller.attach(terminal)

        XCTAssertFalse(controller.copySelection())
        XCTAssertEqual(clipboard.string, "keep me")
    }

    func testPasteTargetsAttachedTerminal() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController(clipboard: TerminalClipboardSpy())

        controller.attach(terminal)
        controller.paste()

        XCTAssertEqual(terminal.pasteCount, 1)
    }

    func testPasteInjectsClipboardTextAsTerminalPaste() {
        let terminal = TerminalInteractionTerminalSpy()
        let clipboard = TerminalClipboardSpy(string: "printf 'from pane a'\n")
        let controller = TerminalInteractionController(clipboard: clipboard)

        controller.attach(terminal)

        XCTAssertTrue(controller.paste())
        XCTAssertEqual(terminal.pastedTexts, ["printf 'from pane a'\n"])
        XCTAssertEqual(terminal.pasteCount, 0)
    }

    func testPasteFallsBackToTerminalPasteWhenClipboardHasNoString() {
        let terminal = TerminalInteractionTerminalSpy()
        let clipboard = TerminalClipboardSpy(string: nil)
        let controller = TerminalInteractionController(clipboard: clipboard)

        controller.attach(terminal)

        XCTAssertFalse(controller.paste())
        XCTAssertEqual(terminal.pastedTexts, [])
        XCTAssertEqual(terminal.pasteCount, 1)
    }

    func testSelectAllTargetsAttachedTerminal() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController()

        controller.attach(terminal)
        controller.selectAll()

        XCTAssertEqual(terminal.selectAllCount, 1)
    }

    func testClearSendsControlL() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController()

        controller.attach(terminal)
        controller.clear()

        XCTAssertEqual(terminal.clearCount, 1)
    }

    func testResetTargetsAttachedTerminal() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController()

        controller.attach(terminal)
        controller.reset()

        XCTAssertEqual(terminal.resetCount, 1)
    }

    func testTerminateTargetsAttachedTerminal() {
        let terminal = TerminalInteractionTerminalSpy()
        let controller = TerminalInteractionController()

        controller.attach(terminal)
        controller.terminate()

        XCTAssertEqual(terminal.terminateCount, 1)
    }

    func testIsProcessRunningReflectsAttachedTerminal() {
        let runningTerminal = TerminalInteractionTerminalSpy(isRunning: true)
        let stoppedTerminal = TerminalInteractionTerminalSpy(isRunning: false)
        let controller = TerminalInteractionController()

        XCTAssertFalse(controller.isProcessRunning())

        controller.attach(runningTerminal)
        XCTAssertTrue(controller.isProcessRunning())

        controller.attach(stoppedTerminal)
        XCTAssertFalse(controller.isProcessRunning())
    }

    func testReplacingAttachedTerminalTerminatesDisplacedTerminal() {
        let firstTerminal = TerminalInteractionTerminalSpy(isRunning: true)
        let replacementTerminal = TerminalInteractionTerminalSpy(isRunning: true)
        let controller = TerminalInteractionController()

        controller.attach(firstTerminal)
        controller.attach(firstTerminal)
        controller.attach(replacementTerminal)

        XCTAssertEqual(firstTerminal.terminateCount, 1)
        XCTAssertEqual(replacementTerminal.terminateCount, 0)
        controller.run("echo replacement")
        XCTAssertTrue(firstTerminal.sentTexts.isEmpty)
        XCTAssertEqual(replacementTerminal.sentTexts, ["echo replacement\n"])
    }

    func testAttachedTerminalReturnsControllerOwnedTerminal() {
        let terminal = TerminalInteractionTerminalSpy(isRunning: true)
        let controller = TerminalInteractionController()

        XCTAssertNil(controller.attachedTerminal(as: TerminalInteractionTerminalSpy.self))

        controller.attach(terminal)

        XCTAssertTrue(controller.owns(terminal))
        XCTAssertTrue(controller.attachedTerminal(as: TerminalInteractionTerminalSpy.self) === terminal)
    }
}

@MainActor
private final class TerminalInteractionTerminalSpy: TerminalInteractionControllingTerminal {
    private let selection: String?
    private let isRunning: Bool
    private(set) var sentTexts: [String] = []
    private(set) var pastedTexts: [String] = []
    private(set) var focusRequestCount = 0
    private(set) var copySelectionCount = 0
    private(set) var pasteCount = 0
    private(set) var selectAllCount = 0
    private(set) var clearCount = 0
    private(set) var resetCount = 0
    private(set) var terminateCount = 0

    init(selection: String? = nil, isRunning: Bool = false) {
        self.selection = selection
        self.isRunning = isRunning
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

    func pasteText(_ text: String) {
        pastedTexts.append(text)
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
        isRunning
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
