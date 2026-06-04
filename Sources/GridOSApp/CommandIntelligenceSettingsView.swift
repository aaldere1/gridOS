import CommandIntelligence
import GridOSKit
import SwiftUI

struct CommandIntelligenceSettingsView: View {
    @AppStorage(GridOSAppPreferences.commandIntelligenceProviderStorageKey)
    private var providerIDRawValue = GridOSAppPreferences.defaultCommandIntelligenceProviderID

    @AppStorage(GridOSAppPreferences.commandIntelligenceModelStorageKey)
    private var modelIDRawValue = GridOSAppPreferences.defaultCommandIntelligenceModelID

    @State private var apiKeyInput = ""
    @State private var isProviderConfigured = false
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var isHelpPresented = false
    @State private var failure: CommandIntelligenceFailure?

    private let credentialStore: any CommandCredentialStore

    init(credentialStore: any CommandCredentialStore = KeychainCommandCredentialStore()) {
        self.credentialStore = credentialStore
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("AI Command Helper turns a terminal question into a reviewed next step.")
                    .font(.subheadline.weight(.semibold))

                Text("Press Command-K in any pane, choose a job, preview the redacted context, then decide what to insert or run.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            CommandHelperHowToCard()

            Picker("Provider", selection: providerSelection) {
                ForEach(CommandIntelligenceModelCatalog.providers) { provider in
                    Text(provider.displayName)
                        .tag(provider.id.rawValue)
                }
            }
            .accessibilityLabel("Provider")
            .accessibilityValue(currentProviderDescriptor.displayName)

            Picker("Model", selection: modelSelection) {
                ForEach(currentProviderDescriptor.models) { model in
                    Text(model.isRecommended ? "\(model.displayName) - Recommended" : model.displayName)
                        .tag(model.id.rawValue)
                }
            }
            .accessibilityLabel("Model")
            .accessibilityValue(normalizedModelIDRawValue)

            VStack(alignment: .leading, spacing: 6) {
                TextField("Model ID", text: $modelIDRawValue)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .accessibilityLabel("Model ID")

                Text(modelHelpText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 8) {
                Text(isProviderConfigured ? "Provider configured" : "Provider not configured")
                    .font(.subheadline.weight(.semibold))

                if !isProviderConfigured {
                    Text("Add \(currentProviderArticle) \(currentProviderDescriptor.displayName) key once. Until then, Command-K still opens, but nothing is sent to a provider.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text(currentProviderDescriptor.setupHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            SecureField(currentProviderDescriptor.apiKeyLabel, text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(currentProviderDescriptor.apiKeyLabel)

            HStack {
                Button("Save Provider Key") {
                    Task {
                        await saveProviderKey()
                    }
                }
                .disabled(isSaving || apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Save Provider Key")

                if isProviderConfigured {
                    Button("Remove Provider Key", role: .destructive) {
                        Task {
                            await removeProviderKey()
                        }
                    }
                    .disabled(isDeleting)
                    .accessibilityLabel("Remove Provider Key")
                }
            }

            if let failure {
                VStack(alignment: .leading, spacing: 4) {
                    Text(failure.title)
                        .font(.footnote.weight(.semibold))
                    Text(failure.message)
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
                .accessibilityElement(children: .combine)
            }
        }
        header: {
            HStack(spacing: 6) {
                Text("AI Command Helper")

                Button {
                    isHelpPresented.toggle()
                } label: {
                    Label("About AI Command Helper", systemImage: "info.circle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About AI Command Helper")
                .popover(isPresented: $isHelpPresented, arrowEdge: .top) {
                    CommandHelperInfoPopover()
                        .padding(16)
                        .frame(width: 320)
                }
            }
        }
        .task(id: normalizedProviderIDRawValue) {
            await refreshProviderStatus()
        }
    }

    private var providerSelection: Binding<String> {
        Binding(
            get: {
                GridOSAppPreferences.normalizedCommandIntelligenceProviderID(providerIDRawValue)
            },
            set: { newValue in
                let normalizedProviderID = GridOSAppPreferences.normalizedCommandIntelligenceProviderID(newValue)
                providerIDRawValue = normalizedProviderID
                modelIDRawValue = GridOSAppPreferences.defaultCommandIntelligenceModelID(for: normalizedProviderID)
                apiKeyInput = ""
                failure = nil
            }
        )
    }

    private var modelSelection: Binding<String> {
        Binding(
            get: {
                normalizedModelIDRawValue
            },
            set: { newValue in
                modelIDRawValue = GridOSAppPreferences.normalizedCommandIntelligenceModelID(
                    newValue,
                    providerID: normalizedProviderIDRawValue
                )
            }
        )
    }

    private var normalizedProviderIDRawValue: String {
        GridOSAppPreferences.normalizedCommandIntelligenceProviderID(providerIDRawValue)
    }

    private var normalizedProviderID: LLMProviderID {
        LLMProviderID(normalizedProviderIDRawValue)
    }

    private var normalizedModelIDRawValue: String {
        GridOSAppPreferences.normalizedCommandIntelligenceModelID(
            modelIDRawValue,
            providerID: normalizedProviderIDRawValue
        )
    }

    private var currentProviderDescriptor: LLMProviderDescriptor {
        CommandIntelligenceModelCatalog.descriptor(for: normalizedProviderID)
    }

    private var currentModelID: LLMModelID {
        LLMModelID(normalizedModelIDRawValue)
    }

    private var currentProviderArticle: String {
        guard let firstCharacter = currentProviderDescriptor.displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first?
            .uppercased()
        else {
            return "a"
        }

        return ["A", "E", "I", "O", "U"].contains(firstCharacter) ? "an" : "a"
    }

    private var modelHelpText: String {
        if let descriptor = CommandIntelligenceModelCatalog.knownModelDescriptor(
            currentModelID,
            providerID: normalizedProviderID
        ) {
            return descriptor.detail
        }

        return "Custom model ID. Use this when your provider account has access to a newer or pinned model."
    }

    @MainActor
    private func saveProviderKey() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await credentialStore.saveAPIKey(apiKeyInput, for: normalizedProviderID)
            apiKeyInput = ""
            failure = nil
            isProviderConfigured = true
        } catch let commandFailure as CommandIntelligenceFailure {
            failure = commandFailure
        } catch {
            failure = .providerError()
        }
    }

    @MainActor
    private func removeProviderKey() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await credentialStore.deleteAPIKey(for: normalizedProviderID)
            apiKeyInput = ""
            failure = nil
            isProviderConfigured = false
        } catch let commandFailure as CommandIntelligenceFailure {
            failure = commandFailure
        } catch {
            failure = .providerError()
        }
    }

    @MainActor
    private func refreshProviderStatus() async {
        do {
            isProviderConfigured = try await credentialStore.apiKey(for: normalizedProviderID) != nil
            failure = nil
        } catch let commandFailure as CommandIntelligenceFailure {
            failure = commandFailure
        } catch {
            failure = .providerError()
        }
    }
}
