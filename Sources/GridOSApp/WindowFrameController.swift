import AppKit
import SwiftUI

struct WindowFrameController: NSViewRepresentable {
    let autosaveName: String

    func makeNSView(context: Context) -> WindowFrameHostView {
        let view = WindowFrameHostView(frame: .zero)
        view.configure(autosaveName: autosaveName)
        return view
    }

    func updateNSView(_ nsView: WindowFrameHostView, context: Context) {
        nsView.configure(autosaveName: autosaveName)
    }
}

@MainActor
final class WindowFrameHostView: NSView {
    private var autosaveName: String?

    func configure(autosaveName: String) {
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

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.minSize = NSSize(width: 960, height: 640)
        if autosaveName == "gridOS.main" {
            window.setFrameAutosaveName("gridOS.main")
        } else {
            window.setFrameAutosaveName(autosaveName)
        }
    }
}
