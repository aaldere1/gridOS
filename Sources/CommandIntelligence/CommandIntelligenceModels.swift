import Foundation

public enum CommandIntelligenceFlow: String, CaseIterable, Codable, Sendable {
    case suggestCommand
    case explainOutput
    case failedCommandHelp
}

public struct LLMProviderID: RawRepresentable, Codable, Equatable, Hashable, Sendable, ExpressibleByStringLiteral {
    public static let anthropic = LLMProviderID("anthropic")
    public static let openAI = LLMProviderID("openai")
    public static let deepSeek = LLMProviderID("deepseek")
    public static let xAI = LLMProviderID("xai")
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
    public static let claudeOpus41 = LLMModelID("claude-opus-4-1-20250805")
    public static let claudeSonnet4 = LLMModelID("claude-sonnet-4-20250514")
    public static let claudeSonnet37 = LLMModelID("claude-3-7-sonnet-20250219")
    public static let claudeHaiku35 = LLMModelID("claude-3-5-haiku-20241022")
    public static let gpt52 = LLMModelID("gpt-5.2")
    public static let gpt5 = LLMModelID("gpt-5")
    public static let gpt5Mini = LLMModelID("gpt-5-mini")
    public static let gpt5Nano = LLMModelID("gpt-5-nano")
    public static let deepSeekV4Flash = LLMModelID("deepseek-v4-flash")
    public static let deepSeekV4Pro = LLMModelID("deepseek-v4-pro")
    public static let grok43 = LLMModelID("grok-4.3")
    public static let grokBuild01 = LLMModelID("grok-build-0.1")

    public let rawValue: String

    public init(_ rawValue: String = "claude-sonnet-4-20250514") {
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
        defaultModelID: .claudeSonnet4,
        models: [
            LLMModelDescriptor(
                id: .claudeOpus41,
                displayName: "Claude Opus 4.1",
                detail: "Most capable stable Claude API choice for complex command reasoning."
            ),
            LLMModelDescriptor(
                id: .claudeSonnet4,
                displayName: "Claude Sonnet 4",
                detail: "Recommended balance of speed and intelligence for AI Command Helper.",
                isRecommended: true
            ),
            LLMModelDescriptor(
                id: .claudeSonnet37,
                displayName: "Claude Sonnet 3.7",
                detail: "Earlier strong Claude reasoning model for accounts pinned to 3.7."
            ),
            LLMModelDescriptor(
                id: .claudeHaiku35,
                displayName: "Claude Haiku 3.5",
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
        defaultModelID: .gpt52,
        models: [
            LLMModelDescriptor(
                id: .gpt52,
                displayName: "GPT-5.2",
                detail: "Recommended OpenAI model for complex command reasoning and polish.",
                isRecommended: true
            ),
            LLMModelDescriptor(
                id: .gpt5,
                displayName: "GPT-5",
                detail: "Strong general command reasoning with configurable reasoning effort."
            ),
            LLMModelDescriptor(
                id: .gpt5Mini,
                displayName: "GPT-5 mini",
                detail: "Faster and cheaper for common shell tasks."
            ),
            LLMModelDescriptor(
                id: .gpt5Nano,
                displayName: "GPT-5 nano",
                detail: "Lowest-latency OpenAI option for lightweight assistance."
            )
        ]
    )

    public static let deepSeek = LLMProviderDescriptor(
        id: .deepSeek,
        displayName: "DeepSeek",
        apiKeyLabel: "DeepSeek API key",
        apiKeyPlaceholder: "sk-...",
        setupHint: "Uses DeepSeek's OpenAI-compatible Chat Completions API. Keys stay in your Mac Keychain.",
        defaultModelID: .deepSeekV4Flash,
        models: [
            LLMModelDescriptor(
                id: .deepSeekV4Flash,
                displayName: "DeepSeek V4 Flash",
                detail: "Fast, low-cost DeepSeek model for everyday command help.",
                isRecommended: true
            ),
            LLMModelDescriptor(
                id: .deepSeekV4Pro,
                displayName: "DeepSeek V4 Pro",
                detail: "Stronger DeepSeek reasoning model for more complex terminal questions."
            )
        ]
    )

    public static let xAI = LLMProviderDescriptor(
        id: .xAI,
        displayName: "xAI",
        apiKeyLabel: "xAI API key",
        apiKeyPlaceholder: "xai-...",
        setupHint: "Uses xAI's OpenAI-compatible Responses API. Keys stay in your Mac Keychain.",
        defaultModelID: .grok43,
        models: [
            LLMModelDescriptor(
                id: .grok43,
                displayName: "Grok 4.3",
                detail: "Recommended xAI model for general command reasoning.",
                isRecommended: true
            ),
            LLMModelDescriptor(
                id: .grokBuild01,
                displayName: "Grok Build 0.1",
                detail: "xAI coding-focused model for agentic software and shell workflows."
            )
        ]
    )

    public static let providers: [LLMProviderDescriptor] = [
        anthropic,
        openAI,
        deepSeek,
        xAI
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
    public let screenshotAttachmentContext: String?
    public let failedCommand: String?
    public let failedCommandOutput: String?

    public init(
        flow: CommandIntelligenceFlow,
        userPrompt: String,
        workingDirectory: String? = nil,
        selectedOrPastedOutput: String? = nil,
        screenshotAttachmentContext: String? = nil,
        failedCommand: String? = nil,
        failedCommandOutput: String? = nil
    ) {
        self.flow = flow
        self.userPrompt = userPrompt
        self.workingDirectory = workingDirectory
        self.selectedOrPastedOutput = selectedOrPastedOutput
        self.screenshotAttachmentContext = screenshotAttachmentContext
        self.failedCommand = failedCommand
        self.failedCommandOutput = failedCommandOutput
    }
}

public enum CommandContextSource: String, CaseIterable, Codable, Sendable {
    case prompt
    case workingDirectory
    case selectedOutput
    case pastedOutput
    case screenshotAttachments
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
