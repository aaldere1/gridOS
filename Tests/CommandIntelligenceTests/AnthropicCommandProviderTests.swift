import Foundation
import XCTest
@testable import CommandIntelligence

final class AnthropicCommandProviderTests: XCTestCase {
    func testAnthropicRequestUsesRequiredHeaders() async throws {
        let transport = MockAnthropicHTTPTransport(
            result: .success(Self.validAnthropicResponse())
        )
        let provider = AnthropicCommandProvider(transport: transport)
        let request = Self.request()

        _ = try await provider.complete(request, apiKey: "sk-ant-secret-test")

        let sentRequest = try XCTUnwrap(await transport.requests.first)
        XCTAssertEqual(sentRequest.httpMethod, "POST")
        XCTAssertEqual(sentRequest.url?.absoluteString, "https://api.anthropic.com/v1/messages")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "x-api-key"), "sk-ant-secret-test")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "content-type"), "application/json")

        let body = try XCTUnwrap(sentRequest.httpBody)
        let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(payload?["model"] as? String, "claude-sonnet-4-6")
        XCTAssertEqual(payload?["max_tokens"] as? Int, 1200)

        let messages = try XCTUnwrap(payload?["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.first?["role"] as? String, "user")
        let content = try XCTUnwrap(messages.first?["content"] as? String)
        XCTAssertTrue(content.contains("approvedPreview"))
        XCTAssertTrue(content.contains("List Swift files"))
        XCTAssertFalse(content.contains("raw shell context"))
    }

    func testSuccessfulResponseDecodesStructuredJSON() async throws {
        let transport = MockAnthropicHTTPTransport(
            result: .success(Self.validAnthropicResponse(requestID: "req-header-123"))
        )
        let provider = AnthropicCommandProvider(transport: transport)

        let response = try await provider.complete(Self.request(), apiKey: "sk-ant-secret-test")

        XCTAssertEqual(response.summary, "Use find for a local source search.")
        XCTAssertEqual(response.explanation, "The command lists Swift source files without changing files.")
        XCTAssertEqual(response.requestID, "req-header-123")
        XCTAssertEqual(response.commands.count, 1)
        XCTAssertEqual(response.commands.first?.command, "find . -name '*.swift'")
        XCTAssertEqual(response.commands.first?.contextUsed, [.prompt, .workingDirectory])
    }

    func testUnauthorizedMapsToProviderErrorWithoutLeakingAPIKey() async {
        await assertFailure(
            response: Self.emptyAnthropicResponse(statusCode: 401),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-ant-should-not-leak"
        )
    }

    func testRateLimitMapsToHumanReadableFailure() async {
        await assertFailure(
            response: Self.emptyAnthropicResponse(statusCode: 429),
            expectedTitle: "Provider is busy",
            apiKey: "sk-ant-rate-limit-secret"
        )
    }

    func testServerErrorMapsToProviderError() async {
        await assertFailure(
            response: Self.emptyAnthropicResponse(statusCode: 503),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-ant-server-secret"
        )
    }

    func testInvalidJSONMapsToInvalidProviderResponse() async {
        await assertFailure(
            response: Self.response(body: #"{"content":[{"type":"text","text":"not json"}]}"#),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-ant-json-secret"
        )
    }

    func testNetworkErrorMapsToOffline() async {
        let transport = MockAnthropicHTTPTransport(
            result: .failure(URLError(.notConnectedToInternet))
        )
        let provider = AnthropicCommandProvider(transport: transport)

        do {
            _ = try await provider.complete(Self.request(), apiKey: "sk-ant-offline-secret")
            XCTFail("Expected offline failure")
        } catch let failure as CommandIntelligenceFailure {
            XCTAssertEqual(failure.title, "Provider unreachable")
            XCTAssertFalse(String(describing: failure).contains("sk-ant-offline-secret"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRefusalMapsToProviderRefusal() async {
        await assertFailure(
            response: Self.response(body: #"{"stop_reason":"refusal","content":[{"type":"text","text":"{}"}]}"#),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-ant-refusal-secret"
        )
    }

    func testMaxTokenStopReasonMapsToTruncatedResponse() async {
        await assertFailure(
            response: Self.response(body: #"{"stop_reason":"max_tokens","content":[{"type":"text","text":"{\"summary\":\"partial\"}"}]}"#),
            expectedTitle: "Command intelligence is unavailable",
            apiKey: "sk-ant-truncated-secret"
        )
    }

    private func assertFailure(
        response: MockAnthropicHTTPResponse,
        expectedTitle: String,
        apiKey: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let transport = MockAnthropicHTTPTransport(result: .success(response))
        let provider = AnthropicCommandProvider(transport: transport)

        do {
            _ = try await provider.complete(Self.request(), apiKey: apiKey)
            XCTFail("Expected provider failure", file: file, line: line)
        } catch let failure as CommandIntelligenceFailure {
            XCTAssertEqual(failure.title, expectedTitle, file: file, line: line)
            XCTAssertFalse(String(describing: failure).contains(apiKey), file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }

    private static func request() -> LLMCommandRequest {
        LLMCommandRequest(
            providerID: .anthropic,
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

    private static func validAnthropicResponse(requestID: String = "req-test-123") -> MockAnthropicHTTPResponse {
        response(
            body: """
            {
              "id": "msg_123",
              "type": "message",
              "role": "assistant",
              "stop_reason": "end_turn",
              "content": [
                {
                  "type": "text",
                  "text": "{\\"summary\\":\\"Use find for a local source search.\\",\\"explanation\\":\\"The command lists Swift source files without changing files.\\",\\"commands\\":[{\\"command\\":\\"find . -name '*.swift'\\",\\"explanation\\":\\"Finds Swift files under the current directory.\\",\\"workingDirectoryAssumption\\":\\"/Users/example/project\\",\\"contextUsed\\":[\\"prompt\\",\\"workingDirectory\\"],\\"providerRiskLabel\\":\\"low\\"}]}"
                }
              ]
            }
            """,
            requestID: requestID
        )
    }

    private static func emptyAnthropicResponse(statusCode: Int) -> MockAnthropicHTTPResponse {
        response(body: #"{"error":{"message":"provider error"}}"#, statusCode: statusCode)
    }

    private static func response(
        body: String,
        statusCode: Int = 200,
        requestID: String? = nil
    ) -> MockAnthropicHTTPResponse {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var headers: [String: String] = [:]
        if let requestID {
            headers["request-id"] = requestID
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )!
        return MockAnthropicHTTPResponse(data: Data(body.utf8), response: response)
    }
}

private actor MockAnthropicHTTPTransport: AnthropicHTTPTransport {
    private let result: Result<MockAnthropicHTTPResponse, Error>
    private(set) var requests: [URLRequest] = []

    init(result: Result<MockAnthropicHTTPResponse, Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let response = try result.get()
        return (response.data, response.response)
    }
}

private struct MockAnthropicHTTPResponse: Sendable {
    let data: Data
    let response: HTTPURLResponse
}
