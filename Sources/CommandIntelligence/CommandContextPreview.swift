import Foundation

public struct CommandContextPreview: Codable, Equatable, Sendable {
    public let approvedPayload: ApprovedCommandContextPayload

    public init(approvedPayload: ApprovedCommandContextPayload) {
        self.approvedPayload = approvedPayload
    }
}

public struct ApprovedCommandContextPayload: Codable, Equatable, Sendable {
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
