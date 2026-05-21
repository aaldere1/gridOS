import Foundation
import Security

public enum KeychainSecItemValue: Equatable, Sendable {
    case string(String)
    case bool(Bool)
    case data(Data)
    case securityConstant(String)

    var objectValue: Any {
        switch self {
        case let .string(value):
            value
        case let .bool(value):
            value
        case let .data(value):
            value
        case let .securityConstant(value):
            value
        }
    }
}

public struct KeychainSecItemQuery: Equatable, Sendable {
    private let values: [String: KeychainSecItemValue]

    public init(values: [String: KeychainSecItemValue]) {
        self.values = values
    }

    public subscript(_ key: CFString) -> KeychainSecItemValue? {
        values[key as String]
    }

    var dictionary: CFDictionary {
        var dictionary: [String: Any] = [:]

        for (key, value) in values {
            dictionary[key] = value.objectValue
        }

        return dictionary as CFDictionary
    }

    public func merging(_ otherValues: [String: KeychainSecItemValue]) -> KeychainSecItemQuery {
        var mergedValues = values
        for (key, value) in otherValues {
            mergedValues[key] = value
        }
        return KeychainSecItemQuery(values: mergedValues)
    }
}

public struct KeychainSecItemCopyResult: Equatable, Sendable {
    public let status: OSStatus
    public let data: Data?

    public init(status: OSStatus, data: Data?) {
        self.status = status
        self.data = data
    }
}

public protocol KeychainSecItemClient: Sendable {
    func add(_ query: KeychainSecItemQuery) async -> OSStatus
    func update(_ query: KeychainSecItemQuery, attributesToUpdate: KeychainSecItemQuery) async -> OSStatus
    func copyMatching(_ query: KeychainSecItemQuery) async -> KeychainSecItemCopyResult
    func delete(_ query: KeychainSecItemQuery) async -> OSStatus
}

public struct LiveKeychainSecItemClient: KeychainSecItemClient {
    public init() {}

    public func add(_ query: KeychainSecItemQuery) async -> OSStatus {
        SecItemAdd(query.dictionary, nil)
    }

    public func update(_ query: KeychainSecItemQuery, attributesToUpdate: KeychainSecItemQuery) async -> OSStatus {
        SecItemUpdate(query.dictionary, attributesToUpdate.dictionary)
    }

    public func copyMatching(_ query: KeychainSecItemQuery) async -> KeychainSecItemCopyResult {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query.dictionary, &item)
        return KeychainSecItemCopyResult(status: status, data: item as? Data)
    }

    public func delete(_ query: KeychainSecItemQuery) async -> OSStatus {
        SecItemDelete(query.dictionary)
    }
}

public struct KeychainCredentialDescriptor: Equatable, Sendable {
    public let service: String
    public let account: String
    public let accessible: String
    public let useDataProtectionKeychain: Bool

    public init(
        service: String,
        account: String,
        accessible: String = kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String,
        useDataProtectionKeychain: Bool = true
    ) {
        self.service = service
        self.account = account
        self.accessible = accessible
        self.useDataProtectionKeychain = useDataProtectionKeychain
    }

    public func baseQuery() -> KeychainSecItemQuery {
        KeychainSecItemQuery(values: [
            kSecClass as String: .securityConstant(kSecClassGenericPassword as String),
            kSecAttrService as String: .string(service),
            kSecAttrAccount as String: .string(account),
            kSecUseDataProtectionKeychain as String: .bool(useDataProtectionKeychain)
        ])
    }
}

public enum KeychainCredentialStoreError: Error, Equatable, Sendable {
    case emptySecret
    case invalidSecretData
    case unexpectedStatus(OSStatus)
}

public struct KeychainCredentialStore: Sendable {
    private let client: any KeychainSecItemClient

    public init(client: any KeychainSecItemClient = LiveKeychainSecItemClient()) {
        self.client = client
    }

    public func secret(for descriptor: KeychainCredentialDescriptor) async throws -> String? {
        let result = await client.copyMatching(
            descriptor.baseQuery().merging([
                kSecReturnData as String: .bool(true),
                kSecMatchLimit as String: .securityConstant(kSecMatchLimitOne as String)
            ])
        )

        switch result.status {
        case errSecSuccess:
            guard let data = result.data,
                  let secret = String(data: data, encoding: .utf8)
            else {
                throw KeychainCredentialStoreError.invalidSecretData
            }
            return secret
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainCredentialStoreError.unexpectedStatus(result.status)
        }
    }

    public func saveSecret(_ secret: String, for descriptor: KeychainCredentialDescriptor) async throws {
        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSecret.isEmpty else {
            throw KeychainCredentialStoreError.emptySecret
        }

        guard let data = trimmedSecret.data(using: .utf8) else {
            throw KeychainCredentialStoreError.invalidSecretData
        }

        let addStatus = await client.add(
            descriptor.baseQuery().merging([
                kSecAttrAccessible as String: .securityConstant(descriptor.accessible),
                kSecValueData as String: .data(data)
            ])
        )

        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updateStatus = await client.update(
                descriptor.baseQuery(),
                attributesToUpdate: KeychainSecItemQuery(values: [
                    kSecAttrAccessible as String: .securityConstant(descriptor.accessible),
                    kSecValueData as String: .data(data)
                ])
            )
            guard updateStatus == errSecSuccess else {
                throw KeychainCredentialStoreError.unexpectedStatus(updateStatus)
            }
        default:
            throw KeychainCredentialStoreError.unexpectedStatus(addStatus)
        }
    }

    public func deleteSecret(for descriptor: KeychainCredentialDescriptor) async throws {
        let status = await client.delete(descriptor.baseQuery())

        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        default:
            throw KeychainCredentialStoreError.unexpectedStatus(status)
        }
    }
}
