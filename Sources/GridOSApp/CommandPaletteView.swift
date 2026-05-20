import CommandIntelligence
import RenderCore
import SwiftUI

struct CommandPaletteView: View {
    let theme: VisualTheme
    let selectedTextProvider: @MainActor () -> String?
    let workingDirectoryProvider: @MainActor () -> String?
    let onClose: () -> Void
    let onOpenCommandIntelligenceSettings: () -> Void
    let onSendRequest: @MainActor (CommandContextPreview) async -> Void

    @State private var selectedFlow: CommandPaletteFlow = .suggestCommand
    @State private var prompt = ""
    @State private var pastedOutput = ""
    @State private var failedCommand = ""
    @State private var failedOutput = ""
    @State private var preview: CommandContextPreview?
    @State private var selectionFailure: CommandIntelligenceSelectionFailure?
    @State private var isSending = false
    @FocusState private var isPromptFocused: Bool

    private let contextBuilder = CommandContextBuilder()

    init(
        theme: VisualTheme,
        selectedTextProvider: @escaping @MainActor () -> String? = { nil },
        workingDirectoryProvider: @escaping @MainActor () -> String? = { nil },
        onClose: @escaping () -> Void,
        onOpenCommandIntelligenceSettings: @escaping () -> Void,
        onSendRequest: @escaping @MainActor (CommandContextPreview) async -> Void = { _ in }
    ) {
        self.theme = theme
        self.selectedTextProvider = selectedTextProvider
        self.workingDirectoryProvider = workingDirectoryProvider
        self.onClose = onClose
        self.onOpenCommandIntelligenceSettings = onOpenCommandIntelligenceSettings
        self.onSendRequest = onSendRequest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .background(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))

