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
            TerminalCommands()
            CommandIntelligenceCommands()
            AppearanceCommands()
        }

        Settings {
            SettingsView()
        }

        // Alpha launch stability: keep MenuBarExtra out of the scene graph until the SwiftUI scene loop is fixed.
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

            Button("Open Folder...") {
                terminalWorkspaceCommands?.openFolder()
            }
            .keyboardShortcut("o", modifiers: [.command])
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

@MainActor
final class GridOSApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppTerminationGuard.shared.shouldTerminate() ? .terminateNow : .terminateCancel
    }
}

private struct CommandIntelligenceCommands: Commands {
    @Environment(\.openSettings) private var openSettings

    var body: some Commands {
        CommandMenu("AI Command Helper") {
            Button("AI Command Helper") {
                CommandIntelligenceCommandCenter.openCommandIntelligence()
            }
            .keyboardShortcut("k", modifiers: [.command])

            Button("Open AI Command Helper Settings") {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
                DispatchQueue.main.async {
                    CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    CommandIntelligenceCommandCenter.openCommandIntelligenceSettings()
                }
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
