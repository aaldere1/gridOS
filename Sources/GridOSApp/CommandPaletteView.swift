import CommandIntelligence
import ImageIO
import RenderCore
import SwiftUI
import UniformTypeIdentifiers
import Vision

struct CommandPaletteView: View {
    let theme: VisualTheme
    let selectedTextProvider: @MainActor () -> String?
    let workingDirectoryProvider: @MainActor () -> String?
    let onClose: () -> Void
    let onOpenCommandIntelligenceSettings: () -> Void
    let onInsertCommand: @MainActor (String) -> Void
    let onRunCommand: @MainActor (String) -> Void
    let onSendRequest: @MainActor (CommandContextPreview) async -> CommandIntelligenceServiceResult
    let providerStatus: CommandPaletteProviderStatus

    @State private var selectedFlow: CommandPaletteFlow = .suggestCommand
    @State private var prompt = ""
    @State private var pastedOutput = ""
    @State private var failedCommand = ""
    @State private var failedOutput = ""
    @State private var screenshotAttachments: [ScreenshotAttachment] = []
    @State private var screenshotDropError: String?
    @State private var isScreenshotDropTargeted = false
    @State private var preview: CommandContextPreview?
    @State private var lastSubmittedPreview: CommandContextPreview?
    @State private var serviceResult: CommandIntelligenceServiceResult?
    @State private var selectionFailure: CommandIntelligenceSelectionFailure?
    @State private var isSending = false
    @State private var sendTask: Task<Void, Never>?
    @State private var pendingRunCommand: ClassifiedGeneratedCommand?
    @State private var isRunConfirmationPresented = false
    @FocusState private var isPromptFocused: Bool

