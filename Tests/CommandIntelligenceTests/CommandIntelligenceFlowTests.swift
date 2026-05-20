import XCTest
@testable import CommandIntelligence

final class CommandIntelligenceFlowTests: XCTestCase {
    func testMissingKeyDoesNotInvokeProvider() async {
        let provider = RecordingCommandProvider(providerID: .anthropic)
        let service = CommandIntelligenceService(
            credentialStore: InMemoryCommandCredentialStore(),
            provider: provider,
            riskClassifier: CommandRiskClassifier()
        )

        let result = await service.completeApprovedRequest(preview: approvedPreview())

        XCTAssertEqual(result.failure, .noProviderKey())
        XCTAssertEqual(await provider.invocationCount, 0)
    }

    func testDebugFixtureDoesNotRequireProviderKey() async {
        let service = CommandIntelligenceService(
            credentialStore: InMemoryCommandCredentialStore(),
            provider: DebugCommandIntelligenceFixtureProvider(),
            riskClassifier: CommandRiskClassifier()
        )

        let result = await service.completeApprovedRequest(preview: approvedPreview(prompt: "PHASE6_INSERT"))

        XCTAssertNil(result.failure)
        XCTAssertEqual(result.completion?.commands.first?.command.command, "printf 'PHASE6_INSERT\\n' > /tmp/gridos_phase6_insert.txt")
        XCTAssertEqual(result.completion?.commands.first?.localRisk.level, .low)
    }

    func testBlockedPreviewDoesNotInvokeProvider() async {
        let provider = RecordingCommandProvider(providerID: .debugSmokeFixture)
        let service = CommandIntelligenceService(
            credentialStore: InMemoryCommandCredentialStore(),
            provider: provider,
            riskClassifier: CommandRiskClassifier()
        )

        let result = await service.completeApprovedRequest(preview: blockedPreview())

        XCTAssertEqual(result.failure, .redactionBlocked(reasons: ["Private key block detected."]))
        XCTAssertEqual(await provider.invocationCount, 0)
    }

    func testProviderFailureMapsToProductCopy() async {
        let provider = RecordingCommandProvider(providerID: .debugSmokeFixture, failure: .offline())
        let service = CommandIntelligenceService(
            credentialStore: InMemoryCommandCredentialStore(),
            provider: provider,
            riskClassifier: CommandRiskClassifier()
        )

        let result = await service.completeApprovedRequest(preview: approvedPreview())

        XCTAssertEqual(result.failure?.title, "Provider unreachable")
        XCTAssertEqual(result.failure?.recoveryAction, "Retry Request")
    }

    func testExplainOnlyResponsesHaveNoCommandsByDefault() async {
        let provider = RecordingCommandProvider(
            providerID: .debugSmokeFixture,
            response: LLMCommandResponse(
                summary: "Output explained.",
                commands: [],
                explanation: "The output is informational."
            )
        )
        let service = CommandIntelligenceService(
            credentialStore: InMemoryCommandCredentialStore(),
            provider: provider,
            riskClassifier: CommandRiskClassifier()
        )

        let result = await service.completeApprovedRequest(preview: approvedPreview(flow: .explainOutput))

        XCTAssertEqual(result.completion?.flow, .explainOutput)
        XCTAssertEqual(result.completion?.commands, [])
        XCTAssertNil(result.failure)
    }

    func testGeneratedCommandsAreLocallyReclassified() async {
        let provider = RecordingCommandProvider(
            providerID: .debugSmokeFixture,
            response: LLMCommandResponse(
                summary: "Dangerous command suggested.",
                commands: [
                    GeneratedCommand(
                        command: "rm -rf ~/tmp/gridos-test",
                        explanation: "Remove test directory.",
                        workingDirectoryAssumption: "Current terminal directory",
                        contextUsed: [.prompt],
                        providerRiskLabel: "low"
                    )
                ],
                explanation: "Use caution."
            )
        )
        let service = CommandIntelligenceService(
            credentialStore: InMemoryCommandCredentialStore(),
            provider: provider,
            riskClassifier: CommandRiskClassifier()
        )

        let result = await service.completeApprovedRequest(preview: approvedPreview())

        XCTAssertEqual(result.completion?.commands.first?.command.providerRiskLabel, "low")
        XCTAssertEqual(result.completion?.commands.first?.localRisk.level, .high)
        XCTAssertEqual(result.completion?.commands.first?.localRisk.policy, .insertOnly)
    }
}

private actor RecordingCommandProvider: LLMCommandProvider {
    let providerID: LLMProviderID
    private let response: LLMCommandResponse
    private let failure: CommandIntelligenceFailure?
    private(set) var invocationCount = 0

    init(
        providerID: LLMProviderID,
        response: LLMCommandResponse = LLMCommandResponse(
            summary: "Command ready.",
            commands: [
                GeneratedCommand(
                    command: "pwd",
                    explanation: "Print the working directory.",
                    workingDirectoryAssumption: "Current terminal directory",
                    contextUsed: [.prompt],
                    providerRiskLabel: "low"
                )
            ],
            explanation: "The command inspects the current directory."
        ),
        failure: CommandIntelligenceFailure? = nil
    ) {
        self.providerID = providerID
        self.response = response
        self.failure = failure
    }

    func complete(_ request: LLMCommandRequest, apiKey: String) async throws -> LLMCommandResponse {
        invocationCount += 1

        if let failure {
            throw failure
        }

        return response
    }
}

private func approvedPreview(
    flow: CommandIntelligenceFlow = .suggestCommand,
    prompt: String = "show current directory"
) -> CommandContextPreview {
    let payload = ApprovedCommandContextPayload(
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

    return CommandContextPreview(flow: flow, approvedPayload: payload)
}

private func blockedPreview() -> CommandContextPreview {
    let payload = ApprovedCommandContextPayload(
        redactedBlocks: [
            ApprovedCommandContextBlock(
                source: .prompt,
                label: CommandContextSource.prompt.previewLabel,
                redactedText: "[redacted private key]",
                characterCount: 24
            )
        ],
        includedContextSourceLabels: [CommandContextSource.prompt.previewLabel],
        redactionSummaries: [
            CommandRedactionSummary(label: "privateKey", count: 1)
        ],
        blockedReasons: ["Private key block detected."]
    )

    return CommandContextPreview(flow: .suggestCommand, approvedPayload: payload)
}
