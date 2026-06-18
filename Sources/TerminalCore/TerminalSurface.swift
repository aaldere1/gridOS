import AppKit
import Darwin
import class SwiftTerm.LocalProcessTerminalView
import protocol SwiftTerm.LocalProcessTerminalViewDelegate
import class SwiftTerm.TerminalView
import SwiftUI

public struct TerminalSurface: NSViewRepresentable {
    public typealias ActivityHandler = @MainActor (TerminalPaneID, TerminalActivityEvent) -> Void

    private let paneID: TerminalPaneID
    private let configuration: TerminalSessionConfiguration
    private let onActivity: ActivityHandler
    private let interactionController: TerminalInteractionController?

    public init(
        paneID: TerminalPaneID = "primary",
        configuration: TerminalSessionConfiguration = .default,
        interactionController: TerminalInteractionController? = nil,
        onActivity: @escaping ActivityHandler = { _, _ in }
    ) {
        self.paneID = paneID
        self.configuration = configuration
        self.interactionController = interactionController
        self.onActivity = onActivity
    }

    @MainActor public func makeCoordinator() -> Coordinator {
        Coordinator(
            paneID: paneID,
            configuration: configuration,
            interactionController: interactionController,
            onActivity: onActivity
        )
    }

    @MainActor public func makeNSView(context: Context) -> NSView {
        let terminal = interactionController?.attachedTerminal(as: LocalProcessTerminalView.self)
            ?? GridOSTerminalView(frame: .zero)
        terminal.removeFromSuperview()
        context.coordinator.attach(terminal)
        return terminal
    }

    @MainActor public func updateNSView(_ nsView: NSView, context: Context) {
        guard let terminalView = nsView as? LocalProcessTerminalView else {
            return
        }

        context.coordinator.update(configuration: configuration, terminalView: terminalView)
    }

    @MainActor public static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.shutdown()
    }

    @MainActor
    public final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        private let paneID: TerminalPaneID
        private var configuration: TerminalSessionConfiguration
        private let interactionController: TerminalInteractionController?
        private let onActivity: ActivityHandler
        private var state = TerminalSessionState.idle
        private var outputFlushScheduled = false
        private var pendingOutputBytes = 0
        private var terminalView: LocalProcessTerminalView?

        init(
            paneID: TerminalPaneID,
            configuration: TerminalSessionConfiguration,
            interactionController: TerminalInteractionController?,
            onActivity: @escaping ActivityHandler
        ) {
            self.paneID = paneID
            self.configuration = configuration
            self.interactionController = interactionController
            self.onActivity = onActivity
            super.init()
        }

        func attach(_ terminalView: LocalProcessTerminalView) {
            if let currentTerminalView = self.terminalView {
                if currentTerminalView !== terminalView {
                    currentTerminalView.terminateEnsuringProcessExit()
                }
                interactionController?.detach(currentTerminalView)
            }
            self.terminalView = terminalView
            interactionController?.attach(terminalView)
            if let gridOSTerminalView = terminalView as? GridOSTerminalView {
                gridOSTerminalView.activityHandler = { [weak self] event in
                    self?.recordActivity(event)
                }
            }
            configure(terminalView)
            startShell(in: terminalView)
        }

        func update(configuration: TerminalSessionConfiguration, terminalView: LocalProcessTerminalView) {
            let previousConfiguration = self.configuration
            self.configuration = configuration

            guard previousConfiguration.fontName != configuration.fontName
                || previousConfiguration.fontSize != configuration.fontSize else {
                return
            }

            applyFont(to: terminalView)
            terminalView.needsLayout = true
            terminalView.needsDisplay = true
        }

        func shutdown() {
            guard let terminalView else {
                return
            }

            defer {
                self.terminalView = nil
            }

            if let gridOSTerminalView = terminalView as? GridOSTerminalView {
                gridOSTerminalView.activityHandler = nil
            }

            if let interactionController {
                let shouldKeepControllerOwnedProcess = interactionController.owns(terminalView)
                    && terminalView.process.running
                if !shouldKeepControllerOwnedProcess {
                    interactionController.detach(terminalView)
                }
                if terminalView.processDelegate === self {
                    terminalView.processDelegate = nil
                }
                return
            }

            terminalView.terminateEnsuringProcessExit()
            state = .terminated(exitCode: nil)
        }

        public nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            Task { @MainActor [weak self] in
                self?.recordActivity(.resized(columns: newCols, rows: newRows))
            }
        }

        public nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            Task { @MainActor [weak self] in
                self?.recordActivity(.titleChanged(title))
            }
        }

        public nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            Task { @MainActor [weak self] in
                self?.recordActivity(.workingDirectoryChanged(directory))
            }
        }

        public nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
            Task { @MainActor [weak self] in
                self?.state = .terminated(exitCode: exitCode)
                self?.recordActivity(.processTerminated(exitCode: exitCode))
            }
        }

        private func configure(_ terminalView: LocalProcessTerminalView) {
            terminalView.processDelegate = self
            terminalView.autoresizingMask = [.width, .height]
            terminalView.wantsLayer = true
            terminalView.layer?.masksToBounds = true
            applyAppearance(to: terminalView)
            terminalView.getTerminal().setCursorStyle(.steadyBlock)

            do {
                try terminalView.setUseMetal(false)
            } catch {
                // SwiftTerm's text renderer is the stable Phase 1 path. A failure here should not block shell launch.
            }
        }

        private func applyAppearance(to terminalView: LocalProcessTerminalView) {
            let foreground = NSColor(calibratedRed: 0.78, green: 0.91, blue: 0.92, alpha: 1)
            let background = NSColor(calibratedRed: 0.015, green: 0.020, blue: 0.024, alpha: 1)

            terminalView.nativeForegroundColor = foreground
            terminalView.nativeBackgroundColor = background
            terminalView.layer?.backgroundColor = background.cgColor
            terminalView.caretColor = .systemCyan
            applyFont(to: terminalView)
        }

        private func applyFont(to terminalView: LocalProcessTerminalView) {
            terminalView.font = resolvedFont()
        }

        private func startShell(in terminalView: LocalProcessTerminalView) {
            guard !terminalView.process.running else {
                state = .running
                return
            }

            guard !state.isActive else {
                return
            }

            terminalView.startProcess(
                executable: configuration.shellPath,
                args: configuration.shellArguments,
                execName: configuration.loginShellName,
                currentDirectory: configuration.workingDirectory
            )
            state = .running
            recordActivity(.processStarted(shell: configuration.shellDisplayName))

            DispatchQueue.main.async {
                terminalView.window?.makeFirstResponder(terminalView)
            }

            if let startupCommand = configuration.startupCommand {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak terminalView] in
                    guard let terminalView, terminalView.process.running else {
                        return
                    }

                    terminalView.sendText(startupCommand + "\n")
                }
            }
        }

        private func resolvedFont() -> NSFont {
            if let fontName = configuration.fontName,
               let font = NSFont(name: fontName, size: configuration.fontSize) {
                return font
            }

            return .monospacedSystemFont(ofSize: configuration.fontSize, weight: .regular)
        }

        private func recordActivity(_ event: TerminalActivityEvent) {
            switch event {
            case .output(let byteCount):
                pendingOutputBytes += byteCount
                scheduleOutputFlush()
            default:
                onActivity(paneID, event)
            }
        }

        private func scheduleOutputFlush() {
            guard !outputFlushScheduled else {
                return
            }

            outputFlushScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 30.0) { [weak self] in
                self?.flushOutputActivity()
            }
        }

        private func flushOutputActivity() {
            let byteCount = pendingOutputBytes
            pendingOutputBytes = 0
            outputFlushScheduled = false

            guard byteCount > 0 else {
                return
            }

            onActivity(paneID, .output(byteCount: byteCount))
        }
    }
}

