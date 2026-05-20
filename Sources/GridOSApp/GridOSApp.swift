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
            CommandIntelligenceCommands()
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
                let copyTerminalSelection = TerminalCommandCenter.copy
                copyTerminalSelection()
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
            .keyboardShortcut("k", modifiers: [.command, .option])

            Button("Reset") {
                TerminalCommandCenter.reset()
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
        }
    }
}

private struct CommandIntelligenceCommands: Commands {
    var body: some Commands {
        CommandMenu("Command Intelligence") {
            Button("Command Intelligence") {
                CommandIntelligenceCommandCenter.openCommandIntelligence()
            }
            .keyboardShortcut("k", modifiers: [.command])

            Button("Open Command Intelligence Settings") {
                CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
            }
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
