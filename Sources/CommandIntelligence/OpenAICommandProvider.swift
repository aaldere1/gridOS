import Foundation

public protocol OpenAIHTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionOpenAIHTTPTransport: OpenAIHTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        }

        return (data, httpResponse)
    }
}

public struct OpenAICommandProvider: LLMCommandProvider {
    public let providerID: LLMProviderID

    public static let defaultBaseURL = URL(string: "https://api.openai.com")!
    public static let defaultModelID = LLMModelID("gpt-5.2")
    private static let responsesPath = "/v1/responses"
    public static let defaultMaxOutputTokens = 1200

    private let baseURL: URL
    private let transport: OpenAIHTTPTransport
    private let maxOutputTokens: Int
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        providerID: LLMProviderID = .openAI,
        baseURL: URL = OpenAICommandProvider.defaultBaseURL,
        transport: OpenAIHTTPTransport = URLSessionOpenAIHTTPTransport(),
        maxOutputTokens: Int = OpenAICommandProvider.defaultMaxOutputTokens
    ) {
        self.providerID = providerID
        self.baseURL = baseURL
        self.transport = transport
        self.maxOutputTokens = maxOutputTokens
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func complete(_ request: LLMCommandRequest, apiKey: String) async throws -> LLMCommandResponse {
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAPIKey.isEmpty else {
            throw CommandIntelligenceFailure.noProviderKey()
        }

        var urlRequest = URLRequest(url: responsesURL())
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(trimmedAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try encoder.encode(responsesRequest(from: request))

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

        let requestID = httpResponse.openAIRequestID
        try validateStatusCode(httpResponse.statusCode, requestID: requestID)

        do {
            let openAIResponse = try decoder.decode(OpenAIResponsesResponse.self, from: responseData)

            if let error = openAIResponse.error {
                throw CommandIntelligenceFailure.providerError(message: error.message, requestID: requestID ?? openAIResponse.id)
            }

            if openAIResponse.status == "incomplete" {
                throw CommandIntelligenceFailure.truncatedResponse(requestID: requestID ?? openAIResponse.id)
            }

            if openAIResponse.containsRefusal {
                throw CommandIntelligenceFailure.providerRefusal(requestID: requestID ?? openAIResponse.id)
            }

            let providerPayload = try openAIResponse.responseJSONText()
            let decodedResponse = try decoder.decode(
                ProviderStructuredResponse.self,
                from: Data(providerPayload.utf8)
            )
            try decodedResponse.validate()

            return LLMCommandResponse(
                summary: decodedResponse.summary,
                commands: decodedResponse.commands,
                explanation: decodedResponse.explanation,
                requestID: decodedResponse.requestID ?? requestID ?? openAIResponse.id
            )
        } catch let failure as CommandIntelligenceFailure {
            throw failure
        } catch {
            throw CommandIntelligenceFailure.invalidProviderResponse(requestID: requestID)
        }
    }

    private func responsesURL() -> URL {
        URL(string: Self.responsesPath, relativeTo: baseURL)!.absoluteURL
    }

    private func responsesRequest(from request: LLMCommandRequest) throws -> OpenAIResponsesRequest {
        OpenAIResponsesRequest(
            model: request.modelID.rawValue,
            instructions: CommandProviderPrompt.systemInstruction,
            input: try CommandProviderPrompt.userMessageContent(from: request, encoder: encoder),
            maxOutputTokens: maxOutputTokens,
            store: false
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

public struct XAICommandProvider: LLMCommandProvider {
    public let providerID: LLMProviderID = .xAI

    public static let defaultBaseURL = URL(string: "https://api.x.ai")!
    public static let defaultModelID = LLMModelID("grok-4.3")

    private let provider: OpenAICommandProvider

    public init(
        baseURL: URL = XAICommandProvider.defaultBaseURL,
        transport: OpenAIHTTPTransport = URLSessionOpenAIHTTPTransport(),
        maxOutputTokens: Int = OpenAICommandProvider.defaultMaxOutputTokens
    ) {
        self.provider = OpenAICommandProvider(
            providerID: .xAI,
            baseURL: baseURL,
            transport: transport,
            maxOutputTokens: maxOutputTokens
        )
    }

    public func complete(_ request: LLMCommandRequest, apiKey: String) async throws -> LLMCommandResponse {
        try await provider.complete(request, apiKey: apiKey)
    }
}

private struct OpenAIResponsesRequest: Encodable {
    let model: String
    let instructions: String
    let input: String
    let maxOutputTokens: Int
    let store: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case instructions
        case input
        case maxOutputTokens = "max_output_tokens"
        case store
    }
}

private struct OpenAIResponsesResponse: Decodable {
    let id: String?
    let status: String?
    let error: OpenAIResponseError?
    let output: [OpenAIResponseOutputItem]

    func responseJSONText() throws -> String {
        let text = output
            .flatMap { $0.content ?? [] }
            .filter { $0.type == "output_text" }
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        }

        return text
    }

    var containsRefusal: Bool {
        output
            .flatMap { $0.content ?? [] }
            .contains { $0.type == "refusal" || !($0.refusal?.isEmpty ?? true) }
    }
}

private struct OpenAIResponseError: Decodable {
    let message: String?
}

private struct OpenAIResponseOutputItem: Decodable {
    let type: String?
    let status: String?
    let content: [OpenAIResponseContent]?
}

private struct OpenAIResponseContent: Decodable {
    let type: String
    let text: String?
    let refusal: String?
}

private extension HTTPURLResponse {
    var openAIRequestID: String? {
        value(forHTTPHeaderField: "x-request-id")
            ?? value(forHTTPHeaderField: "openai-request-id")
    }
}
