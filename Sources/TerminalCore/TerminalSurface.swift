import AppKit
import SwiftTerm
import SwiftUI

public struct TerminalSurface: NSViewRepresentable {
    public typealias ActivityHandler = @MainActor (TerminalActivityEvent) -> Void

    private let configuration: TerminalSessionConfiguration
    private let onActivity: ActivityHandler

    public init(
        configuration: TerminalSessionConfiguration = .default,
        onActivity: @escaping ActivityHandler = { _ in }
    ) {
        self.configuration = configuration
        self.onActivity = onActivity
    }

    @MainActor public func makeCoordinator() -> Coordinator {
        Coordinator(configuration: configuration, onActivity: onActivity)
    }

    @MainActor public func makeNSView(context: Context) -> NSView {
        let terminal = GridOSTerminalView(frame: .zero)
        context.coordinator.attach(terminal)
        return terminal
    }

    @MainActor public func updateNSView(_ nsView: NSView, context: Context) {}

    @MainActor public static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.shutdown()
    }

    @MainActor
    public final class Coordinator: NSObject, @MainActor LocalProcessTerminalViewDelegate {
        private let configuration: TerminalSessionConfiguration
        private let onActivity: ActivityHandler
        private var state = TerminalSessionState.idle
        private var outputFlushScheduled = false
        private var pendingOutputBytes = 0
        private weak var terminalView: LocalProcessTerminalView?

        init(configuration: TerminalSessionConfiguration, onActivity: @escaping ActivityHandler) {
            self.configuration = configuration
            self.onActivity = onActivity
            super.init()
            registerCommandObservers()
        }

        func attach(_ terminalView: LocalProcessTerminalView) {
            self.terminalView = terminalView
            if let gridOSTerminalView = terminalView as? GridOSTerminalView {
                gridOSTerminalView.activityHandler = { [weak self] event in
                    self?.recordActivity(event)
                }
            }
            configure(terminalView)
            startShell(in: terminalView)
        }

        func shutdown() {
            terminalView?.terminate()
            state = .terminated(exitCode: nil)
            removeCommandObservers()
        }

        public func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            recordActivity(.resized(columns: newCols, rows: newRows))
        }

        public func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            recordActivity(.titleChanged(title))
        }

        public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            recordActivity(.workingDirectoryChanged(directory))
        }

        public func processTerminated(source: TerminalView, exitCode: Int32?) {
            state = .terminated(exitCode: exitCode)
            recordActivity(.processTerminated(exitCode: exitCode))
        }

        private func configure(_ terminalView: LocalProcessTerminalView) {
            terminalView.processDelegate = self
            terminalView.autoresizingMask = [.width, .height]
            terminalView.wantsLayer = true

            let foreground = NSColor(calibratedRed: 0.78, green: 0.91, blue: 0.92, alpha: 1)
            let background = NSColor(calibratedRed: 0.015, green: 0.020, blue: 0.024, alpha: 1)

            terminalView.nativeForegroundColor = foreground
            terminalView.nativeBackgroundColor = background
            terminalView.layer?.backgroundColor = background.cgColor
            terminalView.caretColor = .systemCyan
            terminalView.font = resolvedFont()
            terminalView.getTerminal().setCursorStyle(.steadyBlock)

            do {
                try terminalView.setUseMetal(false)
            } catch {
                // SwiftTerm's text renderer is the stable Phase 1 path. A failure here should not block shell launch.
            }
        }

        private func startShell(in terminalView: LocalProcessTerminalView) {
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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

        private func registerCommandObservers() {
            NotificationCenter.default.addObserver(self, selector: #selector(copyCommand), name: .gridOSTerminalCopy, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(pasteCommand), name: .gridOSTerminalPaste, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(clearCommand), name: .gridOSTerminalClear, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(resetCommand), name: .gridOSTerminalReset, object: nil)
        }

        private func removeCommandObservers() {
            NotificationCenter.default.removeObserver(self)
        }

        private func recordActivity(_ event: TerminalActivityEvent) {
            switch event {
            case .output(let byteCount):
                pendingOutputBytes += byteCount
                scheduleOutputFlush()
            default:
                onActivity(event)
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

            onActivity(.output(byteCount: byteCount))
        }

        @objc private func copyCommand() {
            terminalView?.copy(self)
        }

        @objc private func pasteCommand() {
            terminalView?.paste(self)
        }

        @objc private func clearCommand() {
            terminalView?.sendControlByte(12)
        }

        @objc private func resetCommand() {
            terminalView?.getTerminal().resetToInitialState()
            terminalView?.needsDisplay = true
        }
    }
}

@MainActor
private final class GridOSTerminalView: LocalProcessTerminalView {
    var activityHandler: ((TerminalActivityEvent) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.window?.makeFirstResponder(self)
        }
    }

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        emitActivity(.input(byteCount: data.count))
        super.send(source: source, data: data)
    }

    override func dataReceived(slice: ArraySlice<UInt8>) {
        emitActivity(.output(byteCount: slice.count))
        super.dataReceived(slice: slice)
    }

    private func emitActivity(_ event: TerminalActivityEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.activityHandler?(event)
        }
    }
}

@MainActor
private extension LocalProcessTerminalView {
    func sendControlByte(_ byte: UInt8) {
        let bytes = [byte]
        send(source: self, data: bytes[...])
    }

    func sendText(_ text: String) {
        let bytes = Array(text.utf8)
        send(source: self, data: bytes[...])
    }
}
