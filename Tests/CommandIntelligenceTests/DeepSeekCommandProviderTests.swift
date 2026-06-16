import Foundation
import XCTest
@testable import CommandIntelligence

final class DeepSeekCommandProviderTests: XCTestCase {
    func testDeepSeekRequestUsesChatCompletionsHeadersAndPrivacyDefaults() async throws {
        let transport = MockOpenAICompatibleHTTPTransport(
            result: .success(Self.validDeepSeekResponse())
        )
        let provider = DeepSeekCommandProvider(transport: transport)

        _ = try await provider.complete(Self.request(), apiKey: "sk-deepseek-secret-test")

        let requests = await transport.recordedRequests()
        let sentRequest = try XCTUnwrap(requests.first)
        XCTAssertEqual(sentRequest.httpMethod, "POST")
        XCTAssertEqual(sentRequest.url?.absoluteString, "https://api.deepseek.com/chat/completions")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "Authorization"), "Bearer sk-deepseek-secret-test")
        XCTAssertEqual(sentRequest.value(forHTTPHeaderField: "content-type"), "application/json")

        let body = try XCTUnwrap(sentRequest.httpBody)
        let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(payload?["model"] as? String, "deepseek-v4-flash")
        XCTAssertEqual(payload?["max_tokens"] as? Int, 1200)
        XCTAssertEqual(payload?["stream"] as? Bool, false)

        let messages = try XCTUnwrap(payload?["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages.first?["role"] as? String, "system")
        XCTAssertTrue((messages.first?["content"] as? String)?.contains("Return only a JSON object") ?? false)
        XCTAssertEqual(messages.last?["role"] as? String, "user")
        XCTAssertTrue((messages.last?["content"] as? String)?.contains("Provider: deepseek") ?? false)
        XCTAssertTrue((messages.last?["content"] as? String)?.contains("List Swift files") ?? false)
        XCTAssertFalse((messages.last?["content"] as? String)?.contains("raw shell context") ?? true)
    }

    func testSuccessfulResponseDecodesStructuredJSON() async throws {
        let transport = MockOpenAICompatibleHTTPTransport(
            result: .success(Self.validDeepSeekResponse(requestID: "req-deepseek-header"))
        )
        let provider = DeepSeekCommandProvider(transport: transport)

        let response = try await provider.complete(Self.request(), apiKey: "sk-deepseek-secret-test")

        XCTAssertEqual(response.summary, "Use find for a local source search.")
        XCTAssertEqual(response.explanation, "The command lists Swift source files without changing files.")
        XCTAssertEqual(response.requestID, "req-deepseek-header")
        XCTAssertEqual(response.commands.first?.command, "find . -name '*.swift'")
    }

    func testRateLimitMapsToHumanReadableFailure() async {
        await assertFailure(
            response: Self.response(body: #"{"error":{"message":"rate limited"}}"#, statusCode: 429),
            expectedTitle: "Provider is busy",
            apiKey: "sk-deepseek-rate-limit-secret"
        )
    }

    func testLengthFinishMapsToTruncatedResponse() async {
        await assertFailure(
            response: Self.response(
                body: #"{"id":"deepseek_truncated","choices":[{"finish_reason":"length","message":{"role":"assistant","content":"{}"}}]}"#
            ),
            expectedTitle: "AI Command Helper is unavailable",
            apiKey: "sk-deepseek-truncated-secret"
        )
    }

    func testNetworkErrorMapsToOffline() async {
        let transport = MockOpenAICompatibleHTTPTransport(
            result: .failure(URLError(.notConnectedToInternet))
        )
        let provider = DeepSeekCommandProvider(transport: transport)

        do {
            _ = try await provider.complete(Self.request(), apiKey: "sk-deepseek-offline-secret")
            XCTFail("Expected offline failure")
        } catch let failure as CommandIntelligenceFailure {
            XCTAssertEqual(failure.title, "Provider unreachable")
            Self.assertFailure(failure, doesNotLeak: "sk-deepseek-offline-secret")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func assertFailure(
        response: MockOpenAICompatibleHTTPResponse,
        expectedTitle: String,
        apiKey: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let transport = MockOpenAICompatibleHTTPTransport(result: .success(response))
        let provider = DeepSeekCommandProvider(transport: transport)

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
            providerID: .deepSeek,
            modelID: .deepSeekV4Flash,
            flow: .suggestCommand,
            approvedPreview: ApprovedCommandContextPayload(
                redactedBlocks: [
                    ApprovedCommandContextBlock(
                        source: .prompt,
                        label: "User Prompt",
                        redactedText: "List Swift files",
                        characterCount: 16
                    )
                ],
                includedContextSourceLabels: ["User Prompt"],
                redactionSummaries: [],
                blockedReasons: []
            )
        )
    }

    private static func validDeepSeekResponse(requestID: String = "req-deepseek-test") -> MockOpenAICompatibleHTTPResponse {
        response(
            body: """
            {
              "id": "deepseek_123",
              "choices": [
                {
                  "finish_reason": "stop",
                  "message": {
                    "role": "assistant",
                    "content": "{\\"summary\\":\\"Use find for a local source search.\\",\\"explanation\\":\\"The command lists Swift source files without changing files.\\",\\"commands\\":[{\\"command\\":\\"find . -name '*.swift'\\",\\"explanation\\":\\"Finds Swift files under the current directory.\\",\\"workingDirectoryAssumption\\":\\"/Users/example/project\\",\\"contextUsed\\":[\\"prompt\\"],\\"providerRiskLabel\\":\\"low\\"}]}"
                  }
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
    ) -> MockOpenAICompatibleHTTPResponse {
        let url = URL(string: "https://api.deepseek.com/chat/completions")!
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
        return MockOpenAICompatibleHTTPResponse(data: Data(body.utf8), response: response)
    }
}

private actor MockOpenAICompatibleHTTPTransport: OpenAIHTTPTransport {
    private let result: Result<MockOpenAICompatibleHTTPResponse, Error>
    private(set) var requests: [URLRequest] = []

    init(result: Result<MockOpenAICompatibleHTTPResponse, Error>) {
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

private struct MockOpenAICompatibleHTTPResponse: Sendable {
    let data: Data
    let response: HTTPURLResponse
}
