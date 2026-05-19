import SwiftUI
import TerminalCore

@main
struct GridOSApplication: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Terminal") {
                Button("Copy") {
                    TerminalCommandCenter.copy()
                }
                .keyboardShortcut("c", modifiers: [.command])

                Button("Paste") {
                    TerminalCommandCenter.paste()
                }
                .keyboardShortcut("v", modifiers: [.command])

                Divider()

                Button("Clear") {
                    TerminalCommandCenter.clear()
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("Reset") {
                    TerminalCommandCenter.reset()
                }
                .keyboardShortcut("r", modifiers: [.command, .option])
            }
        }

        Settings {
            SettingsView()
        }
    }
}