    private let contextBuilder = CommandContextBuilder()
    private let panelWidth: CGFloat = 860
    private static let supportedScreenshotDropTypes: [UTType] = [
        .fileURL,
        .image,
        .png,
        .jpeg,
        .tiff,
        .heic
    ]

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
        },
        providerStatus: CommandPaletteProviderStatus = .unknown
    ) {
        self.theme = theme
        self.selectedTextProvider = selectedTextProvider
        self.workingDirectoryProvider = workingDirectoryProvider
        self.onClose = onClose
        self.onOpenCommandIntelligenceSettings = onOpenCommandIntelligenceSettings
        self.onInsertCommand = onInsertCommand
        self.onRunCommand = onRunCommand
        self.onSendRequest = onSendRequest
        self.providerStatus = providerStatus
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .background(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))

            panelContent
        }
        .frame(
            minWidth: 760,
            idealWidth: panelWidth,
            maxWidth: panelWidth,
            minHeight: 620,
            idealHeight: 690,
            maxHeight: 720,
            alignment: .topLeading
        )
        .background(Color(theme.palette.background).opacity(max(0.94, theme.panel.backgroundOpacity)))
        .overlay {
            RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(max(0.28, theme.panel.borderOpacity)), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: min(theme.panel.cornerRadius, 8), style: .continuous))
        .shadow(color: .black.opacity(0.34), radius: 28, x: 0, y: 16)
        .accessibilityLabel("AI Command Helper")
        .onAppear {
            isPromptFocused = true
        }
        .onChange(of: selectedFlow) {
            resetComposeState()
        }
        .onExitCommand {
            onClose()
        }
        .onDisappear {
            cancelSendTask()
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
        .onDrop(
            of: Self.supportedScreenshotDropTypes,
            isTargeted: $isScreenshotDropTargeted
        ) { providers in
            guard isComposeMode else {
                return false
            }

            return handleScreenshotDrop(providers)
        }
    }

    @ViewBuilder
    private var panelContent: some View {
        if isComposeMode {
            VStack(spacing: 0) {
                ScrollView {
                    panelContentStack
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollIndicators(.visible)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Divider()
                    .background(Color(theme.palette.primaryAccent).opacity(theme.panel.separatorOpacity))

                composeFooter
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color(theme.palette.background).opacity(0.88))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            panelContentStack
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var panelContentStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            intelligenceBriefing
            providerSetupNotice

            Picker("Flow", selection: $selectedFlow) {
                ForEach(CommandPaletteFlow.allCases) { flow in
                    Text(flow.title)
                        .tag(flow)
                }
            }
            .pickerStyle(.segmented)
            .disabled(preview != nil || serviceResult != nil || isSending)
            .accessibilityLabel("AI Command Helper flow")

            if isComposeMode {
                flowGuideContent
            }

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
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var isComposeMode: Bool {
        preview == nil && serviceResult == nil && !isSending
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Command Helper")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.94))

                Text(headerSubtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.80))
            }

            Spacer(minLength: 16)

            PaletteHeaderBadge(label: "shortcut", value: "Command-K", theme: theme)
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
            .accessibilityLabel("Close AI Command Helper")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 18)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
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
                PaletteExamplePrompt(title: "Permission denied", value: "cat ./secrets.txt\ncat: ./secrets.txt: Permission denied"),
                PaletteExamplePrompt(title: "Port in use", value: "Error: listen EADDRINUSE: address already in use 127.0.0.1:3000"),
                PaletteExamplePrompt(title: "Build failure", value: "xcodebuild: error: The project named \"gridOS\" does not contain a scheme named \"gridOSApp\".")
            ]
        case .fixFailedCommand:
            [
                PaletteExamplePrompt(
                    title: "Safer retry",
                    value: "Error: listen EADDRINUSE: address already in use 127.0.0.1:3000",
                    failedCommand: "npm run dev"
                ),
                PaletteExamplePrompt(
                    title: "Push rejected",
                    value: "! [rejected] main -> main (non-fast-forward)",
                    failedCommand: "git push origin main"
                ),
                PaletteExamplePrompt(
                    title: "Build destination",
                    value: "xcodebuild: error: Unable to find a destination matching the provided destination specifier.",
                    failedCommand: "xcodebuild -scheme gridOS build"
                )
            ]
        }
    }

    private var headerSubtitle: String {
        if isSending {
            return "Sending approved context to the configured provider."
        }

        if serviceResult != nil {
            return "Review the result before inserting or running anything."
        }

        return preview == nil ? selectedFlow.subtitle : "Preview the redacted context before sending."
    }

    private var composeContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            screenshotDropZone
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var composeFooter: some View {
        HStack(alignment: .center, spacing: 12) {
            Button("Open AI Command Helper Settings") {
                onOpenCommandIntelligenceSettings()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.90))
            .accessibilityLabel("Open AI Command Helper Settings")

            Spacer(minLength: 16)

            Button("Preview What Will Be Sent") {
                buildPreview()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(!canBuildPreview)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var screenshotDropZone: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: isScreenshotDropTargeted ? "photo.badge.plus" : "photo.on.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.90))
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(isScreenshotDropTargeted ? "Drop to attach screenshot" : "Drop screenshots")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.90))

                    Text("gridOS extracts text locally; previewed OCR text and metadata are sent, not image pixels.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                resultBadge("LOCAL OCR", tint: Color(theme.palette.statusAccent))
            }

            if !screenshotAttachments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(screenshotAttachments) { attachment in
                        screenshotAttachmentChip(attachment)
                    }
                }
            }

            if let screenshotDropError {
                Text(screenshotDropError)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(theme.palette.background).opacity(isScreenshotDropTargeted ? 0.52 : 0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    Color(theme.palette.statusAccent).opacity(isScreenshotDropTargeted ? 0.46 : 0.22),
                    style: StrokeStyle(lineWidth: 1, dash: isScreenshotDropTargeted ? [] : [6, 5])
                )
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .dropDestination(for: URL.self) { urls, _ in
            guard isComposeMode else {
                return false
            }

            let fileURLs = urls.filter(\.isFileURL)
            guard !fileURLs.isEmpty else {
                screenshotDropError = "Drop a PNG, JPEG, TIFF, HEIC, or screenshot file."
                return false
            }

            screenshotDropError = nil
            let remainingSlots = ScreenshotAttachmentLimits.maxAttachments - screenshotAttachments.count
            guard remainingSlots > 0 else {
                screenshotDropError = "Remove a screenshot before adding another."
                return false
            }

            fileURLs
                .prefix(remainingSlots)
                .forEach(processDroppedScreenshotURL)
            if fileURLs.count > remainingSlots {
                screenshotDropError = "Attached \(remainingSlots) screenshot\(remainingSlots == 1 ? "" : "s"). Remove one before adding more."
            }
            return true
        } isTargeted: { targeted in
            isScreenshotDropTargeted = targeted
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Drop screenshot area")
    }

    private func screenshotAttachmentChip(_ attachment: ScreenshotAttachment) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: attachment.status.systemImageName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(attachmentTint(for: attachment).opacity(0.92))
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.90))
                    .lineLimit(1)

                Text(attachment.detailText)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.72))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(attachment.status.displayText)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(attachmentTint(for: attachment).opacity(0.84))

            Button {
                removeScreenshotAttachment(attachment.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.72))
            .help("Remove screenshot")
            .accessibilityLabel("Remove \(attachment.displayName)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(theme.palette.primaryAccent).opacity(0.040))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(0.14), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    @ViewBuilder
    private var providerSetupNotice: some View {
        if case .missing(let providerName) = providerStatus {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Provider key required")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.94))

                    Spacer(minLength: 12)

                    resultBadge("SETUP", tint: Color(theme.palette.statusAccent))
                }

                Text("Choose a provider in Settings. Current selection: \(providerName). Until a key is saved, you can inspect the helper, but no request leaves the app.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                Button("Choose Provider") {
                    onOpenCommandIntelligenceSettings()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.94))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(theme.palette.statusAccent).opacity(0.050))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(theme.palette.statusAccent).opacity(0.28), lineWidth: 1)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityElement(children: .contain)
        }
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView()
                .controlSize(.small)

            Text("Sending to Provider")
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

                if failure.recoveryAction == CommandIntelligenceFailure.openSettingsRecoveryAction {
                    Button(CommandIntelligenceFailure.openSettingsRecoveryAction) {
                        onOpenCommandIntelligenceSettings()
                    }
                } else if failure.recoveryAction == CommandIntelligenceFailure.retryRecoveryAction {
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
            "AI Command Helper is unavailable"
        }
    }

    @ViewBuilder
    private var flowInputContent: some View {
        switch selectedFlow {
        case .suggestCommand:
            paletteTextEditor(
                title: "Prompt",
                text: $prompt,
                placeholder: "Example: Find the largest files in this project without deleting anything.",
                monospaced: false
            )
        case .explainOutput:
            paletteTextEditor(
                title: "Output",
                text: $pastedOutput,
                placeholder: "Select terminal output, or paste an error/output snippet here.",
                monospaced: true
            )
        case .fixFailedCommand:
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Failed command")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.78))

                    TextField("Example: npm run dev", text: $failedCommand)
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
                    placeholder: "Paste the error output from the failed command.",
                    monospaced: true
                )
            }
        }
    }

    private var flowGuideContent: some View {
        HStack(alignment: .top, spacing: 12) {
            PaletteGuideItem(label: "Use when", value: selectedFlow.useWhen, theme: theme)
            PaletteGuideItem(label: "You provide", value: selectedFlow.inputHint, theme: theme)
            PaletteGuideItem(label: "You get", value: selectedFlow.resultHint, theme: theme)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func previewContent(_ preview: CommandContextPreview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    previewHeader(preview)
                    previewRow("Flow", preview.flowName)
                    previewRow("Prompt or failed command", promptOrFailedCommandText(from: preview))
                    previewRow("Working directory", workingDirectoryText(from: preview))
                    previewRow("Screenshot attachments", screenshotAttachmentText(from: preview))
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

                Button(isSending ? "Sending" : "Send to Provider") {
                    sendRequest()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(preview.canSend == false || isSending || providerStatus.isMissing)
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
                .frame(minHeight: 144, maxHeight: 210)
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

    private var hasPendingScreenshotAnalysis: Bool {
        screenshotAttachments.contains { $0.status == .processing }
    }

    private var readyScreenshotAttachments: [ScreenshotAttachment] {
        screenshotAttachments.filter { $0.status.isReady }
    }

    private var hasReadyScreenshotContext: Bool {
        !readyScreenshotAttachments.isEmpty
    }

    private var screenshotAttachmentContext: String? {
        guard !readyScreenshotAttachments.isEmpty else {
            return nil
        }

        let attachmentText = readyScreenshotAttachments.enumerated().map { index, attachment in
            attachment.contextText(index: index + 1)
        }
        .joined(separator: "\n\n")

        return """
        Screenshot attachments
        gridOS extracted text locally from dropped screenshots. Image pixels and local file paths are not included in this provider context.

        \(attachmentText)
        """
    }

    private func attachmentTint(for attachment: ScreenshotAttachment) -> Color {
        switch attachment.status {
        case .processing, .ready:
            Color(theme.palette.statusAccent)
        case .failed:
            Color(theme.palette.primaryAccent)
        }
    }

    private func handleScreenshotDrop(_ providers: [NSItemProvider]) -> Bool {
        screenshotDropError = nil
        var accepted = false
        var remainingSlots = ScreenshotAttachmentLimits.maxAttachments - screenshotAttachments.count

        guard remainingSlots > 0 else {
            screenshotDropError = "Remove a screenshot before adding another."
            return false
        }

        for provider in providers {
            guard remainingSlots > 0 else {
                break
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                accepted = true
                remainingSlots -= 1
                loadDroppedScreenshotFile(provider)
            } else if let type = Self.supportedImageDataType(for: provider) {
                accepted = true
                remainingSlots -= 1
                loadDroppedScreenshotData(provider, type: type)
            }
        }

        if !accepted {
            screenshotDropError = "Drop a PNG, JPEG, TIFF, HEIC, or screenshot file."
        }

        return accepted
    }

    private func loadDroppedScreenshotFile(_ provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let error {
                DispatchQueue.main.async {
                    screenshotDropError = "Could not read dropped screenshot: \(error.localizedDescription)"
                }
                return
            }

            guard let url = Self.fileURL(fromDroppedItem: item) else {
                DispatchQueue.main.async {
                    screenshotDropError = "Could not read the dropped file URL."
                }
                return
            }

            DispatchQueue.main.async {
                processDroppedScreenshotURL(url)
            }
        }
    }

    private func loadDroppedScreenshotData(_ provider: NSItemProvider, type: UTType) {
        provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
            if let error {
                DispatchQueue.main.async {
                    screenshotDropError = "Could not read dropped image: \(error.localizedDescription)"
                }
                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    screenshotDropError = "Could not read dropped image data."
                }
                return
            }

            DispatchQueue.main.async {
                processDroppedScreenshotData(data, suggestedName: "Dropped Screenshot", contentType: type)
            }
        }
    }

    private func processDroppedScreenshotURL(_ url: URL) {
        let id = UUID()
        let placeholder = ScreenshotAttachment.processing(id: id, displayName: url.lastPathComponent)
        screenshotAttachments.append(placeholder)

        DispatchQueue.global(qos: .userInitiated).async {
            let attachment = ScreenshotAttachment.make(id: id, fileURL: url)
            DispatchQueue.main.async {
                replaceScreenshotAttachment(id, with: attachment)
            }
        }
    }

    private func processDroppedScreenshotData(
        _ data: Data,
        suggestedName: String,
        contentType: UTType
    ) {
        let id = UUID()
        let placeholder = ScreenshotAttachment.processing(id: id, displayName: suggestedName)
        screenshotAttachments.append(placeholder)

        DispatchQueue.global(qos: .userInitiated).async {
            let attachment = ScreenshotAttachment.make(
                id: id,
                data: data,
                displayName: suggestedName,
                contentType: contentType
            )
            DispatchQueue.main.async {
                replaceScreenshotAttachment(id, with: attachment)
            }
        }
    }

    private func replaceScreenshotAttachment(_ id: UUID, with attachment: ScreenshotAttachment) {
        guard let index = screenshotAttachments.firstIndex(where: { $0.id == id }) else {
            return
        }

        screenshotAttachments[index] = attachment
    }

    private func removeScreenshotAttachment(_ id: UUID) {
        screenshotAttachments.removeAll { $0.id == id }
    }

    private static func supportedImageDataType(for provider: NSItemProvider) -> UTType? {
        [.png, .jpeg, .tiff, .heic, .image].first { type in
            provider.hasItemConformingToTypeIdentifier(type.identifier)
        }
    }

    nonisolated private static func fileURL(fromDroppedItem item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }

        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }

        if let string = item as? String {
            return URL(string: string)
        }

        return nil
    }

    @MainActor private var canBuildPreview: Bool {
        if hasPendingScreenshotAnalysis {
            return false
        }

        switch selectedFlow {
        case .suggestCommand:
            return !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasReadyScreenshotContext
        case .explainOutput:
            let output = selectedTextProvider() ?? pastedOutput
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasReadyScreenshotContext
        case .fixFailedCommand:
            return !failedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !failedOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                hasReadyScreenshotContext
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
        let screenshotContext = screenshotAttachmentContext

        switch selectedFlow {
        case .suggestCommand:
            return CommandAssistanceInput(
                flow: .suggestCommand,
                userPrompt: prompt,
                workingDirectory: workingDirectoryProvider(),
                screenshotAttachmentContext: screenshotContext
            )
        case .explainOutput:
            let output = selectedTextProvider() ?? pastedOutput
            let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedOutput.isEmpty || screenshotContext != nil else {
                selectionFailure = CommandIntelligenceSelectionFailure(
                    title: "Selection unavailable",
                    message: "Paste output into the field, or drop a screenshot so gridOS can extract text locally."
                )
                return nil
            }

            return CommandAssistanceInput(
                flow: .explainOutput,
                userPrompt: "Explain terminal output",
                workingDirectory: workingDirectoryProvider(),
                selectedOrPastedOutput: trimmedOutput.isEmpty ? nil : output,
                screenshotAttachmentContext: screenshotContext
            )
        case .fixFailedCommand:
            return CommandAssistanceInput(
                flow: .failedCommandHelp,
                userPrompt: "Fix failed command",
                workingDirectory: workingDirectoryProvider(),
                screenshotAttachmentContext: screenshotContext,
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
        cancelSendTask()
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
        guard !isSending else {
            return
        }

        sendTask?.cancel()
        isSending = true
        serviceResult = nil
        lastSubmittedPreview = preview

        sendTask = Task { @MainActor in
            let result = await onSendRequest(preview)
            guard !Task.isCancelled else {
                return
            }

            self.preview = nil
            serviceResult = result
            isSending = false
            sendTask = nil
        }
    }

    @MainActor
    private func resetComposeState() {
        cancelSendTask()
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
            if let command = example.failedCommand {
                failedCommand = command
            }
            failedOutput = example.value
        }

        isPromptFocused = true
    }

    @MainActor
    private func cancelSendTask() {
        sendTask?.cancel()
        sendTask = nil
        isSending = false
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

    private func screenshotAttachmentText(from preview: CommandContextPreview) -> String {
        contextText(.screenshotAttachments, in: preview)
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

private struct PaletteGuideItem: View {
    let label: String
    let value: String
    let theme: VisualTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.palette.secondaryAccent).opacity(0.64))

            Text(value)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(theme.palette.background).opacity(0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color(theme.palette.primaryAccent).opacity(0.15), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct PaletteExamplePrompt: Equatable {
    let title: String
    let value: String
    var failedCommand: String? = nil
}

private struct ScreenshotAttachment: Identifiable, Equatable, Sendable {
    let id: UUID
    let displayName: String
    let byteCount: Int
    let pixelWidth: Int?
    let pixelHeight: Int?
    let contentTypeDescription: String
    let recognizedText: String
    let status: ScreenshotAttachmentStatus

    var detailText: String {
        let dimensions: String
        if let pixelWidth, let pixelHeight {
            dimensions = "\(pixelWidth)x\(pixelHeight)"
        } else {
            dimensions = "unknown size"
        }

        return "\(contentTypeDescription) | \(dimensions) | \(Self.formattedBytes(byteCount))"
    }

    static func processing(id: UUID, displayName: String) -> ScreenshotAttachment {
        ScreenshotAttachment(
            id: id,
            displayName: displayName.isEmpty ? "Dropped Screenshot" : displayName,
            byteCount: 0,
            pixelWidth: nil,
            pixelHeight: nil,
            contentTypeDescription: "image",
            recognizedText: "",
            status: .processing
        )
    }

    static func make(id: UUID, fileURL: URL) -> ScreenshotAttachment {
        let name = fileURL.lastPathComponent.isEmpty ? "Dropped Screenshot" : fileURL.lastPathComponent

        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
            let byteCount = resourceValues.fileSize ?? 0
            guard byteCount <= ScreenshotAttachmentLimits.maxBytes else {
                return failed(
                    id: id,
                    displayName: name,
                    byteCount: byteCount,
                    reason: "File is larger than 25 MB."
                )
            }

            let data = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
            let contentType = resourceValues.contentType ?? UTType(filenameExtension: fileURL.pathExtension) ?? .image
            return make(id: id, data: data, displayName: name, contentType: contentType)
        } catch {
            return failed(
                id: id,
                displayName: name,
                byteCount: 0,
                reason: "Could not read screenshot metadata."
            )
        }
    }

    static func make(
        id: UUID,
        data: Data,
        displayName: String,
        contentType: UTType
    ) -> ScreenshotAttachment {
        autoreleasepool { () -> ScreenshotAttachment in
            guard data.count <= ScreenshotAttachmentLimits.maxBytes else {
                return failed(
                    id: id,
                    displayName: displayName,
                    byteCount: data.count,
                    reason: "Image is larger than 25 MB."
                )
            }

            let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
                return failed(
                    id: id,
                    displayName: displayName,
                    byteCount: data.count,
                    reason: "Unsupported or unreadable image."
                )
            }

            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, sourceOptions) as? [CFString: Any]
            let propertyWidth = properties?[kCGImagePropertyPixelWidth] as? Int
            let propertyHeight = properties?[kCGImagePropertyPixelHeight] as? Int
            if let propertyWidth, let propertyHeight, !Self.isAllowedPixelCount(width: propertyWidth, height: propertyHeight) {
                return failed(
                    id: id,
                    displayName: displayName,
                    byteCount: data.count,
                    reason: "Image dimensions are too large."
                )
            }

            let imageOptions = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, imageOptions) else {
                return failed(
                    id: id,
                    displayName: displayName,
                    byteCount: data.count,
                    reason: "Unsupported or unreadable image."
                )
            }

            let width = propertyWidth ?? cgImage.width
            let height = propertyHeight ?? cgImage.height
            guard Self.isAllowedPixelCount(width: width, height: height) else {
                return failed(
                    id: id,
                    displayName: displayName,
                    byteCount: data.count,
                    reason: "Image dimensions are too large."
                )
            }

            let recognizedText = recognizedText(from: cgImage)

            return ScreenshotAttachment(
                id: id,
                displayName: displayName.isEmpty ? "Dropped Screenshot" : displayName,
                byteCount: data.count,
                pixelWidth: width,
                pixelHeight: height,
                contentTypeDescription: contentType.preferredFilenameExtension?.uppercased() ?? contentType.localizedDescription ?? "image",
                recognizedText: recognizedText,
                status: .ready
            )
        }
    }

    static func failed(
        id: UUID,
        displayName: String,
        byteCount: Int,
        reason: String
    ) -> ScreenshotAttachment {
        ScreenshotAttachment(
            id: id,
            displayName: displayName.isEmpty ? "Dropped Screenshot" : displayName,
            byteCount: byteCount,
            pixelWidth: nil,
            pixelHeight: nil,
            contentTypeDescription: "image",
            recognizedText: "",
            status: .failed(reason)
        )
    }

    func contextText(index: Int) -> String {
        let textBlock: String
        if recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textBlock = "Recognized text: none"
        } else {
            textBlock = """
            Recognized text:
            \(recognizedText)
            """
        }

        return """
        Screenshot \(index): \(displayName)
        Metadata: \(detailText)
        \(textBlock)
        """
    }

    private static func recognizedText(from cgImage: CGImage) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        let text = (request.results ?? [])
            .compactMap { observation in
                observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        return truncated(text, limit: ScreenshotAttachmentLimits.maxOCRCharacters)
    }

    private static func isAllowedPixelCount(width: Int, height: Int) -> Bool {
        guard width > 0, height > 0 else {
            return false
        }

        return width <= ScreenshotAttachmentLimits.maxPixels / height
    }

    private static func truncated(_ text: String, limit: Int) -> String {
        guard text.count > limit else {
            return text
        }

        let endIndex = text.index(text.startIndex, offsetBy: limit)
        return String(text[..<endIndex]) + "\n[OCR text truncated]"
    }

    private static func formattedBytes(_ byteCount: Int) -> String {
        guard byteCount > 0 else {
            return "pending"
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(byteCount))
    }
}

