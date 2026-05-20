import Foundation

public protocol CommandCredentialStore: Sendable {
    func apiKey(for provider: LLMProviderID) async throws -> String?
    func saveAPIKey(_ apiKey: String, for provider: LLMProviderID) async throws
    func deleteAPIKey(for provider: LLMProviderID) async throws
}

public actor InMemoryCommandCredentialStore: CommandCredentialStore {
    private var apiKeysByProvider: [LLMProviderID: String]

    public init(apiKeysByProvider: [LLMProviderID: String] = [:]) {
        self.apiKeysByProvider = apiKeysByProvider
    }

    public func apiKey(for provider: LLMProviderID) async throws -> String? {
        apiKeysByProvider[provider]
    }

    public func saveAPIKey(_ apiKey: String, for provider: LLMProviderID) async throws {
        apiKeysByProvider[provider] = apiKey
    }

    public func deleteAPIKey(for provider: LLMProviderID) async throws {
        apiKeysByProvider[provider] = nil
    }
}
