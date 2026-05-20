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
        XCTAssertEqual(try await store.apiKey(for: provider), "sk-test-value")

        try await store.deleteAPIKey(for: provider)
        XCTAssertNil(try await store.apiKey(for: provider))
    }
}
