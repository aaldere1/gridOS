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

    func merging(_ otherValues: [String: KeychainSecItemValue]) -> KeychainSecItemQuery {
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

public struct KeychainCommandCredentialStore: CommandCredentialStore {
    public static let service = "com.aaldere1.gridos.command-intelligence"

    private let client: KeychainSecItemClient
    private let service: String

    public init(
        client: KeychainSecItemClient = LiveKeychainSecItemClient(),
        service: String = KeychainCommandCredentialStore.service
    ) {
        self.client = client
        self.service = service
    }

    public func apiKey(for provider: LLMProviderID) async throws -> String? {
        let result = await client.copyMatching(
            baseQuery(for: provider).merging([
                kSecReturnData as String: .bool(true),
                kSecMatchLimit as String: .securityConstant(kSecMatchLimitOne as String)
            ])
        )

        switch result.status {
        case errSecSuccess:
            guard let data = result.data,
                  let apiKey = String(data: data, encoding: .utf8)
            else {
                throw CommandIntelligenceFailure.invalidProviderResponse()
            }
            return apiKey
        case errSecItemNotFound:
            return nil
        default:
            throw CommandIntelligenceFailure.providerError()
        }
    }

    public func saveAPIKey(_ apiKey: String, for provider: LLMProviderID) async throws {
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAPIKey.isEmpty else {
            throw CommandIntelligenceFailure.noProviderKey()
        }

        guard let data = trimmedAPIKey.data(using: .utf8) else {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        }

        let addStatus = await client.add(
            baseQuery(for: provider).merging([
                kSecAttrAccessible as String: .securityConstant(kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String),
                kSecValueData as String: .data(data)
            ])
        )

        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updateStatus = await client.update(
                baseQuery(for: provider),
                attributesToUpdate: KeychainSecItemQuery(values: [
                    kSecAttrAccessible as String: .securityConstant(kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String),
                    kSecValueData as String: .data(data)
                ])
            )
            guard updateStatus == errSecSuccess else {
                throw CommandIntelligenceFailure.providerError()
            }
        default:
            throw CommandIntelligenceFailure.providerError()
        }
    }

    public func deleteAPIKey(for provider: LLMProviderID) async throws {
        let status = await client.delete(baseQuery(for: provider))

        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        default:
            throw CommandIntelligenceFailure.providerError()
        }
    }

    private func baseQuery(for provider: LLMProviderID) -> KeychainSecItemQuery {
        KeychainSecItemQuery(values: [
            kSecClass as String: .securityConstant(kSecClassGenericPassword as String),
            kSecAttrService as String: .string(service),
            kSecAttrAccount as String: .string(provider.rawValue),
            kSecUseDataProtectionKeychain as String: .bool(true)
        ])
    }
}
