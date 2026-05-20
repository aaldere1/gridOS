import Foundation

public protocol AnthropicHTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionAnthropicHTTPTransport: AnthropicHTTPTransport {
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

public struct AnthropicCommandProvider: LLMCommandProvider {
    public let providerID: LLMProviderID = .anthropic

    public static let defaultBaseURL = URL(string: "https://api.anthropic.com")!
    public static let defaultModelID = LLMModelID("claude-sonnet-4-6")
    private static let messagesPath = "/v1/messages"
    private static let anthropicVersion = "2023-06-01"
    public static let defaultMaxTokens = 1200

    private let baseURL: URL
    private let transport: AnthropicHTTPTransport
    private let maxTokens: Int
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = AnthropicCommandProvider.defaultBaseURL,
        transport: AnthropicHTTPTransport = URLSessionAnthropicHTTPTransport(),
        maxTokens: Int = AnthropicCommandProvider.defaultMaxTokens
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

        var urlRequest = URLRequest(url: messagesURL())
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(trimmedAPIKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Self.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try encoder.encode(messagesRequest(from: request))

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

        let requestID = httpResponse.anthropicRequestID
        try validateStatusCode(httpResponse.statusCode, requestID: requestID)

        do {
            let anthropicResponse = try decoder.decode(AnthropicMessagesResponse.self, from: responseData)

            if anthropicResponse.stopReason == "refusal" {
                throw CommandIntelligenceFailure.providerRefusal(requestID: requestID)
            }

            if anthropicResponse.stopReason == "max_tokens" {
                throw CommandIntelligenceFailure.truncatedResponse(requestID: requestID)
            }

            let providerPayload = try anthropicResponse.responseJSONText()
            let decodedResponse = try decoder.decode(
                ProviderStructuredResponse.self,
                from: Data(providerPayload.utf8)
            )
            try decodedResponse.validate()

            return LLMCommandResponse(
                summary: decodedResponse.summary,
                commands: decodedResponse.commands,
                explanation: decodedResponse.explanation,
                requestID: decodedResponse.requestID ?? requestID
            )
        } catch let failure as CommandIntelligenceFailure {
            throw failure
        } catch {
            throw CommandIntelligenceFailure.invalidProviderResponse(requestID: requestID)
        }
    }

    private func messagesURL() -> URL {
        URL(string: Self.messagesPath, relativeTo: baseURL)!.absoluteURL
    }

    private func messagesRequest(from request: LLMCommandRequest) throws -> AnthropicMessagesRequest {
        AnthropicMessagesRequest(
            model: request.modelID.rawValue,
            maxTokens: maxTokens,
            system: Self.systemInstruction,
            messages: [
                AnthropicMessage(
                    role: "user",
                    content: try userMessageContent(from: request)
                )
            ]
        )
    }

    private func userMessageContent(from request: LLMCommandRequest) throws -> String {
        let payloadData = try encoder.encode(request.approvedPreview)
        guard let payload = String(data: payloadData, encoding: .utf8) else {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        }

        return """
        Flow: \(request.flow.rawValue)
        Model: \(request.modelID.rawValue)

        approvedPreview:
        \(payload)

        Use only the approvedPreview payload above. Do not infer unapproved terminal data, hidden history, environment variables, keys, metrics, or unrequested scrollback.
        """
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

    private static let systemInstruction = """
    You are gridOS Command Intelligence. Return only a JSON object matching this schema:
    {
      "summary": "short user-facing summary",
      "explanation": "plain-language explanation",
      "commands": [
        {
          "command": "optional shell command",
          "explanation": "what the command inspects or changes",
          "workingDirectoryAssumption": "path or Current terminal directory",
          "contextUsed": ["prompt", "workingDirectory", "selectedOutput", "pastedOutput", "failedCommand", "failedOutput"],
          "providerRiskLabel": "low, medium, high, or unknown"
        }
      ]
    }
    For read-only explanations, commands may be an empty array. Never include markdown, prose outside JSON, API keys, hidden shell history, or unapproved raw context.
    """
}

private struct AnthropicMessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [AnthropicMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

private struct AnthropicMessage: Encodable {
    let role: String
    let content: String
}

private struct AnthropicMessagesResponse: Decodable {
    let stopReason: String?
    let content: [AnthropicContentBlock]

    enum CodingKeys: String, CodingKey {
        case stopReason = "stop_reason"
        case content
    }

    func responseJSONText() throws -> String {
        let text = content
            .filter { $0.type == "text" }
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        }

        return text
    }
}

private struct AnthropicContentBlock: Decodable {
    let type: String
    let text: String?
}

private struct ProviderStructuredResponse: Decodable {
    let summary: String
    let commands: [GeneratedCommand]
    let explanation: String
    let requestID: String?

    enum CodingKeys: String, CodingKey {
        case summary
        case commands
        case explanation
        case requestID
    }

    func validate() throws {
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        }

        for command in commands {
            guard !command.command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !command.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !command.workingDirectoryAssumption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !command.providerRiskLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                throw CommandIntelligenceFailure.invalidProviderResponse()
            }
        }
    }
}

private extension HTTPURLResponse {
    var anthropicRequestID: String? {
        value(forHTTPHeaderField: "request-id")
            ?? value(forHTTPHeaderField: "anthropic-request-id")
    }
}
