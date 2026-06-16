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
        XCTAssertEqual(LLMProviderID.openAI.rawValue, "openai")
        XCTAssertEqual(LLMProviderID.deepSeek.rawValue, "deepseek")
        XCTAssertEqual(LLMProviderID.xAI.rawValue, "xai")
        XCTAssertEqual(defaultModel.rawValue, "claude-sonnet-4-20250514")
        XCTAssertEqual(LLMModelID.gpt52.rawValue, "gpt-5.2")
        XCTAssertEqual(LLMModelID.deepSeekV4Flash.rawValue, "deepseek-v4-flash")
        XCTAssertEqual(LLMModelID.grok43.rawValue, "grok-4.3")
    }

    func testModelCatalogExposesProviderChoices() {
        XCTAssertEqual(
            CommandIntelligenceModelCatalog.providers.map(\.id),
            [.anthropic, .openAI, .deepSeek, .xAI]
        )
        XCTAssertEqual(
            CommandIntelligenceModelCatalog.descriptor(for: .anthropic).models.map(\.id),
            [.claudeOpus41, .claudeSonnet4, .claudeSonnet37, .claudeHaiku35]
        )
        XCTAssertEqual(
            CommandIntelligenceModelCatalog.descriptor(for: .openAI).models.map(\.id),
            [.gpt52, .gpt5, .gpt5Mini, .gpt5Nano]
        )
        XCTAssertEqual(
            CommandIntelligenceModelCatalog.descriptor(for: .deepSeek).models.map(\.id),
            [.deepSeekV4Flash, .deepSeekV4Pro]
        )
        XCTAssertEqual(
            CommandIntelligenceModelCatalog.descriptor(for: .xAI).models.map(\.id),
            [.grok43, .grokBuild01]
        )
        XCTAssertEqual(CommandIntelligenceModelCatalog.defaultModelID(for: .openAI), .gpt52)
        XCTAssertEqual(CommandIntelligenceModelCatalog.defaultModelID(for: .deepSeek), .deepSeekV4Flash)
        XCTAssertEqual(CommandIntelligenceModelCatalog.defaultModelID(for: .xAI), .grok43)
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
        XCTAssertEqual(request.modelID.rawValue, "claude-sonnet-4-20250514")
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
