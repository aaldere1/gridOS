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
            Picker("Provider", selection: providerSelection) {
                Text("Anthropic")
                    .tag(GridOSAppPreferences.defaultCommandIntelligenceProviderID)
            }
            .accessibilityLabel("Provider")
            .accessibilityValue("Anthropic")

            Picker("Model", selection: modelSelection) {
                Text("claude-sonnet-4-6")
                    .tag(GridOSAppPreferences.defaultCommandIntelligenceModelID)
            }
            .accessibilityLabel("Model")
            .accessibilityValue(GridOSAppPreferences.defaultCommandIntelligenceModelID)

            VStack(alignment: .leading, spacing: 8) {
                Text(isProviderConfigured ? "Provider configured" : "Provider not configured")
                    .font(.subheadline.weight(.semibold))

                if !isProviderConfigured {
                    Text("Add a provider key in Settings to use command intelligence. The terminal still works normally.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            SecureField("Anthropic API key", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Anthropic API key")

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
                providerIDRawValue = GridOSAppPreferences.normalizedCommandIntelligenceProviderID(newValue)
            }
        )
    }

    private var modelSelection: Binding<String> {
        Binding(
            get: {
                GridOSAppPreferences.normalizedCommandIntelligenceModelID(modelIDRawValue)
            },
            set: { newValue in
                modelIDRawValue = GridOSAppPreferences.normalizedCommandIntelligenceModelID(newValue)
            }
        )
    }

    private var normalizedProviderIDRawValue: String {
        GridOSAppPreferences.normalizedCommandIntelligenceProviderID(providerIDRawValue)
    }

    private var normalizedProviderID: LLMProviderID {
        LLMProviderID(normalizedProviderIDRawValue)
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
