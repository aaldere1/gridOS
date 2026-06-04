import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func open(focusCommandIntelligence: Bool = false) {
        let window = settingsWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        guard focusCommandIntelligence else {
            return
        }

        DispatchQueue.main.async {
            CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
        }
    }

    private func settingsWindow() -> NSWindow {
        if let window {
            return window
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "gridOS Settings"
        window.minSize = NSSize(width: 560, height: 560)
        window.contentMinSize = NSSize(width: 560, height: 560)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("gridOS.settings")
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        self.window = window
        return window
    }
}
