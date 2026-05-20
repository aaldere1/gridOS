import XCTest
@testable import CommandIntelligence

final class CommandCredentialStoreTests: XCTestCase {
    func testInMemoryStoreReturnsNilWhenNoKeyIsSaved() async throws {
        let store = InMemoryCommandCredentialStore()

        let apiKey = try await store.apiKey(for: .anthropic)

        XCTAssertNil(apiKey)
    }

    func testInMemoryStoreSavesReadsAndDeletesProviderKeys() async throws {
        let store = InMemoryCommandCredentialStore()
        let provider: LLMProviderID = "anthropic"

        try await store.saveAPIKey("sk-test-value", for: provider)
        let savedAPIKey = try await store.apiKey(for: provider)
        XCTAssertEqual(savedAPIKey, "sk-test-value")

        try await store.deleteAPIKey(for: provider)
        let deletedAPIKey = try await store.apiKey(for: provider)
        XCTAssertNil(deletedAPIKey)
    }
}
