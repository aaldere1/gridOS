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
    @FocusedValue(\.terminalWorkspaceCommands) private var terminalWorkspaceCommands

    var body: some Commands {
        CommandMenu("Terminal") {
            Button("Copy") {
                terminalWorkspaceCommands?.copy()
            }
            .keyboardShortcut("c", modifiers: [.command])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Paste") {
                terminalWorkspaceCommands?.paste()
            }
            .keyboardShortcut("v", modifiers: [.command])
            .disabled(terminalWorkspaceCommands == nil)

            Divider()

            Button("Split Right") {
                terminalWorkspaceCommands?.splitRight()
            }
            .keyboardShortcut("d", modifiers: [.command])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Split Down") {
                terminalWorkspaceCommands?.splitDown()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Duplicate Pane") {
                terminalWorkspaceCommands?.duplicatePane()
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Close Pane") {
                terminalWorkspaceCommands?.closePane()
            }
            .keyboardShortcut("w", modifiers: [.command])
            .disabled(terminalWorkspaceCommands == nil)

            Divider()

            Button("Focus Next Pane") {
                terminalWorkspaceCommands?.focusNextPane()
            }
            .keyboardShortcut("]", modifiers: [.command])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Focus Previous Pane") {
                terminalWorkspaceCommands?.focusPreviousPane()
            }
            .keyboardShortcut("[", modifiers: [.command])
            .disabled(terminalWorkspaceCommands == nil)

            Divider()

            Button("Resize Pane Left") {
                terminalWorkspaceCommands?.resizePaneLeft()
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command, .control])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Resize Pane Right") {
                terminalWorkspaceCommands?.resizePaneRight()
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .control])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Resize Pane Up") {
                terminalWorkspaceCommands?.resizePaneUp()
            }
            .keyboardShortcut(.upArrow, modifiers: [.command, .control])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Resize Pane Down") {
                terminalWorkspaceCommands?.resizePaneDown()
            }
            .keyboardShortcut(.downArrow, modifiers: [.command, .control])
            .disabled(terminalWorkspaceCommands == nil)

            Divider()

            Button("Clear") {
                terminalWorkspaceCommands?.clear()
            }
            .keyboardShortcut("k", modifiers: [.command, .option])
            .disabled(terminalWorkspaceCommands == nil)

            Button("Reset") {
                terminalWorkspaceCommands?.reset()
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
            .disabled(terminalWorkspaceCommands == nil)
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
