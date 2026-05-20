import XCTest
@testable import CommandIntelligence

final class CommandIntelligenceModelTests: XCTestCase {
    func testFlowRawValuesAreStable() {
        XCTAssertEqual(CommandIntelligenceFlow.suggestCommand.rawValue, "suggestCommand")
        XCTAssertEqual(CommandIntelligenceFlow.explainOutput.rawValue, "explainOutput")
        XCTAssertEqual(CommandIntelligenceFlow.failedCommandHelp.rawValue, "failedCommandHelp")
        XCTAssertEqual(CommandIntelligenceFlow.allCases, [.suggestCommand, .explainOutput, .failedCommandHelp])
    }

    func testProviderAndModelDefaultsAreStable() {
        let provider: LLMProviderID = "anthropic"
        let defaultModel = LLMModelID()

        XCTAssertEqual(provider, .anthropic)
        XCTAssertEqual(LLMProviderID.anthropic.rawValue, "anthropic")
        XCTAssertEqual(defaultModel.rawValue, "claude-sonnet-4-6")
    }

    func testCommandAssistanceInputPreservesExplicitContextOnly() {
        let input = CommandAssistanceInput(
            flow: .failedCommandHelp,
            userPrompt: "Help fix this command",
            workingDirectory: "/Users/example/project",
            selectedOrPastedOutput: "permission denied",
            failedCommand: "cat secret.txt",
            failedCommandOutput: "permission denied"
        )

        XCTAssertEqual(input.flow, .failedCommandHelp)
        XCTAssertEqual(input.userPrompt, "Help fix this command")
        XCTAssertEqual(input.workingDirectory, "/Users/example/project")
        XCTAssertEqual(input.selectedOrPastedOutput, "permission denied")
        XCTAssertEqual(input.failedCommand, "cat secret.txt")
        XCTAssertEqual(input.failedCommandOutput, "permission denied")
    }

    func testApprovedPayloadPreservesFields() {
        let payload = ApprovedCommandContextPayload(
            redactedBlocks: [
                ApprovedCommandContextBlock(
                    source: .prompt,
                    label: "Prompt",
                    redactedText: "List Swift files",
                    characterCount: 16
                ),
                ApprovedCommandContextBlock(
                    source: .selectedOutput,
                    label: "Selected Output",
                    redactedText: "token=[REDACTED]",
                    characterCount: 16
                )
            ],
            includedContextSourceLabels: ["Prompt", "Selected Output"],
            redactionSummaries: [
                CommandRedactionSummary(label: "API key", count: 1),
                CommandRedactionSummary(label: "Bearer token", count: 2)
            ],
            blockedReasons: ["Private key block requires review"]
        )
        let preview = CommandContextPreview(approvedPayload: payload)

        XCTAssertEqual(preview.approvedPayload, payload)
        XCTAssertEqual(payload.redactedBlocks.map(\.source), [.prompt, .selectedOutput])
        XCTAssertEqual(payload.includedContextSourceLabels, ["Prompt", "Selected Output"])
        XCTAssertEqual(payload.redactionSummaries.map(\.label), ["API key", "Bearer token"])
        XCTAssertEqual(payload.redactionSummaries.map(\.count), [1, 2])
        XCTAssertEqual(payload.blockedReasons, ["Private key block requires review"])
    }

    func testProviderRequestUsesApprovedPreviewPayload() {
        let payload = ApprovedCommandContextPayload(
            redactedBlocks: [
                ApprovedCommandContextBlock(
                    source: .workingDirectory,
                    label: "Working Directory",
                    redactedText: "/Users/example/project",
                    characterCount: 22
                )
            ],
            includedContextSourceLabels: ["Working Directory"],
            redactionSummaries: [],
            blockedReasons: []
        )
        let request = LLMCommandRequest(
            providerID: .anthropic,
            modelID: LLMModelID(),
            flow: .suggestCommand,
            approvedPreview: payload
        )

        XCTAssertEqual(request.providerID, .anthropic)
        XCTAssertEqual(request.modelID.rawValue, "claude-sonnet-4-6")
        XCTAssertEqual(request.flow, .suggestCommand)
        XCTAssertEqual(request.approvedPreview, payload)
    }

    func testGeneratedCommandAndResponsePreserveProviderFields() {
        let command = GeneratedCommand(
            command: "find . -name '*.swift'",
            explanation: "Searches the current project for Swift files.",
            workingDirectoryAssumption: "/Users/example/project",
            contextUsed: [.prompt, .workingDirectory],
            providerRiskLabel: "low"
        )
        let response = LLMCommandResponse(
            summary: "Use find for a local filename search.",
            commands: [command],
            explanation: "The command reads file names without changing files.",
            requestID: "req-123"
        )

        XCTAssertEqual(command.command, "find . -name '*.swift'")
        XCTAssertEqual(command.explanation, "Searches the current project for Swift files.")
        XCTAssertEqual(command.workingDirectoryAssumption, "/Users/example/project")
        XCTAssertEqual(command.contextUsed, [.prompt, .workingDirectory])
        XCTAssertEqual(command.providerRiskLabel, "low")
        XCTAssertEqual(response.summary, "Use find for a local filename search.")
        XCTAssertEqual(response.commands, [command])
        XCTAssertEqual(response.explanation, "The command reads file names without changing files.")
        XCTAssertEqual(response.requestID, "req-123")
    }
}
