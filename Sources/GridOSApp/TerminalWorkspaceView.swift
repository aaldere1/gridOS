import RenderCore
import SwiftUI
import TerminalCore

struct TerminalWorkspaceView: View {
    @ObservedObject var workspaceController: TerminalWorkspaceController

    let theme: VisualTheme
    let onActivity: TerminalSurface.ActivityHandler
    let onWorkspaceChange: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 8) {
            workspaceToolbar
            render(workspaceController.state.layout)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusedValue(\.terminalWorkspaceCommands, terminalWorkspaceCommands)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Terminal workspace")
    }

    private var workspaceToolbar: some View {
        HStack(spacing: 8) {
            Text("\(workspaceController.state.panesByID.count) \(workspaceController.state.panesByID.count == 1 ? "pane" : "panes")")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.72))
                .accessibilityLabel("Terminal pane count")

            Spacer(minLength: 12)

            terminalToolbarButton(systemName: "rectangle.split.2x1", help: "Split Right") {
                splitRight()
            }

            terminalToolbarButton(systemName: "rectangle.split.1x2", help: "Split Down") {
                splitDown()
            }

            terminalToolbarButton(systemName: "plus.square.on.square", help: "Duplicate Pane") {
                duplicatePane()
            }

            terminalToolbarButton(systemName: "arrow.right.square", help: "Focus Next Pane") {
                focusNextPane()
            }

            terminalToolbarButton(systemName: "xmark.square", help: "Close Pane") {
                closePane()
            }
            .disabled(workspaceController.state.panesByID.count <= 1)
            .opacity(workspaceController.state.panesByID.count <= 1 ? 0.38 : 1)
        }
        .frame(height: 30)
        .padding(.horizontal, 10)
        .background(Color(theme.palette.background).opacity(theme.panel.backgroundOpacity + 0.04))
        .overlay {
            RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(theme.panel.borderOpacity), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous))
    }

    private func terminalToolbarButton(
        systemName: String,
        help: String,
        action: @escaping @MainActor () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 26, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.76))
        .help(help)
        .accessibilityLabel(help)
    }

    private var terminalWorkspaceCommands: TerminalWorkspaceCommandsValue {
        TerminalWorkspaceCommandsValue(
            splitRight: {
                splitRight()
            },
            splitDown: {
                splitDown()
            },
            duplicatePane: {
                duplicatePane()
            },
            closePane: {
                closePane()
            },
            focusNextPane: {
                focusNextPane()
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

    @MainActor
    private func splitRight() {
        workspaceController.splitActivePane(axis: .horizontal)
        workspaceController.focusActivePane()
        onWorkspaceChange()
    }

    @MainActor
    private func splitDown() {
        workspaceController.splitActivePane(axis: .vertical)
        workspaceController.focusActivePane()
        onWorkspaceChange()
    }

    @MainActor
    private func duplicatePane() {
        workspaceController.duplicateActivePane()
        workspaceController.focusActivePane()
        onWorkspaceChange()
    }

    @MainActor
    private func closePane() {
        if workspaceController.closeActivePane() {
            workspaceController.focusActivePane()
            onWorkspaceChange()
        }
    }

    @MainActor
    private func focusNextPane() {
        workspaceController.focusNextPane()
        onWorkspaceChange()
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
