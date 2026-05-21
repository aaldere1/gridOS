import RenderCore
import SwiftUI
import TerminalCore

struct TerminalWorkspaceView: View {
    @ObservedObject var workspaceController: TerminalWorkspaceController

    let theme: VisualTheme
    let onActivity: TerminalSurface.ActivityHandler
    let onWorkspaceChange: @MainActor () -> Void

    var body: some View {
        render(workspaceController.state.layout)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .focusedValue(\.terminalWorkspaceCommands, terminalWorkspaceCommands)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Terminal workspace")
    }

    private var terminalWorkspaceCommands: TerminalWorkspaceCommandsValue {
        TerminalWorkspaceCommandsValue(
            splitRight: {
                workspaceController.splitActivePane(axis: .horizontal)
                workspaceController.focusActivePane()
                onWorkspaceChange()
            },
            splitDown: {
                workspaceController.splitActivePane(axis: .vertical)
                workspaceController.focusActivePane()
                onWorkspaceChange()
            },
            duplicatePane: {
                workspaceController.duplicateActivePane()
                workspaceController.focusActivePane()
                onWorkspaceChange()
            },
            closePane: {
                if workspaceController.closeActivePane() {
                    workspaceController.focusActivePane()
                    onWorkspaceChange()
                }
            },
            focusNextPane: {
                workspaceController.focusNextPane()
                onWorkspaceChange()
            },
            focusPreviousPane: {
                workspaceController.focusPreviousPane()
                onWorkspaceChange()
            },
            resizePaneLeft: {
                workspaceController.resizeActivePaneLeft()
                onWorkspaceChange()
            },
            resizePaneRight: {
                workspaceController.resizeActivePaneRight()
                onWorkspaceChange()
            },
            resizePaneUp: {
                workspaceController.resizeActivePaneUp()
                onWorkspaceChange()
            },
            resizePaneDown: {
                workspaceController.resizeActivePaneDown()
                onWorkspaceChange()
            },
            copy: {
                workspaceController.copyActivePaneSelection()
            },
            paste: {
                workspaceController.pasteIntoActivePane()
            },
            clear: {
                workspaceController.clearActivePane()
            },
            reset: {
                workspaceController.resetActivePane()
            }
        )
    }

    private func render(_ layout: TerminalPaneLayout) -> AnyView {
        switch layout {
        case .pane(let paneID):
            return AnyView(pane(paneID))
        case .split(let axis, _, let first, let second):
            switch axis {
            case .horizontal:
                return AnyView(HSplitView {
                    render(first)
                    render(second)
                })
            case .vertical:
                return AnyView(VSplitView {
                    render(first)
                    render(second)
                })
            }
        }
    }

    @ViewBuilder
    private func pane(_ paneID: TerminalPaneID) -> some View {
        if let descriptor = workspaceController.state.panesByID[paneID] {
            let isActive = workspaceController.activePaneID == paneID

            TerminalSurface(paneID: paneID,
                configuration: descriptor.configuration,
                interactionController: workspaceController.controller(for: paneID),
                onActivity: onActivity
            )
            .id(paneID.rawValue)
            .background(Color(theme.palette.background).opacity(theme.terminal.backgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: theme.panel.cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture {
                workspaceController.activatePane(paneID)
                workspaceController.focusActivePane()
                onWorkspaceChange()
            }
            .overlay {
                RoundedRectangle(cornerRadius: theme.panel.cornerRadius, style: .continuous)
                    .stroke(
                        Color(theme.palette.primaryAccent)
                            .opacity(isActive ? 0.86 : theme.panel.borderOpacity),
                        lineWidth: isActive ? 2 : 1
                    )
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .leading) {
                if isActive {
                    Rectangle()
                        .fill(Color(theme.palette.primaryAccent).opacity(0.82))
                        .frame(width: 2)
                        .padding(.vertical, 6)
                        .accessibilityHidden(true)
                }
            }
            .frame(minWidth: 240, minHeight: 160)
            .accessibilityLabel("Terminal pane")
            .accessibilityValue(isActive ? "Active pane" : "Inactive pane")
        } else {
            Color.clear
                .accessibilityLabel("Missing terminal pane")
        }
    }
}

private extension Color {
    init(_ visualColor: VisualColor) {
        self.init(
            red: visualColor.red,
            green: visualColor.green,
            blue: visualColor.blue,
            opacity: visualColor.alpha
        )
    }
}
