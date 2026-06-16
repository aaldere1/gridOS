import Foundation

public struct DeepSeekCommandProvider: LLMCommandProvider {
    public let providerID: LLMProviderID = .deepSeek

    public static let defaultBaseURL = URL(string: "https://api.deepseek.com")!
    public static let defaultModelID = LLMModelID("deepseek-v4-flash")
    public static let defaultMaxTokens = 1200

    private static let chatCompletionsPath = "/chat/completions"

    private let baseURL: URL
    private let transport: OpenAIHTTPTransport
    private let maxTokens: Int
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = DeepSeekCommandProvider.defaultBaseURL,
        transport: OpenAIHTTPTransport = URLSessionOpenAIHTTPTransport(),
        maxTokens: Int = DeepSeekCommandProvider.defaultMaxTokens
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.maxTokens = maxTokens
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func complete(_ request: LLMCommandRequest, apiKey: String) async throws -> LLMCommandResponse {
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAPIKey.isEmpty else {
            throw CommandIntelligenceFailure.noProviderKey()
        }

        var urlRequest = URLRequest(url: chatCompletionsURL())
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(trimmedAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try encoder.encode(chatRequest(from: request))

        let responseData: Data
        let httpResponse: HTTPURLResponse

        do {
            (responseData, httpResponse) = try await transport.data(for: urlRequest)
        } catch let urlError as URLError {
            throw mappedFailure(for: urlError)
        } catch let failure as CommandIntelligenceFailure {
            throw failure
        } catch {
            throw CommandIntelligenceFailure.providerError()
        }

        let requestID = httpResponse.openAICompatibleRequestID
        try validateStatusCode(httpResponse.statusCode, requestID: requestID)

        do {
            let deepSeekResponse = try decoder.decode(DeepSeekChatCompletionResponse.self, from: responseData)

            if let error = deepSeekResponse.error {
                throw CommandIntelligenceFailure.providerError(message: error.message, requestID: requestID ?? deepSeekResponse.id)
            }

            if deepSeekResponse.finishReason == "length" {
                throw CommandIntelligenceFailure.truncatedResponse(requestID: requestID ?? deepSeekResponse.id)
            }

            if deepSeekResponse.finishReason == "content_filter" {
                throw CommandIntelligenceFailure.providerRefusal(requestID: requestID ?? deepSeekResponse.id)
            }

            let providerPayload = try deepSeekResponse.responseJSONText()
            let decodedResponse = try decoder.decode(
                ProviderStructuredResponse.self,
                from: Data(providerPayload.utf8)
            )
            try decodedResponse.validate()

            return LLMCommandResponse(
                summary: decodedResponse.summary,
                commands: decodedResponse.commands,
                explanation: decodedResponse.explanation,
                requestID: decodedResponse.requestID ?? requestID ?? deepSeekResponse.id
            )
        } catch let failure as CommandIntelligenceFailure {
            throw failure
        } catch {
            throw CommandIntelligenceFailure.invalidProviderResponse(requestID: requestID)
        }
    }

    private func chatCompletionsURL() -> URL {
        URL(string: Self.chatCompletionsPath, relativeTo: baseURL)!.absoluteURL
    }

    private func chatRequest(from request: LLMCommandRequest) throws -> DeepSeekChatCompletionRequest {
        DeepSeekChatCompletionRequest(
            model: request.modelID.rawValue,
            messages: [
                DeepSeekChatMessage(role: "system", content: CommandProviderPrompt.systemInstruction),
                DeepSeekChatMessage(
                    role: "user",
                    content: try CommandProviderPrompt.userMessageContent(from: request, encoder: encoder)
                )
            ],
            maxTokens: maxTokens,
            stream: false
        )
    }

    private func validateStatusCode(_ statusCode: Int, requestID: String?) throws {
        switch statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw CommandIntelligenceFailure.providerError(requestID: requestID)
        case 429:
            throw CommandIntelligenceFailure.rateLimited(requestID: requestID)
        case 500..<600:
            throw CommandIntelligenceFailure.providerError(requestID: requestID)
        default:
            throw CommandIntelligenceFailure.providerError(requestID: requestID)
        }
    }

    private func mappedFailure(for error: URLError) -> CommandIntelligenceFailure {
        switch error.code {
        case .notConnectedToInternet, .cannotFindHost, .timedOut, .networkConnectionLost:
            .offline(underlyingDescription: error.localizedDescription)
        default:
            .providerError()
        }
    }
}

private struct DeepSeekChatCompletionRequest: Encodable {
    let model: String
    let messages: [DeepSeekChatMessage]
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case stream
    }
}

private struct DeepSeekChatMessage: Encodable {
    let role: String
    let content: String
}

private struct DeepSeekChatCompletionResponse: Decodable {
    let id: String?
    let choices: [DeepSeekChatChoice]?
    let error: DeepSeekChatError?

    var finishReason: String? {
        choices?.first?.finishReason
    }

    enum CodingKeys: String, CodingKey {
        case id
        case choices
        case error
    }

    func responseJSONText() throws -> String {
        let text = choices?
            .compactMap(\.message.content)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !text.isEmpty else {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        }

        return text
    }
}

private struct DeepSeekChatChoice: Decodable {
    let finishReason: String?
    let message: DeepSeekChatResponseMessage

    enum CodingKeys: String, CodingKey {
        case finishReason = "finish_reason"
        case message
    }
}

private struct DeepSeekChatResponseMessage: Decodable {
    let role: String?
    let content: String?
}

private struct DeepSeekChatError: Decodable {
    let message: String?
}

extension HTTPURLResponse {
    var openAICompatibleRequestID: String? {
        value(forHTTPHeaderField: "x-request-id")
            ?? value(forHTTPHeaderField: "request-id")
            ?? value(forHTTPHeaderField: "openai-request-id")
    }
}
