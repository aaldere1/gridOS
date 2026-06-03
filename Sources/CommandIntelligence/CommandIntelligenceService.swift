import Foundation

public struct ClassifiedGeneratedCommand: Codable, Equatable, Sendable {
    public let command: GeneratedCommand
    public let localRisk: CommandRiskAssessment

    public init(command: GeneratedCommand, localRisk: CommandRiskAssessment) {
        self.command = command
        self.localRisk = localRisk
    }
}

public struct CommandIntelligenceCompletion: Codable, Equatable, Sendable {
    public let flow: CommandIntelligenceFlow
    public let summary: String
    public let explanation: String
    public let commands: [ClassifiedGeneratedCommand]
    public let requestID: String?

    public init(
        flow: CommandIntelligenceFlow,
        summary: String,
        explanation: String,
        commands: [ClassifiedGeneratedCommand],
        requestID: String? = nil
    ) {
        self.flow = flow
        self.summary = summary
        self.explanation = explanation
        self.commands = commands
        self.requestID = requestID
    }
}

public enum CommandIntelligenceServiceResult: Equatable, Sendable {
    case completion(CommandIntelligenceCompletion)
    case failure(CommandIntelligenceFailure)

    public var completion: CommandIntelligenceCompletion? {
        if case let .completion(completion) = self {
            return completion
        }

        return nil
    }

    public var failure: CommandIntelligenceFailure? {
        if case let .failure(failure) = self {
            return failure
        }

        return nil
    }
}

public struct CommandIntelligenceService: Sendable {
    private let credentialStore: any CommandCredentialStore
    private let provider: any LLMCommandProvider
    private let riskClassifier: CommandRiskClassifier

    public init(
        credentialStore: any CommandCredentialStore,
        provider: any LLMCommandProvider,
        riskClassifier: CommandRiskClassifier = CommandRiskClassifier()
    ) {
        self.credentialStore = credentialStore
        self.provider = provider
        self.riskClassifier = riskClassifier
    }

    public func completeApprovedRequest(
        preview: CommandContextPreview,
        providerID: LLMProviderID? = nil,
        modelID: LLMModelID = LLMModelID()
    ) async -> CommandIntelligenceServiceResult {
        guard preview.canSend else {
            return .failure(.redactionBlocked(reasons: preview.blockedReasons))
        }

        let resolvedProviderID = providerID ?? provider.providerID
        let request = LLMCommandRequest(
            providerID: resolvedProviderID,
            modelID: modelID,
            flow: preview.flow,
            approvedPreview: preview.approvedPayload
        )

        let apiKey: String
        if resolvedProviderID == .debugSmokeFixture {
            apiKey = "debug-smoke-fixture-no-key-required"
        } else {
            do {
                guard let storedAPIKey = try await credentialStore.apiKey(for: resolvedProviderID),
                      !storedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return .failure(.noProviderKey())
                }

                apiKey = storedAPIKey
            } catch let failure as CommandIntelligenceFailure {
                return .failure(failure)
            } catch {
                return .failure(.providerError())
            }
        }

        do {
            let response = try await provider.complete(request, apiKey: apiKey)
            let commands = response.commands.map { generatedCommand in
                ClassifiedGeneratedCommand(
                    command: generatedCommand,
                    localRisk: riskClassifier.classify(generatedCommand.command)
                )
            }

            return .completion(
                CommandIntelligenceCompletion(
                    flow: preview.flow,
                    summary: response.summary,
                    explanation: response.explanation,
                    commands: commands,
                    requestID: response.requestID
                )
            )
        } catch let failure as CommandIntelligenceFailure {
            return .failure(failure)
        } catch {
            return .failure(.providerError())
        }
    }
}
