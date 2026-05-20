import Foundation

public struct CommandContextBuilder: Sendable {
    private let redactor: SecretRedactor

    public init(redactor: SecretRedactor = SecretRedactor()) {
        self.redactor = redactor
    }

    public func buildPreview(from input: CommandAssistanceInput) -> CommandContextPreview {
        let candidates = contextCandidates(from: input)
        var blocks: [ApprovedCommandContextBlock] = []
        var findings: [RedactionFinding] = []
        var blockedReasons: [String] = []

        for candidate in candidates {
            let result = redactor.redact(candidate.text)

            blocks.append(
                ApprovedCommandContextBlock(
                    source: candidate.source,
                    label: candidate.label,
                    redactedText: result.redactedText,
                    characterCount: candidate.text.count
                )
            )
            findings.append(contentsOf: result.findings)

            for reason in result.blockedReasons where !blockedReasons.contains(reason) {
                blockedReasons.append(reason)
            }
        }

        let summaries = redactionSummaries(from: findings)
        let payload = ApprovedCommandContextPayload(
            redactedBlocks: blocks,
            includedContextSourceLabels: blocks.map(\.label),
            redactionSummaries: summaries,
            blockedReasons: blockedReasons
        )

        return CommandContextPreview(
            flow: input.flow,
            contextBlocks: blocks,
            redactionFindings: findings,
            approvedPayload: payload
        )
    }

    private func contextCandidates(from input: CommandAssistanceInput) -> [ContextCandidate] {
        [
            OptionalContextCandidate(source: .prompt, label: CommandContextSource.prompt.previewLabel, text: input.userPrompt),
            OptionalContextCandidate(source: .workingDirectory, label: CommandContextSource.workingDirectory.previewLabel, text: input.workingDirectory),
            OptionalContextCandidate(source: .selectedOutput, label: CommandContextSource.selectedOutput.previewLabel, text: input.selectedOrPastedOutput),
            OptionalContextCandidate(source: .failedCommand, label: CommandContextSource.failedCommand.previewLabel, text: input.failedCommand),
            OptionalContextCandidate(source: .failedOutput, label: CommandContextSource.failedOutput.previewLabel, text: input.failedCommandOutput)
        ]
        .compactMap { candidate in
            guard let text = candidate.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return nil
            }

            return ContextCandidate(source: candidate.source, label: candidate.label, text: text)
        }
    }

    private func redactionSummaries(from findings: [RedactionFinding]) -> [CommandRedactionSummary] {
        RedactionKind.allCases.compactMap { kind in
            let count = findings.filter { $0.kind == kind }.count
            guard count > 0 else { return nil }
            return CommandRedactionSummary(label: kind.label, count: count)
        }
    }

    private struct ContextCandidate {
        let source: CommandContextSource
        let label: String
        let text: String
    }

    private struct OptionalContextCandidate {
        let source: CommandContextSource
        let label: String
        let text: String?
    }
}
