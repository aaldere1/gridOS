import Foundation

public enum CommandIntelligenceFlow: String, CaseIterable, Codable, Sendable {
    case suggestCommand
    case explainOutput
    case failedCommandHelp
}

public struct LLMProviderID: RawRepresentable, Codable, Equatable, Hashable, Sendable, ExpressibleByStringLiteral {
    public static let anthropic = LLMProviderID("anthropic")
    public static let debugSmokeFixture = LLMProviderID("debug-smoke-fixture")

    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct LLMModelID: RawRepresentable, Codable, Equatable, Hashable, Sendable, ExpressibleByStringLiteral {
    public static let claudeSonnet46 = LLMModelID("claude-sonnet-4-6")

    public let rawValue: String

    public init(_ rawValue: String = "claude-sonnet-4-6") {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct CommandAssistanceInput: Codable, Equatable, Sendable {
    public let flow: CommandIntelligenceFlow
    public let userPrompt: String
    public let workingDirectory: String?
    public let selectedOrPastedOutput: String?
    public let failedCommand: String?
    public let failedCommandOutput: String?

    public init(
        flow: CommandIntelligenceFlow,
        userPrompt: String,
        workingDirectory: String? = nil,
        selectedOrPastedOutput: String? = nil,
        failedCommand: String? = nil,
        failedCommandOutput: String? = nil
    ) {
        self.flow = flow
        self.userPrompt = userPrompt
        self.workingDirectory = workingDirectory
        self.selectedOrPastedOutput = selectedOrPastedOutput
        self.failedCommand = failedCommand
        self.failedCommandOutput = failedCommandOutput
    }
}

public enum CommandContextSource: String, CaseIterable, Codable, Sendable {
    case prompt
    case workingDirectory
    case selectedOutput
    case pastedOutput
    case failedCommand
    case failedOutput
}

public struct GeneratedCommand: Codable, Equatable, Sendable {
    public let command: String
    public let explanation: String
    public let workingDirectoryAssumption: String
    public let contextUsed: [CommandContextSource]
    public let providerRiskLabel: String

    public init(
        command: String,
        explanation: String,
        workingDirectoryAssumption: String,
        contextUsed: [CommandContextSource],
        providerRiskLabel: String
    ) {
        self.command = command
        self.explanation = explanation
        self.workingDirectoryAssumption = workingDirectoryAssumption
        self.contextUsed = contextUsed
        self.providerRiskLabel = providerRiskLabel
    }
}

public struct LLMCommandResponse: Codable, Equatable, Sendable {
    public let summary: String
    public let commands: [GeneratedCommand]
    public let explanation: String
    public let requestID: String?

    public init(
        summary: String,
        commands: [GeneratedCommand],
        explanation: String,
        requestID: String? = nil
    ) {
        self.summary = summary
        self.commands = commands
        self.explanation = explanation
        self.requestID = requestID
    }
}
