import GridOSKit
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
            TerminalCommands()
            AppearanceCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

private struct TerminalCommands: Commands {
    var body: some Commands {
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
}

private struct AppearanceCommands: Commands {
    @AppStorage(GridOSAppPreferences.visualModeStorageKey) private var visualModeRawValue = GridOSAppPreferences.defaultVisualModeRawValue

    var body: some Commands {
        CommandMenu("Appearance") {
            Button("Cycle Visual Mode") {
                visualModeRawValue = GridOSAppPreferences.nextVisualModeRawValue(after: visualModeRawValue)
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        }
    }
}
