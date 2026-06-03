import Foundation

public enum CommandIntelligenceFlow: String, CaseIterable, Codable, Sendable {
    case suggestCommand
    case explainOutput
    case failedCommandHelp
}

public struct LLMProviderID: RawRepresentable, Codable, Equatable, Hashable, Sendable, ExpressibleByStringLiteral {
    public static let anthropic = LLMProviderID("anthropic")
    public static let openAI = LLMProviderID("openai")
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
    public static let claudeOpus48 = LLMModelID("claude-opus-4-8")
    public static let claudeSonnet46 = LLMModelID("claude-sonnet-4-6")
    public static let claudeHaiku45 = LLMModelID("claude-haiku-4-5")
    public static let gpt55 = LLMModelID("gpt-5.5")
    public static let gpt54 = LLMModelID("gpt-5.4")
    public static let gpt54Mini = LLMModelID("gpt-5.4-mini")
    public static let gpt54Nano = LLMModelID("gpt-5.4-nano")

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

public struct LLMModelDescriptor: Identifiable, Equatable, Sendable {
    public let id: LLMModelID
    public let displayName: String
    public let detail: String
    public let isRecommended: Bool

    public init(
        id: LLMModelID,
        displayName: String,
        detail: String,
        isRecommended: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.detail = detail
        self.isRecommended = isRecommended
    }
}

public struct LLMProviderDescriptor: Identifiable, Equatable, Sendable {
    public let id: LLMProviderID
    public let displayName: String
    public let apiKeyLabel: String
    public let apiKeyPlaceholder: String
    public let setupHint: String
    public let defaultModelID: LLMModelID
    public let models: [LLMModelDescriptor]

    public init(
        id: LLMProviderID,
        displayName: String,
        apiKeyLabel: String,
        apiKeyPlaceholder: String,
        setupHint: String,
        defaultModelID: LLMModelID,
        models: [LLMModelDescriptor]
    ) {
        self.id = id
        self.displayName = displayName
        self.apiKeyLabel = apiKeyLabel
        self.apiKeyPlaceholder = apiKeyPlaceholder
        self.setupHint = setupHint
        self.defaultModelID = defaultModelID
        self.models = models
    }
}

public enum CommandIntelligenceModelCatalog {
    public static let anthropic = LLMProviderDescriptor(
        id: .anthropic,
        displayName: "Anthropic",
        apiKeyLabel: "Anthropic API key",
        apiKeyPlaceholder: "sk-ant-...",
        setupHint: "Uses Claude through Anthropic Messages. Keys stay in your Mac Keychain.",
        defaultModelID: .claudeSonnet46,
        models: [
            LLMModelDescriptor(
                id: .claudeOpus48,
                displayName: "Claude Opus 4.8",
                detail: "Most capable Claude for complex reasoning and high-autonomy command planning."
            ),
            LLMModelDescriptor(
                id: .claudeSonnet46,
                displayName: "Claude Sonnet 4.6",
                detail: "Recommended balance of speed and intelligence for AI Command Helper.",
                isRecommended: true
            ),
            LLMModelDescriptor(
                id: .claudeHaiku45,
                displayName: "Claude Haiku 4.5",
                detail: "Fastest Claude choice for simple command help."
            )
        ]
    )

    public static let openAI = LLMProviderDescriptor(
        id: .openAI,
        displayName: "OpenAI",
        apiKeyLabel: "OpenAI API key",
        apiKeyPlaceholder: "sk-proj-...",
        setupHint: "Uses OpenAI Responses. Keys stay in your Mac Keychain.",
        defaultModelID: .gpt55,
        models: [
            LLMModelDescriptor(
                id: .gpt55,
                displayName: "GPT-5.5",
                detail: "Recommended OpenAI model for complex command reasoning and polish.",
                isRecommended: true
            ),
            LLMModelDescriptor(
                id: .gpt54,
                displayName: "GPT-5.4",
                detail: "Strong general command reasoning at lower cost than GPT-5.5."
            ),
            LLMModelDescriptor(
                id: .gpt54Mini,
                displayName: "GPT-5.4 mini",
                detail: "Faster and cheaper for common shell tasks."
            ),
            LLMModelDescriptor(
                id: .gpt54Nano,
                displayName: "GPT-5.4 nano",
                detail: "Lowest-latency OpenAI option for lightweight assistance."
            )
        ]
    )

    public static let providers: [LLMProviderDescriptor] = [
        anthropic,
        openAI
    ]

    public static func descriptor(for providerID: LLMProviderID) -> LLMProviderDescriptor {
        providers.first { $0.id == providerID } ?? anthropic
    }

    public static func defaultModelID(for providerID: LLMProviderID) -> LLMModelID {
        descriptor(for: providerID).defaultModelID
    }

    public static func knownModelDescriptor(
        _ modelID: LLMModelID,
        providerID: LLMProviderID
    ) -> LLMModelDescriptor? {
        descriptor(for: providerID).models.first { $0.id == modelID }
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
