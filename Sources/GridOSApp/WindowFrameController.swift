import AppKit
import SwiftUI

struct WindowFrameController: NSViewRepresentable {
    let autosaveName: String
    let shouldClose: @MainActor (NSWindow) -> Bool

    init(
        autosaveName: String,
        shouldClose: @escaping @MainActor (NSWindow) -> Bool = { _ in true }
    ) {
        self.autosaveName = autosaveName
        self.shouldClose = shouldClose
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(shouldClose: shouldClose)
    }

    func makeNSView(context: Context) -> WindowFrameHostView {
        let view = WindowFrameHostView(frame: .zero)
        view.configure(autosaveName: autosaveName, delegate: context.coordinator)
        return view
    }

    func updateNSView(_ nsView: WindowFrameHostView, context: Context) {
        context.coordinator.shouldClose = shouldClose
        nsView.configure(autosaveName: autosaveName, delegate: context.coordinator)
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        var shouldClose: @MainActor (NSWindow) -> Bool

        init(shouldClose: @escaping @MainActor (NSWindow) -> Bool) {
            self.shouldClose = shouldClose
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            MainActor.assumeIsolated {
                shouldClose(sender)
            }
        }
    }
}

@MainActor
final class WindowFrameHostView: NSView {
    private var autosaveName: String?
    private weak var configuredWindow: NSWindow?
    private var configuredAutosaveName: String?
    private weak var configuredDelegate: NSWindowDelegate?

    func configure(autosaveName: String, delegate: NSWindowDelegate) {
        configuredDelegate = delegate
        guard self.autosaveName != autosaveName else {
            configureWindowIfAvailable()
            return
        }

        self.autosaveName = autosaveName

        DispatchQueue.main.async { [weak self] in
            self?.configureWindowIfAvailable()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindowIfAvailable()
    }

    private func configureWindowIfAvailable() {
        guard let window, let autosaveName else {
            return
        }

        if configuredWindow === window, configuredAutosaveName == autosaveName {
            return
        }

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.minSize = NSSize(width: 1180, height: 720)
        window.delegate = configuredDelegate
        if autosaveName == "gridOS.main" {
            window.setFrameAutosaveName("gridOS.main")
        } else {
            window.setFrameAutosaveName(autosaveName)
        }

        configuredWindow = window
        configuredAutosaveName = autosaveName
    }
}
