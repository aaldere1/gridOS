import CommandIntelligence
import GridOSKit
import SwiftUI

struct CommandIntelligenceSettingsView: View {
    private static let openSettingsActionText = "Open Command Intelligence Settings"

    @AppStorage(GridOSAppPreferences.commandIntelligenceProviderStorageKey)
    private var providerIDRawValue = GridOSAppPreferences.defaultCommandIntelligenceProviderID

    @AppStorage(GridOSAppPreferences.commandIntelligenceModelStorageKey)
    private var modelIDRawValue = GridOSAppPreferences.defaultCommandIntelligenceModelID

    @State private var apiKeyInput = ""
    @State private var isProviderConfigured = false
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var failure: CommandIntelligenceFailure?

    private let credentialStore: any CommandCredentialStore

    init(credentialStore: any CommandCredentialStore = KeychainCommandCredentialStore()) {
        self.credentialStore = credentialStore
    }

    var body: some View {
        Section("Command Intelligence") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Command Intelligence turns only the context you approve into provider-assisted shell help.")
                    .font(.subheadline.weight(.semibold))

                Text("gridOS redacts secrets before send, stores provider keys in Keychain, rechecks suggested commands locally, and inserts risky commands for review instead of running them blindly.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

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
                    Text("Add a \(currentProviderDescriptor.displayName) key to use this provider. The terminal still works normally.")
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
