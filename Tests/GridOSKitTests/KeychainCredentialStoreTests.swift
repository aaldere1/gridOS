import XCTest
import Security
@testable import GridOSKit

final class KeychainCredentialStoreTests: XCTestCase {
    func testDescriptorBuildsGenericPasswordQuery() {
        let descriptor = KeychainCredentialDescriptor(
            service: "com.aaldere1.gridos.test",
            account: "anthropic"
        )

        let query = descriptor.baseQuery()

        XCTAssertEqual(query[kSecClass], .securityConstant(kSecClassGenericPassword as String))
        XCTAssertEqual(query[kSecAttrService], .string("com.aaldere1.gridos.test"))
        XCTAssertEqual(query[kSecAttrAccount], .string("anthropic"))
        XCTAssertEqual(query[kSecUseDataProtectionKeychain], .bool(true))
        XCTAssertNil(query[kSecValueData])
    }

    func testStoreSavesSecretWithAccessibilityAndTrimmedData() async throws {
        let client = RecordingKeychainSecItemClient(addStatuses: [errSecSuccess])
        let store = KeychainCredentialStore(client: client)

        try await store.saveSecret("  stored-secret  ", for: descriptor)

        let operations = await client.recordedOperations()
        guard case let .add(query) = operations.first else {
            return XCTFail("Expected add operation")
        }

        XCTAssertEqual(query[kSecClass], .securityConstant(kSecClassGenericPassword as String))
        XCTAssertEqual(query[kSecAttrService], .string("com.aaldere1.gridos.test"))
        XCTAssertEqual(query[kSecAttrAccount], .string("anthropic"))
        XCTAssertEqual(query[kSecAttrAccessible], .securityConstant(kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String))
        XCTAssertEqual(query[kSecUseDataProtectionKeychain], .bool(true))
        XCTAssertEqual(query[kSecValueData], .data(Data("stored-secret".utf8)))
    }

    func testStoreUpdatesDuplicateItem() async throws {
        let client = RecordingKeychainSecItemClient(addStatuses: [errSecDuplicateItem], updateStatus: errSecSuccess)
        let store = KeychainCredentialStore(client: client)

        try await store.saveSecret("replacement-secret", for: descriptor)

        let operations = await client.recordedOperations()
        XCTAssertEqual(operations.count, 2)

        guard case .add = operations[0],
              case let .update(query, attributesToUpdate) = operations[1]
        else {
            return XCTFail("Expected add followed by update")
        }

        XCTAssertEqual(query[kSecClass], .securityConstant(kSecClassGenericPassword as String))
        XCTAssertEqual(query[kSecAttrService], .string("com.aaldere1.gridos.test"))
        XCTAssertEqual(query[kSecAttrAccount], .string("anthropic"))
        XCTAssertNil(query[kSecValueData])
        XCTAssertEqual(attributesToUpdate[kSecValueData], .data(Data("replacement-secret".utf8)))
        XCTAssertEqual(
            attributesToUpdate[kSecAttrAccessible],
            .securityConstant(kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        )
    }

    func testStoreReadsSecretAndDeletes() async throws {
        let client = RecordingKeychainSecItemClient(
            copyResult: KeychainSecItemCopyResult(status: errSecSuccess, data: Data("stored-secret".utf8)),
            deleteStatus: errSecSuccess
        )
        let store = KeychainCredentialStore(client: client)

        let secret = try await store.secret(for: descriptor)
        try await store.deleteSecret(for: descriptor)

        XCTAssertEqual(secret, "stored-secret")
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

    func testStoreReturnsNilForMissingItem() async throws {
        let client = RecordingKeychainSecItemClient(
            copyResult: KeychainSecItemCopyResult(status: errSecItemNotFound, data: nil)
        )
        let store = KeychainCredentialStore(client: client)

        let secret = try await store.secret(for: descriptor)

        XCTAssertNil(secret)
    }

    func testStoreRejectsEmptySecret() async throws {
        let store = KeychainCredentialStore(client: RecordingKeychainSecItemClient())

        do {
            try await store.saveSecret("   ", for: descriptor)
            XCTFail("Expected empty secret failure")
        } catch let error as KeychainCredentialStoreError {
            XCTAssertEqual(error, .emptySecret)
        }
    }

    private var descriptor: KeychainCredentialDescriptor {
        KeychainCredentialDescriptor(
            service: "com.aaldere1.gridos.test",
            account: "anthropic"
        )
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
