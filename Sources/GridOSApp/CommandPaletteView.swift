import CommandIntelligence
import RenderCore
import SwiftUI

struct CommandPaletteView: View {
    let theme: VisualTheme
    let selectedTextProvider: @MainActor () -> String?
    let workingDirectoryProvider: @MainActor () -> String?
    let onClose: () -> Void
    let onOpenCommandIntelligenceSettings: () -> Void
    let onInsertCommand: @MainActor (String) -> Void
    let onRunCommand: @MainActor (String) -> Void
    let onSendRequest: @MainActor (CommandContextPreview) async -> CommandIntelligenceServiceResult

    @State private var selectedFlow: CommandPaletteFlow = .suggestCommand
    @State private var prompt = ""
    @State private var pastedOutput = ""
    @State private var failedCommand = ""
    @State private var failedOutput = ""
    @State private var preview: CommandContextPreview?
    @State private var lastSubmittedPreview: CommandContextPreview?
    @State private var serviceResult: CommandIntelligenceServiceResult?
    @State private var selectionFailure: CommandIntelligenceSelectionFailure?
    @State private var isSending = false
    @State private var pendingRunCommand: ClassifiedGeneratedCommand?
    @State private var isRunConfirmationPresented = false
    @FocusState private var isPromptFocused: Bool

    private let contextBuilder = CommandContextBuilder()

    init(
        theme: VisualTheme,
        selectedTextProvider: @escaping @MainActor () -> String? = { nil },
        workingDirectoryProvider: @escaping @MainActor () -> String? = { nil },
        onClose: @escaping () -> Void,
        onOpenCommandIntelligenceSettings: @escaping () -> Void,
        onInsertCommand: @escaping @MainActor (String) -> Void = { _ in },
        onRunCommand: @escaping @MainActor (String) -> Void = { _ in },
        onSendRequest: @escaping @MainActor (CommandContextPreview) async -> CommandIntelligenceServiceResult = { _ in
            .failure(.providerError())
        }
    ) {
        self.theme = theme
        self.selectedTextProvider = selectedTextProvider
        self.workingDirectoryProvider = workingDirectoryProvider
        self.onClose = onClose
        self.onOpenCommandIntelligenceSettings = onOpenCommandIntelligenceSettings
        self.onInsertCommand = onInsertCommand
        self.onRunCommand = onRunCommand
        self.onSendRequest = onSendRequest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .background(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))

            VStack(alignment: .leading, spacing: 16) {
                intelligenceBriefing

                Picker("Flow", selection: $selectedFlow) {
                    ForEach(CommandPaletteFlow.allCases) { flow in
                        Text(flow.title)
                            .tag(flow)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(preview != nil || serviceResult != nil || isSending)
                .accessibilityLabel("Command Intelligence flow")

                if isSending {
                    loadingContent
                } else if let serviceResult {
                    resultContent(serviceResult)
                } else if let preview {
                    previewContent(preview)
                } else {
                    composeContent
                }
            }
            .padding(16)
        }
        .frame(maxWidth: 780, maxHeight: 660)
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
        .alert("Run exactly this command?", isPresented: $isRunConfirmationPresented) {
            Button("Run Command") {
                if let pendingRunCommand {
                    onRunCommand(pendingRunCommand.command.command)
                }
                self.pendingRunCommand = nil
            }

            Button("Cancel", role: .cancel) {
                pendingRunCommand = nil
            }
        } message: {
            Text(pendingRunCommand?.command.command ?? "")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Command-K")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.94))

                Text(headerSubtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.80))
            }

            Spacer(minLength: 16)

            PaletteHeaderBadge(label: "policy", value: "insert-first", theme: theme)
            PaletteHeaderBadge(label: "context", value: "previewed", theme: theme)

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

