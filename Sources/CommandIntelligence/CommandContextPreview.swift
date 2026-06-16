import Foundation

public struct CommandContextPreview: Codable, Equatable, Sendable {
    public let flow: CommandIntelligenceFlow
    public let flowName: String
    public let contextBlocks: [ApprovedCommandContextBlock]
    public let redactionFindings: [RedactionFinding]
    public let approvedPayload: ApprovedCommandContextPayload

    public var redactionSummaries: [CommandRedactionSummary] {
        approvedPayload.redactionSummaries
    }

    public var blockedReasons: [String] {
        approvedPayload.blockedReasons
    }

    public var canSend: Bool {
        !approvedPayload.isBlocked
    }

    public init(
        flow: CommandIntelligenceFlow = .suggestCommand,
        contextBlocks: [ApprovedCommandContextBlock]? = nil,
        redactionFindings: [RedactionFinding] = [],
        approvedPayload: ApprovedCommandContextPayload
    ) {
        self.flow = flow
        self.flowName = flow.previewName
        self.contextBlocks = contextBlocks ?? approvedPayload.redactedBlocks
        self.redactionFindings = redactionFindings
        self.approvedPayload = approvedPayload
    }
}

public struct ApprovedCommandContextPayload: Codable, Equatable, Sendable {
    public let redactedSections: [CommandContextSource: String]
    public let redactionSummary: [String: Int]
    public let redactedBlocks: [ApprovedCommandContextBlock]
    public let includedContextSourceLabels: [String]
    public let redactionSummaries: [CommandRedactionSummary]
    public let blockedReasons: [String]

    public var isBlocked: Bool {
        !blockedReasons.isEmpty
    }

    public init(
        redactedBlocks: [ApprovedCommandContextBlock],
        includedContextSourceLabels: [String],
        redactionSummaries: [CommandRedactionSummary],
        blockedReasons: [String]
    ) {
        self.redactedBlocks = redactedBlocks
        self.includedContextSourceLabels = includedContextSourceLabels
        self.redactionSummaries = redactionSummaries
        self.blockedReasons = blockedReasons

        var sections: [CommandContextSource: String] = [:]
        for block in redactedBlocks {
            sections[block.source] = block.redactedText
        }
        self.redactedSections = sections

        var summary: [String: Int] = [:]
        for item in redactionSummaries {
            summary[item.label] = item.count
        }
        self.redactionSummary = summary
    }

    public init(
        redactedSections: [CommandContextSource: String],
        redactionSummary: [String: Int],
        blockedReasons: [String]
    ) {
        let blocks = CommandContextSource.allCases.compactMap { source -> ApprovedCommandContextBlock? in
            guard let redactedText = redactedSections[source] else { return nil }

            return ApprovedCommandContextBlock(
                source: source,
                label: source.previewLabel,
                redactedText: redactedText,
                characterCount: redactedText.count
            )
        }

        let summaries = redactionSummary.keys.sorted().compactMap { label -> CommandRedactionSummary? in
            guard let count = redactionSummary[label] else { return nil }
            return CommandRedactionSummary(label: label, count: count)
        }

        self.redactedSections = redactedSections
        self.redactionSummary = redactionSummary
        self.redactedBlocks = blocks
        self.includedContextSourceLabels = blocks.map(\.label)
        self.redactionSummaries = summaries
        self.blockedReasons = blockedReasons
    }
}

public struct ApprovedCommandContextBlock: Codable, Equatable, Sendable {
    public let source: CommandContextSource
    public let label: String
    public let redactedText: String
    public let characterCount: Int

    public init(
        source: CommandContextSource,
        label: String,
        redactedText: String,
        characterCount: Int
    ) {
        self.source = source
        self.label = label
        self.redactedText = redactedText
        self.characterCount = characterCount
    }
}

public struct CommandRedactionSummary: Codable, Equatable, Sendable {
    public let label: String
    public let count: Int

    public init(label: String, count: Int) {
        self.label = label
        self.count = count
    }
}

public extension CommandIntelligenceFlow {
    var previewName: String {
        switch self {
        case .suggestCommand:
            "Suggest Command"
        case .explainOutput:
            "Explain Output"
        case .failedCommandHelp:
            "Fix Failed Command"
        }
    }
}

public extension CommandContextSource {
    var previewLabel: String {
        switch self {
        case .prompt:
            "User Prompt"
        case .workingDirectory:
            "Working Directory"
        case .selectedOutput:
            "Selected or Pasted Output"
        case .pastedOutput:
            "Pasted Output"
        case .screenshotAttachments:
            "Screenshot Attachments"
        case .failedCommand:
            "Failed Command"
        case .failedOutput:
            "Failed Output"
        }
    }
}
