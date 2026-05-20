import Foundation

public protocol LLMCommandProvider: Sendable {
    var providerID: LLMProviderID { get }
    func complete(_ request: LLMCommandRequest, apiKey: String) async throws -> LLMCommandResponse
}

public struct LLMCommandRequest: Codable, Equatable, Sendable {
    public let providerID: LLMProviderID
    public let modelID: LLMModelID
    public let flow: CommandIntelligenceFlow
    public let approvedPreview: ApprovedCommandContextPayload

    public init(
        providerID: LLMProviderID,
        modelID: LLMModelID = LLMModelID(),
        flow: CommandIntelligenceFlow,
        approvedPreview: ApprovedCommandContextPayload
    ) {
        self.providerID = providerID
        self.modelID = modelID
        self.flow = flow
        self.approvedPreview = approvedPreview
    }
}
