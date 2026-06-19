import AppKit
import GridOSKit
import Integrations
import SwiftUI
import TerminalCore

@main
struct GridOSApplication: App {
    @NSApplicationDelegateAdaptor(GridOSApplicationDelegate.self) private var appDelegate

    #if DEBUG
    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--phase9-ready-smoke")
            || arguments.contains("--phase9-input-latency-smoke")
            || arguments.contains("--phase9-heavy-output-smoke")
            || arguments.contains("--phase9-frame-pacing-smoke") {
            UserDefaults.standard.set(
                true,
                forKey: GridOSAppPreferences.privacySafetyLaunchAcceptedStorageKey
            )
        }

        if arguments.contains("--phase8-notification-smoke") {
            Phase8MacIntegrationsSmokeCoordinator()
                .startIfRequested(arguments: arguments)
        }

        if arguments.contains("--phase9-ready-smoke") {
            Phase9PerformanceSmokeCoordinator()
                .startIfRequested(arguments: arguments)
        }

        if arguments.contains("--phase11-alpha-smoke") {
            Phase11AlphaSmokeCoordinator.writeHeadlessFallbackIfRequested(arguments: arguments)
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 1180, minHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            AppSettingsCommands()
            SoftwareUpdateCommands()
            TerminalCommands()
            CommandIntelligenceCommands()
            AppearanceCommands()
        }

        // Alpha launch stability: keep MenuBarExtra out of the scene graph until the SwiftUI scene loop is fixed.
    }
}

private struct AppSettingsCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings...") {
                SettingsWindowController.shared.open()
            }
            .keyboardShortcut(",", modifiers: [.command])
        }
    }
}

private struct SoftwareUpdateCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView()
        }
    }
}

private struct TerminalCommands: Commands {
    @ObservedObject private var terminalWorkspaceCommandCenter = TerminalWorkspaceCommandCenter.shared

    var body: some Commands {
        CommandMenu("Terminal") {
            Button("Copy") {
                terminalWorkspaceCommandCenter.copy()
            }

            Button("Paste") {
                terminalWorkspaceCommandCenter.paste()
            }

            Button("Select All") {
                terminalWorkspaceCommandCenter.selectAll()
            }

            Divider()

            Button("New Terminal Pane") {
                terminalWorkspaceCommandCenter.splitRight()
            }
            .keyboardShortcut("t", modifiers: [.command])

            Button("Split Right") {
                terminalWorkspaceCommandCenter.splitRight()
            }
            .keyboardShortcut("d", modifiers: [.command])

            Button("Split Down") {
                terminalWorkspaceCommandCenter.splitDown()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Duplicate Pane") {
                terminalWorkspaceCommandCenter.duplicatePane()
            }
            .keyboardShortcut("d", modifiers: [.command, .option])

            Button("Open Folder...") {
                terminalWorkspaceCommandCenter.openFolder()
            }
            .keyboardShortcut("o", modifiers: [.command])

            Button("Close Pane") {
                terminalWorkspaceCommandCenter.closePane()
            }
            .keyboardShortcut("w", modifiers: [.command])

            Divider()

            Button("Focus Next Pane") {
                terminalWorkspaceCommandCenter.focusNextPane()
            }
            .keyboardShortcut("]", modifiers: [.command])

            Button("Focus Previous Pane") {
                terminalWorkspaceCommandCenter.focusPreviousPane()
            }
            .keyboardShortcut("[", modifiers: [.command])

            Divider()

            Button("Resize Pane Left") {
                terminalWorkspaceCommandCenter.resizePaneLeft()
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command, .control])

            Button("Resize Pane Right") {
                terminalWorkspaceCommandCenter.resizePaneRight()
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .control])

            Button("Resize Pane Up") {
                terminalWorkspaceCommandCenter.resizePaneUp()
            }
            .keyboardShortcut(.upArrow, modifiers: [.command, .control])

            Button("Resize Pane Down") {
                terminalWorkspaceCommandCenter.resizePaneDown()
            }
            .keyboardShortcut(.downArrow, modifiers: [.command, .control])

            Divider()

            Button("Clear") {
                terminalWorkspaceCommandCenter.clear()
            }
            .keyboardShortcut("k", modifiers: [.command, .option])

            Button("Reset") {
                terminalWorkspaceCommandCenter.reset()
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
        }
    }
}

@MainActor
final class GridOSApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppTerminationGuard.shared.shouldTerminate() ? .terminateNow : .terminateCancel
    }
}

private struct CommandIntelligenceCommands: Commands {
    var body: some Commands {
        CommandMenu("AI Command Helper") {
            Button("AI Command Helper") {
                CommandIntelligenceCommandCenter.openCommandIntelligence()
            }
            .keyboardShortcut("k", modifiers: [.command])

            Button("Open AI Command Helper Settings") {
                SettingsWindowController.shared.open(focusCommandIntelligence: true)
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