private enum ScreenshotAttachmentLimits {
    static let maxAttachments = 4
    static let maxBytes = 25 * 1_024 * 1_024
    static let maxPixels = 20_000_000
    static let maxOCRCharacters = 6_000
}

private enum ScreenshotAttachmentStatus: Equatable, Sendable {
    case processing
    case ready
    case failed(String)

    var isReady: Bool {
        if case .ready = self {
            return true
        }

        return false
    }

    var displayText: String {
        switch self {
        case .processing:
            "OCR"
        case .ready:
            "READY"
        case .failed:
            "FAILED"
        }
    }

    var systemImageName: String {
        switch self {
        case .processing:
            "clock"
        case .ready:
            "text.viewfinder"
        case .failed:
            "exclamationmark.triangle"
        }
    }
}

enum CommandPaletteProviderStatus: Equatable {
    case unknown
    case configured
    case missing(providerName: String)

    var isMissing: Bool {
        if case .missing = self {
            return true
        }

        return false
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

    var useWhen: String {
        switch self {
        case .suggestCommand:
            "You know the goal, not the exact command."
        case .explainOutput:
            "Output is confusing and you want the meaning."
        case .fixFailedCommand:
            "A command failed and you need a safer next try."
        }
    }

    var inputHint: String {
        switch self {
        case .suggestCommand:
            "Plain English intent and current directory."
        case .explainOutput:
            "Selected terminal output or pasted text."
        case .fixFailedCommand:
            "The failed command plus the error output."
        }
    }

    var resultHint: String {
        switch self {
        case .suggestCommand:
            "A reviewed command plan."
        case .explainOutput:
            "A read-only diagnosis."
        case .fixFailedCommand:
            "A repair command with local risk labels."
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