    private var intelligenceBriefing: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(briefingTitle)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.94))

                Spacer(minLength: 12)

                Text("LOCAL GUARDRAILS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.78))
            }

            Text(briefingSubtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            if preview == nil && serviceResult == nil && !isSending {
                examplePromptRow
            }
        }
        .padding(14)
        .background(Color(theme.palette.primaryAccent).opacity(0.045))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(max(0.18, theme.panel.borderOpacity)), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var briefingTitle: String {
        switch selectedFlow {
        case .suggestCommand:
            "Prepare the next shell move."
        case .explainOutput:
            "Turn terminal output into a diagnosis."
        case .fixFailedCommand:
            "Repair the failed command path."
        }
    }

    private var briefingSubtitle: String {
        switch selectedFlow {
        case .suggestCommand:
            "Describe intent. gridOS previews exactly what context will leave the app before asking a provider."
        case .explainOutput:
            "Select or paste output. gridOS summarizes meaning without running anything."
        case .fixFailedCommand:
            "Paste the command and failure. gridOS prepares a fix, then local policy decides whether it can run."
        }
    }

    private var examplePromptRow: some View {
        HStack(spacing: 8) {
            ForEach(examplePrompts, id: \.title) { example in
                Button(example.title) {
                    applyExamplePrompt(example)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.88))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(theme.palette.background).opacity(0.42))
                .overlay {
                    Capsule()
                        .stroke(Color(theme.palette.primaryAccent).opacity(0.18), lineWidth: 1)
                        .accessibilityHidden(true)
                }
                .clipShape(Capsule())
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var examplePrompts: [PaletteExamplePrompt] {
        switch selectedFlow {
        case .suggestCommand:
            [
                PaletteExamplePrompt(title: "Find large files", value: "Find the largest files in this project without deleting anything."),
                PaletteExamplePrompt(title: "Explain git state", value: "Show me the safest commands to inspect this repo before committing."),
                PaletteExamplePrompt(title: "Free a port", value: "Find what is using a local port and prepare a safe stop command.")
            ]
        case .explainOutput:
            [
                PaletteExamplePrompt(title: "Summarize error", value: "Paste terminal output below and explain the likely cause."),
                PaletteExamplePrompt(title: "Find blocker", value: "Identify the single most important failure in this output."),
                PaletteExamplePrompt(title: "Next check", value: "Tell me the next read-only command I should run.")
            ]
        case .fixFailedCommand:
            [
                PaletteExamplePrompt(title: "Safer retry", value: "Prepare a safer retry for this failed command."),
                PaletteExamplePrompt(title: "Missing tool", value: "Check whether this failure is a missing tool or a bad path."),
                PaletteExamplePrompt(title: "Permission issue", value: "Diagnose whether this is a permission problem.")
            ]
        }
    }

    private var headerSubtitle: String {
        if isSending {
            return "Sending the approved context to the configured provider."
        }

        if serviceResult != nil {
            return "Review the result before inserting or running anything."
        }

        return preview == nil ? selectedFlow.subtitle : "Preview the redacted context before sending."
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

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView()
                .controlSize(.small)

            Text("Sending Request")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.88))

            Text("The terminal remains available. No command will be inserted or run from a provider response.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.82))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func resultContent(_ result: CommandIntelligenceServiceResult) -> some View {
        switch result {
        case .completion(let completion):
            completionContent(completion)
        case .failure(let failure):
            failureContent(failure)
        }
    }

    private func completionContent(_ completion: CommandIntelligenceCompletion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    resultHero(completion)

                    if completion.commands.isEmpty {
                        readOnlyExplanationContent(completion)
                    } else {
                        if completion.commands.count > 1 {
                            resultSection(
                                "Execution order",
                                "\(completion.commands.count) candidate commands returned. Review each local risk label before inserting anything."
                            )
                        }

                        ForEach(completion.commands.indices, id: \.self) { index in
                            generatedCommandContent(completion.commands[index], index: index)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 12) {
                Button("Edit Context") {
                    closeResult()
                }

                Spacer(minLength: 16)

                Button("New Request") {
                    closeResult()
                }
            }
        }
    }

    private func readOnlyExplanationContent(_ completion: CommandIntelligenceCompletion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Diagnosis")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.92))

                Spacer(minLength: 10)

                resultBadge("READ ONLY", tint: Color(theme.palette.statusAccent))
            }

            resultSection("Meaning", completion.explanation)
            resultSection("Likely cause", "Review the selected or pasted output above; gridOS intentionally generated no command for this response.")
            resultSection("Next check", "Continue in the terminal, or switch to Fix Failed Command if you want a concrete repair step.")
        }
        .padding(14)
        .background(Color(theme.palette.background).opacity(0.40))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(theme.palette.statusAccent).opacity(0.34), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func generatedCommandContent(_ classifiedCommand: ClassifiedGeneratedCommand, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Plan \(index + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.74))

                    Text(policyHeadline(for: classifiedCommand.localRisk.policy))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.94))
                }

                Spacer(minLength: 12)

                riskBadge(classifiedCommand.localRisk)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(classifiedCommand.command.command)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.94))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.black.opacity(0.24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color(theme.palette.primaryAccent).opacity(0.16), lineWidth: 1)
                            .accessibilityHidden(true)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(policyInstruction(for: classifiedCommand.localRisk.policy))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.76))
            }

            resultSection("Why this command", classifiedCommand.command.explanation)
            resultSection("Working directory", classifiedCommand.command.workingDirectoryAssumption, monospaced: true)
            resultSection("Context used", contextUsedText(classifiedCommand.command.contextUsed))
            riskContent(classifiedCommand.localRisk)

            HStack(spacing: 12) {
                Button(insertActionLabel(for: classifiedCommand.localRisk.policy)) {
                    onInsertCommand(classifiedCommand.command.command)
                }
                .keyboardShortcut(.defaultAction)

                if classifiedCommand.localRisk.policy == .canRun {
                    Button("Run Command") {
                        onRunCommand(classifiedCommand.command.command)
                    }
                } else if classifiedCommand.localRisk.policy == .requiresConfirmation {
                    Button("Run Command") {
                        pendingRunCommand = classifiedCommand
                        isRunConfirmationPresented = true
                    }
                }
            }
            .accessibilityElement(children: .contain)
        }
        .padding(14)
        .background(Color(theme.palette.background).opacity(0.42))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(riskBorderColor(classifiedCommand.localRisk).opacity(0.64), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func riskContent(_ risk: CommandRiskAssessment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Local risk label")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.72))

            Text("\(risk.level.displayName): \(risk.reason)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(riskTextColor(risk))
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

    private func failureContent(_ failure: CommandIntelligenceFailure) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(commandPaletteFailureTitle(failure))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.94))

                    Spacer(minLength: 10)

                    resultBadge("RECOVERY", tint: Color(theme.palette.statusAccent))
                }

                Text("Command-K did not insert or run anything.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.92))

                resultSection("What happened", failure.message)
                resultSection("Next move", failure.recoveryAction ?? "Edit the context and try again.")
            }
            .padding(14)
            .background(Color(theme.palette.background).opacity(0.40))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(theme.palette.statusAccent).opacity(0.34), lineWidth: 1)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button("Edit Context") {
                    closeResult()
                }

                Spacer(minLength: 16)

                if failure.recoveryAction == "Open Command Intelligence Settings" {
                    Button("Open Command Intelligence Settings") {
                        onOpenCommandIntelligenceSettings()
                    }
                } else if failure.recoveryAction == "Retry Request" {
                    Button("Retry Request") {
                        retryRequest()
                    }
                    .disabled(lastSubmittedPreview == nil)
                }
            }
        }
    }

    private func commandPaletteFailureTitle(_ failure: CommandIntelligenceFailure) -> String {
        switch failure {
        case .noProviderKey:
            "Provider not configured"
        case .offline:
            "Provider unreachable"
        case .rateLimited:
            "Provider is busy"
        case .redactionBlocked:
            "Context needs review"
        case .unsupportedSelection:
            "Selection unavailable"
        case .cancelledBeforeSend:
            failure.title
        case .providerError, .providerRefusal, .invalidProviderResponse, .truncatedResponse:
            "Command intelligence is unavailable"
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
                    previewHeader(preview)
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

    private func resultHero(_ completion: CommandIntelligenceCompletion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plan ready")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.96))

                    Text(completion.flow.displayTitle)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.78))
                }

                Spacer(minLength: 12)

                resultBadge(commandCountText(completion.commands.count), tint: Color(theme.palette.primaryAccent))
            }

            Text(completion.summary)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)

            if let requestID = completion.requestID, !requestID.isEmpty {
                Text("Request \(requestID)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.56))
                    .textSelection(.enabled)
            }
        }
        .padding(14)
        .background(Color(theme.palette.primaryAccent).opacity(0.052))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(max(0.20, theme.panel.borderOpacity)), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func previewHeader(_ preview: CommandContextPreview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Context review")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.94))

                Spacer(minLength: 10)

                resultBadge(preview.canSend ? "READY TO SEND" : "BLOCKED", tint: preview.canSend ? Color(theme.palette.primaryAccent) : Color(theme.palette.statusAccent))
            }

            Text("This is the exact redacted context gridOS will send. Nothing leaves the app until you approve it.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(theme.palette.background).opacity(0.36))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(0.22), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func resultSection(_ label: String, _ value: String, monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.72))

            Text(value.isEmpty ? "None" : value)
                .font(.system(size: 12, weight: .regular, design: monospaced ? .monospaced : .default))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.90))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private func resultBadge(_ label: String, tint: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(tint.opacity(0.92))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10))
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.26), lineWidth: 1)
                    .accessibilityHidden(true)
            }
            .clipShape(Capsule())
    }

    private func riskBadge(_ risk: CommandRiskAssessment) -> some View {
        resultBadge(risk.level.displayName.uppercased(), tint: riskBorderColor(risk))
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

    private func contextUsedText(_ contextUsed: [CommandContextSource]) -> String {
        if contextUsed.isEmpty {
            return "None"
        }

        return contextUsed.map(\.previewLabel).joined(separator: ", ")
    }

    private func insertActionLabel(for policy: CommandRunPolicy) -> String {
        switch policy {
        case .canRun, .requiresConfirmation:
            "Insert Command"
        case .insertOnly:
            "Insert for Review"
        }
    }

    private func policyHeadline(for policy: CommandRunPolicy) -> String {
        switch policy {
        case .canRun:
            "Ready for direct run"
        case .requiresConfirmation:
            "Run only after confirmation"
        case .insertOnly:
            "Insert-only safeguard"
        }
    }

    private func policyInstruction(for policy: CommandRunPolicy) -> String {
        switch policy {
        case .canRun:
            "Local policy allows direct run, but inserting first keeps the terminal in control."
        case .requiresConfirmation:
            "gridOS will ask before running this command because it mutates local project state."
        case .insertOnly:
            "gridOS will not run this automatically. Insert it, inspect it, then decide in the shell."
        }
    }

    private func commandCountText(_ commandCount: Int) -> String {
        if commandCount == 0 {
            return "DIAGNOSIS"
        }

        if commandCount == 1 {
            return "1 COMMAND"
        }

        return "\(commandCount) COMMANDS"
    }

    private func riskTextColor(_ risk: CommandRiskAssessment) -> Color {
        switch risk.level {
        case .low:
            Color(theme.palette.primaryAccent).opacity(0.90)
        case .medium, .unknown:
            Color(theme.palette.statusAccent).opacity(0.94)
        case .high:
            .red.opacity(0.92)
        }
    }

    private func riskBorderColor(_ risk: CommandRiskAssessment) -> Color {
        switch risk.level {
        case .low:
            Color(theme.palette.primaryAccent)
        case .medium, .unknown:
            Color(theme.palette.statusAccent)
        case .high:
            .red
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
        serviceResult = nil

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
    private func closeResult() {
        serviceResult = nil
        lastSubmittedPreview = nil
        preview = nil
        isPromptFocused = true
    }

    @MainActor
    private func sendRequest() {
        guard let preview, preview.canSend else {
            return
        }

        sendPreview(preview)
    }

    @MainActor
    private func retryRequest() {
        guard let lastSubmittedPreview else {
            return
        }

        sendPreview(lastSubmittedPreview)
    }

    @MainActor
    private func sendPreview(_ preview: CommandContextPreview) {
        Task { @MainActor in
            isSending = true
            serviceResult = nil
            lastSubmittedPreview = preview
            let result = await onSendRequest(preview)
            self.preview = nil
            serviceResult = result
            isSending = false
        }
    }

    @MainActor
    private func resetComposeState() {
        preview = nil
        lastSubmittedPreview = nil
        serviceResult = nil
        selectionFailure = nil
        pendingRunCommand = nil
        isRunConfirmationPresented = false
        isPromptFocused = true
    }

    @MainActor
    private func applyExamplePrompt(_ example: PaletteExamplePrompt) {
        switch selectedFlow {
        case .suggestCommand:
            prompt = example.value
        case .explainOutput:
            pastedOutput = example.value
        case .fixFailedCommand:
            failedOutput = example.value
        }

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

private struct PaletteHeaderBadge: View {
    let label: String
    let value: String
    let theme: VisualTheme

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.58))

            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.78))
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PaletteExamplePrompt: Equatable {
    let title: String
    let value: String
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

private extension CommandIntelligenceFlow {
    var displayTitle: String {
        switch self {
        case .suggestCommand:
            "Suggested command"
        case .explainOutput:
            "Output diagnosis"
        case .failedCommandHelp:
            "Failed command repair"
        }
    }
}

private extension CommandRiskLevel {
    var displayName: String {
        switch self {
        case .low:
            "Low risk"
        case .medium:
            "Medium risk"
        case .high:
            "High risk"
        case .unknown:
            "Unknown risk"
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
