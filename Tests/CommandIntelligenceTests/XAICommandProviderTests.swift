import Foundation
import XCTest
@testable import CommandIntelligence

final class XAICommandProviderTests: XCTestCase {
    func testXAIRequestUsesResponsesAPIWithXAIBaseURLAndProviderID() async throws {
        let transport = MockXAIHTTPTransport(
            result: .success(Self.validXAIResponse())
        )
        let provider = XAICommandProvider(transport: transport)

        _ = try await provider.complete(Self.request(), apiKey: "xai-secret-test")

        let requests = await transport.recordedRequests()
        let sentRequest = try XCTUnwrap(requests.first)
        XCTAssertEqual(sentRequest.httpMethod, "POST")
        XCTAssertEqual(sentRequest.url?.absoluteString, "https://api.x.ai/v1/responses")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "Authorization"), "Bearer xai-secret-test")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "content-type"), "application/json")

        let body = try XCTUnwrap(sentRequest.httpBody)
        let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(payload?["model"] as? String, "grok-4.3")
        XCTAssertEqual(payload?["max_output_tokens"] as? Int, 1200)
        XCTAssertEqual(payload?["store"] as? Bool, false)

        let input = try XCTUnwrap(payload?["input"] as? String)
        XCTAssertTrue(input.contains("Provider: xai"))
        XCTAssertTrue(input.contains("Explain this error"))
    }

    func testSuccessfulResponseDecodesStructuredJSON() async throws {
        let transport = MockXAIHTTPTransport(
            result: .success(Self.validXAIResponse(requestID: "req-xai-header"))
        )
        let provider = XAICommandProvider(transport: transport)

        let response = try await provider.complete(Self.request(), apiKey: "xai-secret-test")

        XCTAssertEqual(response.summary, "Explain the permission issue.")
        XCTAssertEqual(response.requestID, "req-xai-header")
        XCTAssertTrue(response.commands.isEmpty)
    }

    private static func request() -> LLMCommandRequest {
        LLMCommandRequest(
            providerID: .xAI,
            modelID: .grok43,
            flow: .explainOutput,
            approvedPreview: ApprovedCommandContextPayload(
                redactedBlocks: [
                    ApprovedCommandContextBlock(
                        source: .prompt,
                        label: "User Prompt",
                        redactedText: "Explain this error",
                        characterCount: 18
                    )
                ],
                includedContextSourceLabels: ["User Prompt"],
                redactionSummaries: [],
                blockedReasons: []
            )
        )
    }

    private static func validXAIResponse(requestID: String = "req-xai-test") -> MockXAIHTTPResponse {
        response(
            body: """
            {
              "id": "resp_xai_123",
              "status": "completed",
              "error": null,
              "output": [
                {
                  "type": "message",
                  "status": "completed",
                  "content": [
                    {
                      "type": "output_text",
                      "text": "{\\"summary\\":\\"Explain the permission issue.\\",\\"explanation\\":\\"The output indicates a permissions problem.\\",\\"commands\\":[]}"
                    }
                  ]
                }
              ]
            }
            """,
            requestID: requestID
        )
    }

    private static func response(
        body: String,
        statusCode: Int = 200,
        requestID: String? = nil
    ) -> MockXAIHTTPResponse {
        let url = URL(string: "https://api.x.ai/v1/responses")!
        var headers: [String: String] = [:]
        if let requestID {
            headers["x-request-id"] = requestID
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )!
        return MockXAIHTTPResponse(data: Data(body.utf8), response: response)
    }
}

private actor MockXAIHTTPTransport: OpenAIHTTPTransport {
    private let result: Result<MockXAIHTTPResponse, Error>
    private(set) var requests: [URLRequest] = []

    init(result: Result<MockXAIHTTPResponse, Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let response = try result.get()
        return (response.data, response.response)
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

private struct MockXAIHTTPResponse: Sendable {
    let data: Data
    let response: HTTPURLResponse
}