@MainActor
private final class GridOSTerminalView: LocalProcessTerminalView {
    var activityHandler: ((TerminalActivityEvent) -> Void)?
    private var focusMouseMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            removeFocusMouseMonitor()
            return
        }

        installFocusMouseMonitorIfNeeded()

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.window?.makeFirstResponder(self)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if super.performKeyEquivalent(with: event) {
            return true
        }

        return handlePasteboardKeyEquivalent(event)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            removeFocusMouseMonitor()
        }

        super.viewWillMove(toWindow: newWindow)
    }

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        emitActivity(.input(byteCount: data.count))
        super.send(source: source, data: data)
    }

    override func dataReceived(slice: ArraySlice<UInt8>) {
        emitActivity(.output(byteCount: slice.count))
        super.dataReceived(slice: slice)
    }

    private func installFocusMouseMonitorIfNeeded() {
        guard focusMouseMonitor == nil else {
            return
        }

        focusMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self,
                  let window = self.window,
                  event.window === window else {
                return event
            }

            let clickLocation = self.convert(event.locationInWindow, from: nil)
            if self.bounds.contains(clickLocation) {
                self.emitFocusActivity()
            }

            return event
        }
    }

    private func removeFocusMouseMonitor() {
        guard let focusMouseMonitor else {
            return
        }

        NSEvent.removeMonitor(focusMouseMonitor)
        self.focusMouseMonitor = nil
    }

    private func emitFocusActivity() {
        activityHandler?(.focused)
    }

    private func emitActivity(_ event: TerminalActivityEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.activityHandler?(event)
        }
    }

    private func handlePasteboardKeyEquivalent(_ event: NSEvent) -> Bool {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifierFlags == .command,
              let key = event.charactersIgnoringModifiers?.lowercased() else {
            return false
        }

        switch key {
        case "a":
            emitFocusActivity()
            selectAll()
            return true
        case "c":
            emitFocusActivity()
            copy(self)
            return true
        case "v":
            emitFocusActivity()
            paste(self)
            return true
        default:
            return false
        }
    }
}

@MainActor
extension LocalProcessTerminalView: TerminalInteractionControllingTerminal {
    func sendControlByte(_ byte: UInt8) {
        let bytes = [byte]
        send(source: self, data: bytes[...])
    }

    func sendText(_ text: String) {
        let bytes = Array(text.utf8)
        send(source: self, data: bytes[...])
    }

    func focusTerminal() {
        window?.makeFirstResponder(self)
    }

    func copySelection() {
        copy(self)
    }

    func paste() {
        paste(self)
    }

    func pasteText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        paste(self)
    }

    func clear() {
        sendControlByte(12)
    }

    func reset() {
        getTerminal().resetToInitialState()
        needsDisplay = true
    }

    func terminateEnsuringProcessExit() {
        let processIdentifier = process.shellPid
        terminate()

        guard processIdentifier > 0 else {
            return
        }

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
            guard kill(processIdentifier, 0) == 0 else {
                return
            }

            kill(processIdentifier, SIGKILL)
        }
    }

    func isProcessRunning() -> Bool {
        process.running
    }
}
