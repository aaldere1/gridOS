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
    private let isActive: Bool
    private let onActivity: ActivityHandler
    private let interactionController: TerminalInteractionController?

    public init(
        paneID: TerminalPaneID = "primary",
        configuration: TerminalSessionConfiguration = .default,
        isActive: Bool = true,
        interactionController: TerminalInteractionController? = nil,
        onActivity: @escaping ActivityHandler = { _, _ in }
    ) {
        self.paneID = paneID
        self.configuration = configuration
        self.isActive = isActive
        self.interactionController = interactionController
        self.onActivity = onActivity
    }

    @MainActor public func makeCoordinator() -> Coordinator {
        Coordinator(
            paneID: paneID,
            configuration: configuration,
            isActive: isActive,
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

        context.coordinator.update(configuration: configuration, isActive: isActive, terminalView: terminalView)
    }

    @MainActor public static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.shutdown()
    }

    @MainActor
    public final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        private let paneID: TerminalPaneID
        private var configuration: TerminalSessionConfiguration
        private var isActive: Bool
        private let interactionController: TerminalInteractionController?
        private let onActivity: ActivityHandler
        private var state = TerminalSessionState.idle
        private var outputFlushScheduled = false
        private var pendingOutputBytes = 0
        private var terminalView: LocalProcessTerminalView?

        init(
            paneID: TerminalPaneID,
            configuration: TerminalSessionConfiguration,
            isActive: Bool,
            interactionController: TerminalInteractionController?,
            onActivity: @escaping ActivityHandler
        ) {
            self.paneID = paneID
            self.configuration = configuration
            self.isActive = isActive
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
                gridOSTerminalView.shouldAutoFocus = isActive
                gridOSTerminalView.activityHandler = { [weak self] event in
                    self?.recordActivity(event)
                }
            }
            configure(terminalView)
            startShell(in: terminalView)
        }

        func update(configuration: TerminalSessionConfiguration, isActive: Bool, terminalView: LocalProcessTerminalView) {
            let previousConfiguration = self.configuration
            let wasActive = self.isActive
            self.configuration = configuration
            self.isActive = isActive

            if let gridOSTerminalView = terminalView as? GridOSTerminalView {
                gridOSTerminalView.shouldAutoFocus = isActive
            }

            if isActive, !wasActive {
                focusAfterRender(terminalView)
            }

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

            if isActive {
                focusAfterRender(terminalView)
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

        private func focusAfterRender(_ terminalView: LocalProcessTerminalView) {
            let delays: [TimeInterval] = [0, 0.05, 0.20]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak terminalView] in
                    guard let self,
                          self.isActive,
                          let terminalView else {
                        return
                    }

                    terminalView.window?.makeFirstResponder(terminalView)
                }
            }
        }
    }
}

@MainActor
private final class GridOSTerminalView: LocalProcessTerminalView {
    var activityHandler: ((TerminalActivityEvent) -> Void)?
    var shouldAutoFocus = true
    private var focusMouseMonitor: Any?
    private var workspaceShortcutMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            removeEventMonitors()
            return
        }

        installFocusMouseMonitorIfNeeded()
        installWorkspaceShortcutMonitorIfNeeded()

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            if self.shouldAutoFocus {
                self.window?.makeFirstResponder(self)
            }
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if handleWorkspaceKeyEquivalent(event) {
            return true
        }

        if super.performKeyEquivalent(with: event) {
            return true
        }

        return handlePasteboardKeyEquivalent(event)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            removeEventMonitors()
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

    private func installWorkspaceShortcutMonitorIfNeeded() {
        guard workspaceShortcutMonitor == nil else {
            return
        }

        workspaceShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  let window = self.window,
                  event.window === window else {
                return event
            }

            guard self.shouldHandleTerminalKeyEquivalent(in: window) else {
                return event
            }

            if self.handleWorkspaceKeyEquivalent(event) {
                return nil
            }

            if self.handlePasteboardKeyEquivalent(event) {
                return nil
            }

            return event
        }
    }

    private func shouldHandleTerminalKeyEquivalent(in window: NSWindow) -> Bool {
        if window.firstResponder === self {
            return true
        }

        guard let responderView = window.firstResponder as? NSView else {
            return false
        }

        return responderView.isDescendant(of: self)
    }

    private func removeEventMonitors() {
        removeFocusMouseMonitor()
        removeWorkspaceShortcutMonitor()
    }

    private func removeFocusMouseMonitor() {
        guard let focusMouseMonitor else {
            return
        }

        NSEvent.removeMonitor(focusMouseMonitor)
        self.focusMouseMonitor = nil
    }

    private func removeWorkspaceShortcutMonitor() {
        guard let workspaceShortcutMonitor else {
            return
        }

        NSEvent.removeMonitor(workspaceShortcutMonitor)
        self.workspaceShortcutMonitor = nil
    }

    private func emitFocusActivity() {
        window?.makeFirstResponder(self)
        activityHandler?(.focused)
    }

    private func emitActivity(_ event: TerminalActivityEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.activityHandler?(event)
        }
    }

    private func emitActivityImmediately(_ event: TerminalActivityEvent) {
        activityHandler?(event)
    }

    private func handlePasteboardKeyEquivalent(_ event: NSEvent) -> Bool {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifierFlags == .command,
              let key = event.charactersIgnoringModifiers?.lowercased() else {
            return false
        }

        switch key {
        case "a":
            emitActivityImmediately(.selectAllRequested)
            return true
        case "c":
            emitActivityImmediately(.copyRequested)
            return true
        case "v":
            emitActivityImmediately(.pasteRequested)
            return true
        default:
            return false
        }
    }

    private func handleWorkspaceKeyEquivalent(_ event: NSEvent) -> Bool {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifierFlags == .command,
              event.charactersIgnoringModifiers?.lowercased() == "t" else {
            return false
        }

        emitFocusActivity()
        emitActivityImmediately(.splitRightRequested)
        return true
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
