import RenderCore
import SwiftUI
import TerminalCore

struct TerminalWorkspaceView: View {
    @ObservedObject var workspaceController: TerminalWorkspaceController

    let theme: VisualTheme
    let onActivity: TerminalSurface.ActivityHandler

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
            },
            splitDown: {
                workspaceController.splitActivePane(axis: .vertical)
                workspaceController.focusActivePane()
            },
            duplicatePane: {
                workspaceController.duplicateActivePane()
                workspaceController.focusActivePane()
            },
            closePane: {
                if workspaceController.closeActivePane() {
                    workspaceController.focusActivePane()
                }
            },
            focusNextPane: {
                workspaceController.focusNextPane()
            },
            focusPreviousPane: {
                workspaceController.focusPreviousPane()
            },
            resizePaneLeft: {
                workspaceController.resizeActivePaneLeft()
            },
            resizePaneRight: {
                workspaceController.resizeActivePaneRight()
            },
            resizePaneUp: {
                workspaceController.resizeActivePaneUp()
            },
            resizePaneDown: {
                workspaceController.resizeActivePaneDown()
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
            .background(Color(theme.palette.background).opacity(theme.terminal.backgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: theme.panel.cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture {
                workspaceController.activatePane(paneID)
                workspaceController.focusActivePane()
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
