import CoreServices
@preconcurrency import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

public struct WorkspaceSearchMetadata: Equatable, Sendable, Identifiable {
    public let id: String
    public let displayName: String
    public let directoryBasename: String

    public init(id: String, displayName: String, directoryPath: String) {
        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = trimmedID.isEmpty ? "workspace" : trimmedID

        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.displayName = trimmedDisplayName.isEmpty ? "Workspace" : trimmedDisplayName

        let trimmedPath = directoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let basename = trimmedPath.isEmpty
            ? ""
            : URL(fileURLWithPath: trimmedPath).lastPathComponent
                .trimmingCharacters(in: .whitespacesAndNewlines)
        self.directoryBasename = basename.isEmpty ? "Home" : basename
    }
}

public protocol WorkspaceMetadataIndexClient: Sendable {
    func index(_ items: [CSSearchableItem]) async throws
    func deleteAll(domainIdentifier: String) async throws
}

public struct CoreSpotlightWorkspaceMetadataIndexClient: WorkspaceMetadataIndexClient {
    public init() {}

    public func index(_ items: [CSSearchableItem]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func deleteAll(domainIdentifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

public struct WorkspaceMetadataIndexer: Sendable {
    public static let domainIdentifier = "com.aaldere1.gridos.workspace-metadata"

    private let client: any WorkspaceMetadataIndexClient

    public init(client: any WorkspaceMetadataIndexClient = CoreSpotlightWorkspaceMetadataIndexClient()) {
        self.client = client
    }

    public func searchableItem(for metadata: WorkspaceSearchMetadata) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        attributeSet.title = metadata.displayName
        attributeSet.displayName = metadata.directoryBasename
        attributeSet.keywords = [metadata.displayName, metadata.directoryBasename]

        let item = CSSearchableItem(
            uniqueIdentifier: metadata.id,
            domainIdentifier: Self.domainIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = .distantFuture
        return item
    }

    public func index(_ metadataItems: [WorkspaceSearchMetadata]) async throws {
        try await client.index(metadataItems.map(searchableItem(for:)))
    }

    public func deleteAll() async throws {
        try await client.deleteAll(domainIdentifier: Self.domainIdentifier)
    }
}
