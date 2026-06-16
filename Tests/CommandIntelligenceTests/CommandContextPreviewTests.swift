import XCTest
@testable import CommandIntelligence

final class CommandContextPreviewTests: XCTestCase {
    func testPreviewPayloadContainsOnlyRedactedContext() {
        let input = CommandAssistanceInput(
            flow: .failedCommandHelp,
            userPrompt: "Why did this deployment fail with sk-ant-api03-secretVALUE?",
            workingDirectory: "/Users/example/project",
            selectedOrPastedOutput: "Authorization: Bearer bearer-secret-value",
            failedCommand: "curl https://user:pass@example.com/deploy",
            failedCommandOutput: "TOKEN=raw-token-value"
        )

        let preview = CommandContextBuilder().buildPreview(from: input)
        let payloadText = preview.approvedPayload.redactedBlocks
            .map(\.redactedText)
            .joined(separator: "\n")

        XCTAssertEqual(preview.flow, .failedCommandHelp)
        XCTAssertEqual(preview.flowName, "Fix Failed Command")
        XCTAssertTrue(preview.canSend)
        XCTAssertFalse(payloadText.contains("sk-ant-api03-secretVALUE"))
        XCTAssertFalse(payloadText.contains("bearer-secret-value"))
        XCTAssertFalse(payloadText.contains("user:pass"))
        XCTAssertFalse(payloadText.contains("raw-token-value"))
        XCTAssertTrue(payloadText.contains("[REDACTED API KEY]"))
        XCTAssertTrue(payloadText.contains("[REDACTED BEARER TOKEN]"))
        XCTAssertTrue(payloadText.contains("[REDACTED CREDENTIAL URL]"))
        XCTAssertTrue(payloadText.contains("[REDACTED ENV VALUE]"))
    }

    func testPreviewIncludesPromptCwdSelectedOutputAndFailedCommandBlocks() {
        let input = CommandAssistanceInput(
            flow: .failedCommandHelp,
            userPrompt: "Explain this failure",
            workingDirectory: "/tmp/gridos",
            selectedOrPastedOutput: "permission denied",
            failedCommand: "cat restricted.txt",
            failedCommandOutput: "cat: restricted.txt: Permission denied"
        )

        let preview = CommandContextBuilder().buildPreview(from: input)

        XCTAssertEqual(
            preview.contextBlocks.map(\.source),
            [.prompt, .workingDirectory, .selectedOutput, .failedCommand, .failedOutput]
        )
        XCTAssertEqual(preview.approvedPayload.includedContextSourceLabels, [
            "User Prompt",
            "Working Directory",
            "Selected or Pasted Output",
            "Failed Command",
            "Failed Output"
        ])
        XCTAssertEqual(preview.contextBlocks.first?.characterCount, "Explain this failure".count)
    }

    func testPreviewIncludesRedactedScreenshotAttachmentContext() {
        let input = CommandAssistanceInput(
            flow: .explainOutput,
            userPrompt: "Explain the dropped screenshot",
            screenshotAttachmentContext: """
            Screenshot attachments
            gridOS extracted text locally from dropped screenshots. Image pixels and local file paths are not included in this provider context.

            Screenshot 1: failure.png
            Metadata: PNG | 1800x1200 | 944 KB
            Recognized text:
            TOKEN=raw-token-value
            xcodebuild failed with permission denied
            """
        )

        let preview = CommandContextBuilder().buildPreview(from: input)
        let screenshotBlock = preview.contextBlocks.first { $0.source == .screenshotAttachments }

        XCTAssertEqual(preview.contextBlocks.map(\.source), [.prompt, .screenshotAttachments])
        XCTAssertTrue(preview.approvedPayload.includedContextSourceLabels.contains("Screenshot Attachments"))
        XCTAssertEqual(screenshotBlock?.label, "Screenshot Attachments")
        XCTAssertTrue(screenshotBlock?.redactedText.contains("[REDACTED ENV VALUE]") ?? false)
        XCTAssertFalse(screenshotBlock?.redactedText.contains("raw-token-value") ?? true)
        XCTAssertTrue(screenshotBlock?.redactedText.contains("Image pixels and local file paths are not included") ?? false)
    }

    func testCanSendIsFalseWhenBlockedReasonsExist() {
        let input = CommandAssistanceInput(
            flow: .explainOutput,
            userPrompt: "Explain this key",
            selectedOrPastedOutput: """
            -----BEGIN PRIVATE KEY-----
            raw-private-key
            -----END PRIVATE KEY-----
            """
        )

        let preview = CommandContextBuilder().buildPreview(from: input)

        XCTAssertFalse(preview.canSend)
        XCTAssertFalse(preview.approvedPayload.blockedReasons.isEmpty)
        XCTAssertTrue(preview.approvedPayload.redactedBlocks.map(\.redactedText).joined().contains("[REDACTED PRIVATE KEY]"))
        XCTAssertFalse(preview.approvedPayload.redactedBlocks.map(\.redactedText).joined().contains("raw-private-key"))
    }

    func testProviderRequestCanOnlyUseApprovedPayload() {
        let preview = CommandContextBuilder().buildPreview(
            from: CommandAssistanceInput(
                flow: .suggestCommand,
                userPrompt: "List Swift files",
                workingDirectory: "/Users/example/project"
            )
        )

        let request = LLMCommandRequest(
            providerID: .anthropic,
            flow: .suggestCommand,
            approvedPreview: preview.approvedPayload
        )

        XCTAssertEqual(request.approvedPreview, preview.approvedPayload)
        XCTAssertEqual(request.flow, .suggestCommand)
    }

    func testPreviewDoesNotIncludeShellHistoryOrMetrics() {
        let input = CommandAssistanceInput(
            flow: .suggestCommand,
            userPrompt: "Find TODO comments",
            workingDirectory: "/Users/example/project"
        )

        let preview = CommandContextBuilder().buildPreview(from: input)
        let labelsAndPayload = (
            preview.approvedPayload.includedContextSourceLabels
            + preview.approvedPayload.redactedBlocks.map(\.redactedText)
        )
        .joined(separator: "\n")

        XCTAssertFalse(labelsAndPayload.localizedCaseInsensitiveContains("shell history"))
        XCTAssertFalse(labelsAndPayload.localizedCaseInsensitiveContains("environment variables"))
        XCTAssertFalse(labelsAndPayload.localizedCaseInsensitiveContains("process lists"))
        XCTAssertFalse(labelsAndPayload.localizedCaseInsensitiveContains("hidden files"))
        XCTAssertFalse(labelsAndPayload.localizedCaseInsensitiveContains("SSH config"))
        XCTAssertFalse(labelsAndPayload.localizedCaseInsensitiveContains("Keychain data"))
        XCTAssertFalse(labelsAndPayload.localizedCaseInsensitiveContains("metrics snapshots"))
        XCTAssertFalse(labelsAndPayload.localizedCaseInsensitiveContains("unrequested scrollback"))
    }
}
