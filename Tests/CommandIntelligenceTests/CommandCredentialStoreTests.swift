import XCTest
import Security
import GridOSKit
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

    func testKeychainStoreUsesExpectedServiceClassAccountAndAccessibility() async throws {
        let client = RecordingKeychainSecItemClient(addStatuses: [errSecSuccess])
        let store = KeychainCommandCredentialStore(client: client)

        try await store.saveAPIKey("  sk-ant-test-value  ", for: .anthropic)

        let operations = await client.recordedOperations()
        let operation = try XCTUnwrap(operations.first)
        guard case let .add(query) = operation else {
            return XCTFail("Expected add operation")
        }

        XCTAssertEqual(query[kSecClass], .securityConstant(kSecClassGenericPassword as String))
        XCTAssertEqual(query[kSecAttrService], .string("com.aaldere1.gridos.command-intelligence"))
        XCTAssertEqual(query[kSecAttrAccount], .string("anthropic"))
        XCTAssertEqual(query[kSecAttrAccessible], .securityConstant(kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String))
        XCTAssertEqual(query[kSecUseDataProtectionKeychain], .bool(true))
        XCTAssertEqual(query[kSecValueData], .data(Data("sk-ant-test-value".utf8)))
    }

    func testKeychainStoreUpdatesExistingItemInsteadOfDuplicating() async throws {
        let client = RecordingKeychainSecItemClient(addStatuses: [errSecDuplicateItem], updateStatus: errSecSuccess)
        let store = KeychainCommandCredentialStore(client: client)

        try await store.saveAPIKey("sk-ant-replacement", for: .anthropic)

        let operations = await client.recordedOperations()
        XCTAssertEqual(operations.count, 2)

        guard case .add = operations[0],
              case let .update(query, attributesToUpdate) = operations[1]
        else {
            return XCTFail("Expected add followed by update")
        }

        XCTAssertEqual(query[kSecClass], .securityConstant(kSecClassGenericPassword as String))
        XCTAssertEqual(query[kSecAttrService], .string("com.aaldere1.gridos.command-intelligence"))
        XCTAssertEqual(query[kSecAttrAccount], .string("anthropic"))
        XCTAssertNil(query[kSecValueData])
        XCTAssertEqual(attributesToUpdate[kSecValueData], .data(Data("sk-ant-replacement".utf8)))
        XCTAssertEqual(
            attributesToUpdate[kSecAttrAccessible],
            .securityConstant(kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        )
    }

    func testKeychainStoreReadsAndDeletesWithoutRealKeychainAccess() async throws {
        let client = RecordingKeychainSecItemClient(
            copyResult: KeychainSecItemCopyResult(status: errSecSuccess, data: Data("sk-ant-saved".utf8)),
            deleteStatus: errSecItemNotFound
        )
        let store = KeychainCommandCredentialStore(client: client)

        let savedKey = try await store.apiKey(for: .anthropic)
        try await store.deleteAPIKey(for: .anthropic)

        XCTAssertEqual(savedKey, "sk-ant-saved")
        let operations = await client.recordedOperations()
        XCTAssertEqual(operations.count, 2)
        guard case let .copyMatching(copyQuery) = operations[0],
              case let .delete(deleteQuery) = operations[1]
        else {
            return XCTFail("Expected copy then delete")
        }
        XCTAssertEqual(copyQuery[kSecReturnData], .bool(true))
        XCTAssertEqual(copyQuery[kSecMatchLimit], .securityConstant(kSecMatchLimitOne as String))
        XCTAssertEqual(deleteQuery[kSecUseDataProtectionKeychain], .bool(true))
    }

    func testKeychainStoreReturnsNilForMissingItemAndRejectsEmptyKeys() async throws {
        let client = RecordingKeychainSecItemClient(
            copyResult: KeychainSecItemCopyResult(status: errSecItemNotFound, data: nil)
        )
        let store = KeychainCommandCredentialStore(client: client)

        let missingKey = try await store.apiKey(for: .anthropic)
        XCTAssertNil(missingKey)

        do {
            try await store.saveAPIKey("   ", for: .anthropic)
            XCTFail("Expected human-readable empty key failure")
        } catch let failure as CommandIntelligenceFailure {
            XCTAssertEqual(failure.title, "Provider not configured")
        }
    }

    func testKeychainStoreMapsUnexpectedStatusesToProviderError() async throws {
        let client = RecordingKeychainSecItemClient(addStatuses: [errSecAuthFailed])
        let store = KeychainCommandCredentialStore(client: client)

        do {
            try await store.saveAPIKey("sk-ant-test-value", for: .anthropic)
            XCTFail("Expected provider error")
        } catch let failure as CommandIntelligenceFailure {
            XCTAssertEqual(failure, .providerError())
        }
    }
}

private enum RecordedKeychainOperation: Equatable {
    case add(KeychainSecItemQuery)
    case update(KeychainSecItemQuery, attributesToUpdate: KeychainSecItemQuery)
    case copyMatching(KeychainSecItemQuery)
    case delete(KeychainSecItemQuery)
}

private actor RecordingKeychainSecItemClient: KeychainSecItemClient {
    private var operations: [RecordedKeychainOperation] = []
    private var addStatuses: [OSStatus]
    private let updateStatus: OSStatus
    private let copyResult: KeychainSecItemCopyResult
    private let deleteStatus: OSStatus

    init(
        addStatuses: [OSStatus] = [],
        updateStatus: OSStatus = errSecSuccess,
        copyResult: KeychainSecItemCopyResult = KeychainSecItemCopyResult(status: errSecItemNotFound, data: nil),
        deleteStatus: OSStatus = errSecSuccess
    ) {
        self.addStatuses = addStatuses
        self.updateStatus = updateStatus
        self.copyResult = copyResult
        self.deleteStatus = deleteStatus
    }

    func add(_ query: KeychainSecItemQuery) async -> OSStatus {
        operations.append(.add(query))
        guard !addStatuses.isEmpty else { return errSecSuccess }
        return addStatuses.removeFirst()
    }

    func update(_ query: KeychainSecItemQuery, attributesToUpdate: KeychainSecItemQuery) async -> OSStatus {
        operations.append(.update(query, attributesToUpdate: attributesToUpdate))
        return updateStatus
    }

    func copyMatching(_ query: KeychainSecItemQuery) async -> KeychainSecItemCopyResult {
        operations.append(.copyMatching(query))
        return copyResult
    }

    func delete(_ query: KeychainSecItemQuery) async -> OSStatus {
        operations.append(.delete(query))
        return deleteStatus
    }

    func recordedOperations() -> [RecordedKeychainOperation] {
        operations
    }
}
