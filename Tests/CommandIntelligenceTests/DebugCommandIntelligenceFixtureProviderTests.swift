import XCTest
@testable import CommandIntelligence

final class DebugCommandIntelligenceFixtureProviderTests: XCTestCase {
    func testFixtureReturnsPhase6InsertCommand() async throws {
        let provider = DebugCommandIntelligenceFixtureProvider()
        let request = LLMCommandRequest(
            providerID: .debugSmokeFixture,
            flow: .suggestCommand,
            approvedPreview: fixturePayload(prompt: "PHASE6_INSERT")
        )

        let response = try await provider.complete(request, apiKey: "")

        XCTAssertEqual(response.commands.first?.command, "printf 'PHASE6_INSERT\\n' > /tmp/gridos_phase6_insert.txt")
        XCTAssertEqual(response.commands.first?.providerRiskLabel, "low")
    }

    func testFixtureReturnsHighRiskSmokeCommand() async throws {
        let provider = DebugCommandIntelligenceFixtureProvider()
        let request = LLMCommandRequest(
            providerID: .debugSmokeFixture,
            flow: .suggestCommand,
            approvedPreview: fixturePayload(prompt: "PHASE6_HIGH_RISK")
        )

        let response = try await provider.complete(request, apiKey: "")

        XCTAssertEqual(response.commands.first?.command, "rm -rf ~/tmp/gridos-test")
        XCTAssertEqual(response.commands.first?.providerRiskLabel, "high")
    }
}

private func fixturePayload(prompt: String) -> ApprovedCommandContextPayload {
    ApprovedCommandContextPayload(
        redactedBlocks: [
            ApprovedCommandContextBlock(
                source: .prompt,
                label: CommandContextSource.prompt.previewLabel,
                redactedText: prompt,
                characterCount: prompt.count
            )
        ],
        includedContextSourceLabels: [CommandContextSource.prompt.previewLabel],
        redactionSummaries: [],
        blockedReasons: []
    )
}
