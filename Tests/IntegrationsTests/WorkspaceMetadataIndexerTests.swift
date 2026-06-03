@preconcurrency import CoreSpotlight
@testable import Integrations
import XCTest

final class WorkspaceMetadataIndexerTests: XCTestCase {
    func testMetadataUsesDirectoryBasenameOnly() {
        let metadata = WorkspaceSearchMetadata(
            id: "workspace-alpha",
            displayName: "  Project Alpha  ",
            directoryPath: "/Users/example/private/ProjectAlpha"
        )

        XCTAssertEqual(metadata.id, "workspace-alpha")
        XCTAssertEqual(metadata.displayName, "Project Alpha")
        XCTAssertEqual(metadata.directoryBasename, "ProjectAlpha")
        XCTAssertFalse(metadata.directoryBasename.contains("/Users/example/private"))
    }

    func testBlankMetadataFallsBackToNeutralLabels() {
        let metadata = WorkspaceSearchMetadata(
            id: "  ",
            displayName: "  ",
            directoryPath: "  "
        )

        XCTAssertEqual(metadata.id, "workspace")
        XCTAssertEqual(metadata.displayName, "Workspace")
        XCTAssertEqual(metadata.directoryBasename, "Home")
    }

    func testSearchableItemUsesWorkspaceMetadataDomain() {
        let indexer = WorkspaceMetadataIndexer()
        let metadata = WorkspaceSearchMetadata(
            id: "workspace-build-lab",
            displayName: "Build Lab",
            directoryPath: "/Users/example/BuildLab"
        )

        let item = indexer.searchableItem(for: metadata)

        XCTAssertEqual(item.uniqueIdentifier, "workspace-build-lab")
        XCTAssertEqual(item.domainIdentifier, WorkspaceMetadataIndexer.domainIdentifier)
        XCTAssertEqual(item.attributeSet.title, "Build Lab")
        XCTAssertEqual(item.attributeSet.displayName, "BuildLab")
        XCTAssertNil(item.attributeSet.contentDescription)
    }

    func testIndexerPassesSearchableItemsToClientAndDeletesDomain() async throws {
        let client = RecordingWorkspaceMetadataIndexClient()
        let indexer = WorkspaceMetadataIndexer(client: client)
        let metadata = WorkspaceSearchMetadata(
            id: "workspace-gamma",
            displayName: "Ops",
            directoryPath: "/Users/example/Ops"
        )

        try await indexer.index([metadata])
        try await indexer.deleteAll()

        XCTAssertEqual(client.indexedItems.map(\.uniqueIdentifier), ["workspace-gamma"])
        XCTAssertEqual(client.deletedDomainIdentifiers, [WorkspaceMetadataIndexer.domainIdentifier])
    }

    func testMetadataSourceAvoidsPrivateFieldNames() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = repositoryRoot.appendingPathComponent("Sources/Integrations/WorkspaceMetadataIndexer.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let privacyAssertion = "Terminal output and command history are never indexed"
        let privateFieldNames = [
            ["shell", "History"].joined(),
            ["command", "Output"].joined(),
            ["terminal", "Transcript"].joined(),
            ["environment", "Variables"].joined(),
            ["process", "Args"].joined(),
            ["pro", "mpt"].joined(),
            ["generated", "Command"].joined()
        ]

        for fieldName in privateFieldNames {
            XCTAssertFalse(source.contains(fieldName), "\(privacyAssertion): \(fieldName)")
        }
    }
}

private final class RecordingWorkspaceMetadataIndexClient: WorkspaceMetadataIndexClient, @unchecked Sendable {
    private(set) var indexedItems: [CSSearchableItem] = []
    private(set) var deletedDomainIdentifiers: [String] = []

    func index(_ items: [CSSearchableItem]) async throws {
        indexedItems = items
    }

    func deleteAll(domainIdentifier: String) async throws {
        deletedDomainIdentifiers.append(domainIdentifier)
    }
}
