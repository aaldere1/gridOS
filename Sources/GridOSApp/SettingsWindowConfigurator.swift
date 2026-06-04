import AppKit
import SwiftUI

struct SettingsWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> SettingsWindowHostView {
        SettingsWindowHostView(frame: .zero)
    }

    func updateNSView(_ nsView: SettingsWindowHostView, context: Context) {
        nsView.configureWindowIfAvailable()
    }
}

@MainActor
final class SettingsWindowHostView: NSView {
    private weak var configuredWindow: NSWindow?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindowIfAvailable()
    }

    func configureWindowIfAvailable() {
        guard let window else {
            return
        }

        if configuredWindow === window {
            return
        }

        window.styleMask.insert(.resizable)
        window.minSize = NSSize(width: 560, height: 560)
        window.contentMinSize = NSSize(width: 560, height: 560)
        window.setFrameAutosaveName("gridOS.settings")
        window.standardWindowButton(.zoomButton)?.isEnabled = true
        configuredWindow = window
    }
}
