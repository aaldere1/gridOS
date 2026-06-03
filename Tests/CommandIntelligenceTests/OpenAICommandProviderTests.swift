import Foundation
import XCTest
@testable import CommandIntelligence

final class OpenAICommandProviderTests: XCTestCase {
    func testOpenAIRequestUsesResponsesAPIHeadersAndPrivacyDefaults() async throws {
        let transport = MockOpenAIHTTPTransport(
            result: .success(Self.validOpenAIResponse())
        )
        let provider = OpenAICommandProvider(transport: transport)

        _ = try await provider.complete(Self.request(), apiKey: "sk-openai-secret-test")

        let requests = await transport.recordedRequests()
        let sentRequest = try XCTUnwrap(requests.first)
        XCTAssertEqual(sentRequest.httpMethod, "POST")
        XCTAssertEqual(sentRequest.url?.absoluteString, "https://api.openai.com/v1/responses")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "Authorization"), "Bearer sk-openai-secret-test")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "content-type"), "application/json")

        let body = try XCTUnwrap(sentRequest.httpBody)
        let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(payload?["model"] as? String, "gpt-5.5")
        XCTAssertEqual(payload?["max_output_tokens"] as? Int, 1200)
        XCTAssertEqual(payload?["store"] as? Bool, false)
        XCTAssertTrue((payload?["instructions"] as? String)?.contains("Return only a JSON object") ?? false)

        let input = try XCTUnwrap(payload?["input"] as? String)
        XCTAssertTrue(input.contains("approvedPreview"))
        XCTAssertTrue(input.contains("Provider: openai"))
        XCTAssertTrue(input.contains("List Swift files"))
        XCTAssertFalse(input.contains("raw shell context"))
    }

    func testSuccessfulResponseDecodesStructuredJSON() async throws {
        let transport = MockOpenAIHTTPTransport(
            result: .success(Self.validOpenAIResponse(requestID: "req-openai-header"))
        )
        let provider = OpenAICommandProvider(transport: transport)

        let response = try await provider.complete(Self.request(), apiKey: "sk-openai-secret-test")

        XCTAssertEqual(response.summary, "Use find for a local source search.")
        XCTAssertEqual(response.explanation, "The command lists Swift source files without changing files.")
        XCTAssertEqual(response.requestID, "req-openai-header")
        XCTAssertEqual(response.commands.count, 1)
        XCTAssertEqual(response.commands.first?.command, "find . -name '*.swift'")
        XCTAssertEqual(response.commands.first?.contextUsed, [.prompt, .workingDirectory])
    }

    func testUnauthorizedMapsToProviderErrorWithoutLeakingAPIKey() async {
        await assertFailure(
            response: Self.emptyOpenAIResponse(statusCode: 401),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-openai-should-not-leak"
        )
    }

    func testRateLimitMapsToHumanReadableFailure() async {
        await assertFailure(
            response: Self.emptyOpenAIResponse(statusCode: 429),
            expectedTitle: "Provider is busy",
            apiKey: "sk-openai-rate-limit-secret"
        )
    }

    func testIncompleteResponseMapsToTruncatedResponse() async {
        await assertFailure(
            response: Self.response(body: #"{"id":"resp_incomplete","status":"incomplete","output":[]}"#),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-openai-truncated-secret"
        )
    }

    func testRefusalMapsToProviderRefusal() async {
        await assertFailure(
            response: Self.response(
                body: #"{"id":"resp_refusal","status":"completed","output":[{"type":"message","content":[{"type":"refusal","refusal":"I cannot help with that."}]}]}"#
            ),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-openai-refusal-secret"
        )
    }

    func testInvalidJSONMapsToInvalidProviderResponse() async {
        await assertFailure(
            response: Self.response(
                body: #"{"id":"resp_bad_json","status":"completed","output":[{"type":"message","content":[{"type":"output_text","text":"not json"}]}]}"#
            ),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-openai-json-secret"
        )
    }

    func testNetworkErrorMapsToOffline() async {
        let transport = MockOpenAIHTTPTransport(
            result: .failure(URLError(.notConnectedToInternet))
        )
        let provider = OpenAICommandProvider(transport: transport)

        do {
            _ = try await provider.complete(Self.request(), apiKey: "sk-openai-offline-secret")
            XCTFail("Expected offline failure")
        } catch let failure as CommandIntelligenceFailure {
            XCTAssertEqual(failure.title, "Provider unreachable")
            Self.assertFailure(failure, doesNotLeak: "sk-openai-offline-secret")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func assertFailure(
        response: MockOpenAIHTTPResponse,
        expectedTitle: String,
        apiKey: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let transport = MockOpenAIHTTPTransport(result: .success(response))
        let provider = OpenAICommandProvider(transport: transport)

        do {
            _ = try await provider.complete(Self.request(), apiKey: apiKey)
            XCTFail("Expected provider failure", file: file, line: line)
        } catch let failure as CommandIntelligenceFailure {
            XCTAssertEqual(failure.title, expectedTitle, file: file, line: line)
            Self.assertFailure(failure, doesNotLeak: apiKey, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }

    private static func assertFailure(
        _ failure: CommandIntelligenceFailure,
        doesNotLeak secret: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(failure.title.contains(secret), file: file, line: line)
        XCTAssertFalse(failure.message.contains(secret), file: file, line: line)
        XCTAssertFalse(failure.recoveryAction?.contains(secret) ?? false, file: file, line: line)
        XCTAssertFalse(failure.requestID?.contains(secret) ?? false, file: file, line: line)
        XCTAssertFalse(String(describing: failure).contains(secret), file: file, line: line)
    }

    private static func request() -> LLMCommandRequest {
        LLMCommandRequest(
            providerID: .openAI,
            modelID: .gpt55,
            flow: .suggestCommand,
            approvedPreview: ApprovedCommandContextPayload(
                redactedBlocks: [
                    ApprovedCommandContextBlock(
                        source: .prompt,
                        label: "User Prompt",
                        redactedText: "List Swift files",
                        characterCount: 16
                    ),
                    ApprovedCommandContextBlock(
                        source: .workingDirectory,
                        label: "Working Directory",
                        redactedText: "/Users/example/project",
                        characterCount: 22
                    )
                ],
                includedContextSourceLabels: ["User Prompt", "Working Directory"],
                redactionSummaries: [],
                blockedReasons: []
            )
        )
    }

    private static func validOpenAIResponse(requestID: String = "req-openai-test") -> MockOpenAIHTTPResponse {
        response(
            body: """
            {
              "id": "resp_123",
              "status": "completed",
              "error": null,
              "output": [
                {
                  "type": "message",
                  "status": "completed",
                  "content": [
                    {
                      "type": "output_text",
                      "text": "{\\"summary\\":\\"Use find for a local source search.\\",\\"explanation\\":\\"The command lists Swift source files without changing files.\\",\\"commands\\":[{\\"command\\":\\"find . -name '*.swift'\\",\\"explanation\\":\\"Finds Swift files under the current directory.\\",\\"workingDirectoryAssumption\\":\\"/Users/example/project\\",\\"contextUsed\\":[\\"prompt\\",\\"workingDirectory\\"],\\"providerRiskLabel\\":\\"low\\"}]}"
                    }
                  ]
                }
              ]
            }
            """,
            requestID: requestID
        )
    }

    private static func emptyOpenAIResponse(statusCode: Int) -> MockOpenAIHTTPResponse {
        response(body: #"{"error":{"message":"provider error"},"output":[]}"#, statusCode: statusCode)
    }

    private static func response(
        body: String,
        statusCode: Int = 200,
        requestID: String? = nil
    ) -> MockOpenAIHTTPResponse {
        let url = URL(string: "https://api.openai.com/v1/responses")!
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
        return MockOpenAIHTTPResponse(data: Data(body.utf8), response: response)
    }
}

private actor MockOpenAIHTTPTransport: OpenAIHTTPTransport {
    private let result: Result<MockOpenAIHTTPResponse, Error>
    private(set) var requests: [URLRequest] = []

    init(result: Result<MockOpenAIHTTPResponse, Error>) {
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

private struct MockOpenAIHTTPResponse: Sendable {
    let data: Data
    let response: HTTPURLResponse
}
