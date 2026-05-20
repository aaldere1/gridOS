import RenderCore
import SwiftUI

struct CommandPaletteView: View {
    let theme: VisualTheme
    let onClose: () -> Void
    let onOpenCommandIntelligenceSettings: () -> Void

    @State private var selectedFlow: CommandPaletteFlow = .suggestCommand
    @State private var prompt = ""
    @FocusState private var isPromptFocused: Bool

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
                .accessibilityLabel("Command Intelligence flow")

                composeContent

                Spacer(minLength: 0)

                Button("Open Command Intelligence Settings") {
                    onOpenCommandIntelligenceSettings()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(theme.palette.statusAccent).opacity(0.90))
                .accessibilityLabel("Open Command Intelligence Settings")
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

                Text(selectedFlow.subtitle)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedFlow.inputLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.78))

            TextEditor(text: $prompt)
                .font(.system(size: 13, weight: .regular, design: selectedFlow.usesMonospacedInput ? .monospaced : .default))
                .foregroundStyle(Color(theme.palette.primaryAccent).opacity(0.92))
                .scrollContentBackground(.hidden)
                .background(Color(theme.palette.background).opacity(0.46))
                .overlay(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text(selectedFlow.placeholder)
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

    var inputLabel: String {
        switch self {
        case .suggestCommand:
            "Prompt"
        case .explainOutput:
            "Output"
        case .fixFailedCommand:
            "Failed command and output"
        }
    }

    var placeholder: String {
        switch self {
        case .suggestCommand:
            "Describe the command you want."
        case .explainOutput:
            "Select terminal output or paste it here."
        case .fixFailedCommand:
            "Paste the failed command and output."
        }
    }

    var usesMonospacedInput: Bool {
        self != .suggestCommand
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
