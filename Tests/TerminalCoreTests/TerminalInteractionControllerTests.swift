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
}

@MainActor
private final class TerminalInteractionTerminalSpy: TerminalInteractionControllingTerminal {
    private let selection: String?
    private(set) var sentTexts: [String] = []
    private(set) var focusRequestCount = 0

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
}
