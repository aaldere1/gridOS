import Foundation
import GridOSKit

public struct KeychainCommandCredentialStore: CommandCredentialStore {
    public static let service = "com.aaldere1.gridos.command-intelligence"

    private let credentialStore: KeychainCredentialStore
    private let service: String

    public init(
        client: any KeychainSecItemClient = LiveKeychainSecItemClient(),
        service: String = KeychainCommandCredentialStore.service
    ) {
        self.credentialStore = KeychainCredentialStore(client: client)
        self.service = service
    }

    public func apiKey(for provider: LLMProviderID) async throws -> String? {
        do {
            return try await credentialStore.secret(for: descriptor(for: provider))
        } catch KeychainCredentialStoreError.invalidSecretData {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        } catch {
            throw CommandIntelligenceFailure.providerError()
        }
    }

    public func saveAPIKey(_ apiKey: String, for provider: LLMProviderID) async throws {
        do {
            try await credentialStore.saveSecret(apiKey, for: descriptor(for: provider))
        } catch KeychainCredentialStoreError.emptySecret {
            throw CommandIntelligenceFailure.noProviderKey()
        } catch KeychainCredentialStoreError.invalidSecretData {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        } catch {
            throw CommandIntelligenceFailure.providerError()
        }
    }

    public func deleteAPIKey(for provider: LLMProviderID) async throws {
        do {
            try await credentialStore.deleteSecret(for: descriptor(for: provider))
        } catch {
            throw CommandIntelligenceFailure.providerError()
        }
    }

    private func descriptor(for provider: LLMProviderID) -> KeychainCredentialDescriptor {
        KeychainCredentialDescriptor(
            service: service,
            account: provider.rawValue
        )
    }
}