            VStack(alignment: .leading, spacing: 16) {
                Picker("Flow", selection: $selectedFlow) {
                    ForEach(CommandPaletteFlow.allCases) { flow in
                        Text(flow.title)
                            .tag(flow)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(preview != nil || isSending)
                .accessibilityLabel("Command Intelligence flow")

                if let preview {
                    previewContent(preview)
                } else {
                    composeContent
                }
            }
            .padding(16)
        }
        .frame(maxWidth: 720, maxHeight: 620)
        .background(Color(theme.palette.background).opacity(max(0.86, theme.panel.backgroundOpacity)))
        .overlay {
            RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(max(0.28, theme.panel.borderOpacity)), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous))
        .shadow(color: .black.opacity(0.34), radius: 28, x: 0, y: 16)
        .accessibilityLabel("Command Intelligence")
        .onAppear {
            isPromptFocused = true
        }
        .onChange(of: selectedFlow) {
            resetComposeState()
        }
        .onExitCommand {
            onClose()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Command Intelligence")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.94))

                Text(preview == nil ? selectedFlow.subtitle : "Preview the redacted context before sending.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.80))
            }

            Spacer(minLength: 16)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.82))
            .accessibilityLabel("Close Command Intelligence")
        }
        .padding(16)
    }

    private var composeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            flowInputContent

            if let selectionFailure {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectionFailure.title)
                        .font(.system(size: 12, weight: .semibold))
                    Text(selectionFailure.message)
                        .font(.system(size: 13, weight: .regular))
                }
                .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.92))
                .accessibilityElement(children: .combine)
            }

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 12) {
                Button("Open Command Intelligence Settings") {
                    onOpenCommandIntelligenceSettings()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.90))
                .accessibilityLabel("Open Command Intelligence Settings")

                Spacer(minLength: 16)

                Button("Preview Context") {
                    buildPreview()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(!canBuildPreview)
            }
        }
    }

    @ViewBuilder
    private var flowInputContent: some View {
        switch selectedFlow {
        case .suggestCommand:
            paletteTextEditor(
                title: "Prompt",
                text: $prompt,
                placeholder: "Describe the command you want.",
                monospaced: false
            )
        case .explainOutput:
            paletteTextEditor(
                title: "Output",
                text: $pastedOutput,
                placeholder: "Select terminal output or paste it here.",
                monospaced: true
            )
        case .fixFailedCommand:
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Failed command")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.78))

                    TextField("Paste the failed command.", text: $failedCommand)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(theme.palette.background).opacity(0.46))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color(theme.palette.primaryAccent).opacity(0.22), lineWidth: 1)
                                .accessibilityHidden(true)
                        }
                }

                paletteTextEditor(
                    title: "Failed output",
                    text: $failedOutput,
                    placeholder: "Paste the failed command and output.",
                    monospaced: true
                )
            }
        }
    }

    private func previewContent(_ preview: CommandContextPreview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    previewRow("Flow", preview.flowName)
                    previewRow("Prompt or failed command", promptOrFailedCommandText(from: preview))
                    previewRow("Working directory", workingDirectoryText(from: preview))
                    previewRow("Selected/pasted output", selectedOutputCountText(from: preview))
                    previewRow("Failed output", failedOutputCountText(from: preview))

                    redactionSummaryContent(preview)

                    if preview.blockedReasons.isEmpty {
                        previewRow("Blocked reasons", "None")
                    } else {
                        previewRow("Blocked reasons", preview.blockedReasons.joined(separator: "\n"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 12) {
                Button("Close Preview") {
                    closePreview()
                }

                Button("Edit Context") {
                    closePreview()
                }

                Spacer(minLength: 16)

                Button(isSending ? "Sending" : "Send Request") {
                    sendRequest()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(preview.canSend == false || isSending)
            }
        }
    }

    private func paletteTextEditor(
        title: String,
        text: Binding<String>,
        placeholder: String,
        monospaced: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.78))

            TextEditor(text: text)
                .font(.system(size: 13, weight: .regular, design: monospaced ? .monospaced : .default))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.92))
                .scrollContentBackground(.hidden)
                .background(Color(theme.palette.background).opacity(0.46))
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.66))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color(theme.palette.primaryAccent).opacity(0.22), lineWidth: 1)
                        .accessibilityHidden(true)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .focused($isPromptFocused)
                .frame(minHeight: 132, maxHeight: 196)
        }
    }

    private func previewRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.72))

            Text(value.isEmpty ? "None" : value)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.90))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))
                .frame(height: 1)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private func redactionSummaryContent(_ preview: CommandContextPreview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Redaction")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.72))

            if preview.redactionSummaries.isEmpty {
                Text("No redactions")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.90))
            } else {
                ForEach(preview.redactionSummaries, id: \.label) { item in
                    Text("\(item.label): \(item.count)")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.92))
                }
            }
        }
    }

    private var canBuildPreview: Bool {
        switch selectedFlow {
        case .suggestCommand:
            !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .explainOutput:
            true
        case .fixFailedCommand:
            !failedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !failedOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    @MainActor
    private func buildPreview() {
        selectionFailure = nil

        guard let input = commandAssistanceInput() else {
            return
        }

        preview = contextBuilder.buildPreview(from: input)
        isPromptFocused = false
    }

    @MainActor
    private func commandAssistanceInput() -> CommandAssistanceInput? {
        switch selectedFlow {
        case .suggestCommand:
            return CommandAssistanceInput(
                flow: .suggestCommand,
                userPrompt: prompt,
                workingDirectory: workingDirectoryProvider()
            )
        case .explainOutput:
            let output = selectedTextProvider() ?? pastedOutput
            guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                selectionFailure = CommandIntelligenceSelectionFailure(
                    title: "Selection unavailable",
                    message: "Paste the output into the field to continue."
                )
                return nil
            }

            return CommandAssistanceInput(
                flow: .explainOutput,
                userPrompt: "Explain terminal output",
                workingDirectory: workingDirectoryProvider(),
                selectedOrPastedOutput: output
            )
        case .fixFailedCommand:
            return CommandAssistanceInput(
                flow: .failedCommandHelp,
                userPrompt: "Fix failed command",
                workingDirectory: workingDirectoryProvider(),
                failedCommand: failedCommand,
                failedCommandOutput: failedOutput
            )
        }
    }

    @MainActor
    private func closePreview() {
        preview = nil
        isPromptFocused = true
    }

    @MainActor
    private func sendRequest() {
        guard let preview, preview.canSend else {
            return
        }

        Task { @MainActor in
            isSending = true
            await onSendRequest(preview)
            isSending = false
        }
    }

    @MainActor
    private func resetComposeState() {
        preview = nil
        selectionFailure = nil
        isPromptFocused = true
    }

    private func promptOrFailedCommandText(from preview: CommandContextPreview) -> String {
        switch preview.flow {
        case .failedCommandHelp:
            return contextText(.failedCommand, in: preview)
        case .suggestCommand, .explainOutput:
            return contextText(.prompt, in: preview)
        }
    }

    private func workingDirectoryText(from preview: CommandContextPreview) -> String {
        contextText(.workingDirectory, in: preview)
    }

    private func selectedOutputCountText(from preview: CommandContextPreview) -> String {
        countText(for: .selectedOutput, in: preview)
    }

    private func failedOutputCountText(from preview: CommandContextPreview) -> String {
        countText(for: .failedOutput, in: preview)
    }

    private func countText(for source: CommandContextSource, in preview: CommandContextPreview) -> String {
        guard let block = preview.contextBlocks.first(where: { $0.source == source }) else {
            return "0 characters"
        }

        return "\(block.characterCount) characters"
    }

    private func contextText(_ source: CommandContextSource, in preview: CommandContextPreview) -> String {
        preview.contextBlocks.first(where: { $0.source == source })?.redactedText ?? ""
    }
}

private enum CommandPaletteFlow: String, CaseIterable, Identifiable {
    case suggestCommand
    case explainOutput
    case fixFailedCommand

    var id: String { rawValue }

    var title: String {
        switch self {
        case .suggestCommand:
            "Suggest Command"
        case .explainOutput:
            "Explain Output"
        case .fixFailedCommand:
            "Fix Failed Command"
        }
    }

    var subtitle: String {
        switch self {
        case .suggestCommand:
            "Describe the terminal action you want to prepare."
        case .explainOutput:
            "Select output when available, or paste output here."
        case .fixFailedCommand:
            "Paste the failed command and output for a focused fix."
        }
    }
}

private struct CommandIntelligenceSelectionFailure: Equatable {
    let title: String
    let message: String
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
