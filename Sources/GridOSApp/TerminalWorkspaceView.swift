import AppKit
import CoreTransferable
import RenderCore
import SwiftUI
import TerminalCore
import UniformTypeIdentifiers

struct TerminalWorkspaceView: View {
    @ObservedObject var workspaceController: TerminalWorkspaceController

    let theme: VisualTheme
    let terminalFontSize: Double
    let canDecreaseFontSize: Bool
    let canIncreaseFontSize: Bool
    let onActivity: TerminalSurface.ActivityHandler
    let onWorkspaceChange: @MainActor () -> Void
    let onDecreaseFontSize: @MainActor () -> Void
    let onIncreaseFontSize: @MainActor () -> Void
    let onResetFontSize: @MainActor () -> Void
    @State private var isClosePaneConfirmationPresented = false
    @State private var paneSizes: [TerminalPaneID: CGSize] = [:]
    @State private var paneDropTargetID: TerminalPaneID?

    var body: some View {
        VStack(spacing: 8) {
            workspaceToolbar
            render(workspaceController.state.layout)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusedValue(\.terminalWorkspaceCommands, terminalWorkspaceCommands)
        .background(
            TerminalWorkspaceShortcutBridge(
                onFocusNextPane: {
                    focusNextPane()
                },
                onFocusPreviousPane: {
                    workspaceController.focusPreviousPane()
                    onWorkspaceChange()
                }
            )
        )
        .onChange(of: workspaceController.state.layout.paneIDsInVisualOrder) { _, paneIDs in
            prunePaneSizeState(livePaneIDs: Set(paneIDs))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Terminal workspace")
        .alert("Close this terminal pane?", isPresented: $isClosePaneConfirmationPresented) {
            Button("Close Pane", role: .destructive) {
                closePaneConfirmed()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Closing a pane terminates its shell process. Make sure long-running work, editors, and remote sessions are safe to stop.")
        }
    }

    private var workspaceToolbar: some View {
        HStack(spacing: 8) {
            Text("\(workspaceController.state.panesByID.count) \(workspaceController.state.panesByID.count == 1 ? "pane" : "panes")")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.72))
                .accessibilityLabel("Terminal pane count")

            Spacer(minLength: 12)

            HStack(spacing: 2) {
                terminalToolbarButton(systemName: "textformat.size.smaller", help: "Decrease Terminal Font Size") {
                    onDecreaseFontSize()
                }
                .disabled(!canDecreaseFontSize)
                .opacity(canDecreaseFontSize ? 1 : 0.38)

                Text("\(Int(terminalFontSize.rounded())) pt")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.72))
                    .frame(width: 40)
                    .accessibilityLabel("Terminal font size")
                    .accessibilityValue("\(Int(terminalFontSize.rounded())) points")

                terminalToolbarButton(systemName: "textformat.size.larger", help: "Increase Terminal Font Size") {
                    onIncreaseFontSize()
                }
                .disabled(!canIncreaseFontSize)
                .opacity(canIncreaseFontSize ? 1 : 0.38)

                terminalToolbarButton(systemName: "arrow.counterclockwise", help: "Reset Terminal Font Size") {
                    onResetFontSize()
                }
            }
            .padding(.trailing, 4)

            terminalToolbarButton(systemName: "rectangle.split.2x1", help: "Split Right") {
                splitRight()
            }

            terminalToolbarButton(systemName: "rectangle.split.1x2", help: "Split Down") {
                splitDown()
            }

            terminalToolbarButton(systemName: "plus.square.on.square", help: "Duplicate Pane") {
                duplicatePane()
            }

            terminalToolbarButton(systemName: "folder", help: "Open Folder") {
                openFolder()
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
            openFolder: {
                openFolder()
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
            selectAll: {
                workspaceController.selectAllInActivePane()
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
    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a folder to open in a new gridOS pane."

        guard panel.runModal() == .OK,
              let directory = panel.url?.path else {
            workspaceController.focusActivePane()
            return
        }

        workspaceController.openDirectoryInNewPane(directory)
        workspaceController.focusActivePane()
        onWorkspaceChange()
    }

    @MainActor
    private func closePane() {
        guard workspaceController.isActivePaneProcessRunning() else {
            closePaneConfirmed()
            return
        }

        isClosePaneConfirmationPresented = true
    }

    @MainActor
    private func closePaneConfirmed() {
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

            VStack(spacing: 0) {
                paneHeader(paneID, descriptor: descriptor, isActive: isActive)

                TerminalSurface(
                    paneID: paneID,
                    configuration: descriptor.configuration,
                    interactionController: workspaceController.controller(for: paneID),
                    onActivity: onActivity
                )
                .id(paneID.rawValue)
                .background(Color(theme.palette.background).opacity(theme.terminal.backgroundOpacity))
            }
            .background(Color(theme.palette.background).opacity(theme.terminal.backgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture {
                workspaceController.activatePane(paneID)
                workspaceController.focusActivePane()
                onWorkspaceChange()
            }
            .background(paneSizeReader(for: paneID))
            .dropDestination(for: TerminalPaneDragPayload.self) { payloads, location in
                guard let payload = payloads.first else {
                    return false
                }

                let sourcePaneID = TerminalPaneID(rawValue: payload.paneIDRawValue)
                let placement = paneDropPlacement(for: location, in: paneSizes[paneID] ?? .zero)
                let didMove = workspaceController.movePane(
                    sourcePaneID,
                    relativeTo: paneID,
                    placement: placement
                )
                if didMove {
                    onWorkspaceChange()
                }
                paneDropTargetID = nil
                return didMove
            } isTargeted: { isTargeted in
                if isTargeted {
                    paneDropTargetID = paneID
                } else if paneDropTargetID == paneID {
                    paneDropTargetID = nil
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous)
                    .stroke(
                        Color(theme.palette.primaryAccent)
                            .opacity(isActive ? 0.86 : theme.panel.borderOpacity),
                        lineWidth: isActive ? 2 : 1
                    )
                    .accessibilityHidden(true)
            }
            .overlay {
                if paneDropTargetID == paneID {
                    RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous)
                        .stroke(Color(theme.palette.statusAccent).opacity(0.84), lineWidth: 2)
                        .accessibilityHidden(true)
                }
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
            .clipped()
            .accessibilityLabel("Terminal pane")
            .accessibilityValue(isActive ? "Active pane" : "Inactive pane")
        } else {
            Color.clear
                .accessibilityLabel("Missing terminal pane")
        }
    }

    private func paneHeader(
        _ paneID: TerminalPaneID,
        descriptor: TerminalPaneDescriptor,
        isActive: Bool
    ) -> some View {
        let paneIndex = (workspaceController.state.layout.paneIDsInVisualOrder.firstIndex(of: paneID) ?? 0) + 1
        let directoryName = descriptor.lastWorkingDirectory
            .flatMap { URL(fileURLWithPath: $0).lastPathComponent.isEmpty ? nil : URL(fileURLWithPath: $0).lastPathComponent }
            ?? descriptor.configuration.workingDirectory
                .flatMap { URL(fileURLWithPath: $0).lastPathComponent.isEmpty ? nil : URL(fileURLWithPath: $0).lastPathComponent }
            ?? descriptor.configuration.shellDisplayName

        return HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 18, height: 18)
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(isActive ? 0.88 : 0.56))
                .accessibilityHidden(true)

            Text("PANE \(paneIndex)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(isActive ? 0.92 : 0.58))

            Text(directoryName)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.statusAccent).opacity(isActive ? 0.72 : 0.44))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)

            Circle()
                .fill(Color(theme.palette.primaryAccent).opacity(isActive ? 0.92 : 0.34))
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
        }
        .frame(height: 28)
        .padding(.horizontal, 8)
        .background(Color(theme.palette.background).opacity(isActive ? 0.68 : 0.42))
        .contentShape(Rectangle())
        .draggable(TerminalPaneDragPayload(paneIDRawValue: paneID.rawValue)) {
            paneDragPreview(paneIndex: paneIndex, directoryName: directoryName)
        }
        .help("Drag to rearrange this terminal pane")
        .accessibilityLabel("Terminal pane \(paneIndex)")
        .accessibilityValue(isActive ? "Active, \(directoryName)" : directoryName)
        .onTapGesture {
            workspaceController.activatePane(paneID)
            workspaceController.focusActivePane()
            onWorkspaceChange()
        }
    }

    private func paneDragPreview(paneIndex: Int, directoryName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 13, weight: .semibold))
            Text("PANE \(paneIndex)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            Text(directoryName)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(Color(theme.palette.background).opacity(0.92))
        .foregroundStyle(Color(theme.palette.primaryAccent))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(0.58), lineWidth: 1)
        }
    }

    private func paneSizeReader(for paneID: TerminalPaneID) -> some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    updatePaneSize(proxy.size, for: paneID)
                }
                .onChange(of: proxy.size) { _, newSize in
                    updatePaneSize(newSize, for: paneID)
                }
        }
    }

    @MainActor
    private func updatePaneSize(_ size: CGSize, for paneID: TerminalPaneID) {
        guard paneSizes[paneID] != size else {
            return
        }

        paneSizes[paneID] = size
    }

    @MainActor
    private func prunePaneSizeState(livePaneIDs: Set<TerminalPaneID>) {
        let stalePaneIDs = paneSizes.keys.filter { !livePaneIDs.contains($0) }
        for paneID in stalePaneIDs {
            paneSizes.removeValue(forKey: paneID)
        }

        if let paneDropTargetID, !livePaneIDs.contains(paneDropTargetID) {
            self.paneDropTargetID = nil
        }
    }

    private func paneDropPlacement(for location: CGPoint, in size: CGSize) -> TerminalPanePlacement {
        guard size.width > 0, size.height > 0 else {
            return .after
        }

        let distanceToLeft = max(0, location.x)
        let distanceToRight = max(0, size.width - location.x)
        let distanceToTop = max(0, location.y)
        let distanceToBottom = max(0, size.height - location.y)
        let horizontalDistance = min(distanceToLeft, distanceToRight) / size.width
        let verticalDistance = min(distanceToTop, distanceToBottom) / size.height

        if verticalDistance < horizontalDistance {
            return distanceToTop < distanceToBottom ? .above : .below
        }

        return distanceToLeft < distanceToRight ? .before : .after
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

private struct TerminalPaneDragPayload: Codable, Hashable, Transferable {
    let paneIDRawValue: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .gridOSTerminalPane)
    }
}

