import AppKit
import SwiftTerm
import SwiftUI

public struct TerminalSurface: NSViewRepresentable {
    private let configuration: TerminalSessionConfiguration

    public init(configuration: TerminalSessionConfiguration = .default) {
        self.configuration = configuration
    }

    @MainActor public func makeCoordinator() -> Coordinator {
        Coordinator(configuration: configuration)
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
        private var state = TerminalSessionState.idle
        private weak var terminalView: LocalProcessTerminalView?

        init(configuration: TerminalSessionConfiguration) {
            self.configuration = configuration
            super.init()
            registerCommandObservers()
        }

        func attach(_ terminalView: LocalProcessTerminalView) {
            self.terminalView = terminalView
            configure(terminalView)
            startShell(in: terminalView)
        }

        func shutdown() {
            terminalView?.terminate()
            state = .terminated(exitCode: nil)
            removeCommandObservers()
        }

        public func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        public func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

        public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        public func processTerminated(source: TerminalView, exitCode: Int32?) {
            state = .terminated(exitCode: exitCode)
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
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.window?.makeFirstResponder(self)
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