private extension UTType {
    static let gridOSTerminalPane = UTType(exportedAs: "com.aaldere1.gridos.terminal-pane")
}

private struct TerminalWorkspaceShortcutBridge: NSViewRepresentable {
    let onFocusNextPane: @MainActor () -> Void
    let onFocusPreviousPane: @MainActor () -> Void

    func makeNSView(context: Context) -> TerminalWorkspaceShortcutView {
        let view = TerminalWorkspaceShortcutView()
        view.onFocusNextPane = onFocusNextPane
        view.onFocusPreviousPane = onFocusPreviousPane
        return view
    }

    func updateNSView(_ nsView: TerminalWorkspaceShortcutView, context: Context) {
        nsView.onFocusNextPane = onFocusNextPane
        nsView.onFocusPreviousPane = onFocusPreviousPane
    }

    static func dismantleNSView(_ nsView: TerminalWorkspaceShortcutView, coordinator: ()) {
        nsView.shutdown()
    }
}

@MainActor
private final class TerminalWorkspaceShortcutView: NSView {
    var onFocusNextPane: (@MainActor () -> Void)?
    var onFocusPreviousPane: (@MainActor () -> Void)?
    private var keyDownMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            removeKeyDownMonitor()
        } else {
            installKeyDownMonitorIfNeeded()
        }
    }

    func shutdown() {
        removeKeyDownMonitor()
        onFocusNextPane = nil
        onFocusPreviousPane = nil
    }

    private func installKeyDownMonitorIfNeeded() {
        guard keyDownMonitor == nil else {
            return
        }

        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  self.window?.isKeyWindow == true else {
                return event
            }

            return self.handleKeyDown(event)
        }
    }

    private func removeKeyDownMonitor() {
        guard let keyDownMonitor else {
            return
        }

        NSEvent.removeMonitor(keyDownMonitor)
        self.keyDownMonitor = nil
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        guard event.keyCode == 48 else {
            return event
        }

        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        switch modifierFlags {
        case .control:
            onFocusNextPane?()
            return nil
        case [.control, .shift]:
            onFocusPreviousPane?()
            return nil
        default:
            return event
        }
    }
}
