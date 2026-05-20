import XCTest
@testable import CommandIntelligence

final class CommandIntelligenceFailureTests: XCTestCase {
    func testRequiredFailureCopyIsHumanReadable() {
        XCTAssertEqual(CommandIntelligenceFailure.noProviderKey().title, "Provider not configured")
        XCTAssertEqual(
            CommandIntelligenceFailure.noProviderKey().message,
            "Add a provider key in Settings to use command intelligence. The terminal still works normally."
        )
        XCTAssertEqual(
            CommandIntelligenceFailure.noProviderKey().recoveryAction,
            "Open Command Intelligence Settings"
        )

        XCTAssertEqual(CommandIntelligenceFailure.offline().title, "Provider unreachable")
        XCTAssertEqual(
            CommandIntelligenceFailure.offline().message,
            "Check your connection or try again later. Nothing was sent after the failure."
        )
        XCTAssertEqual(CommandIntelligenceFailure.offline().recoveryAction, "Retry Request")

        XCTAssertEqual(CommandIntelligenceFailure.rateLimited().title, "Provider is busy")
        XCTAssertEqual(
            CommandIntelligenceFailure.rateLimited().message,
            "Wait a moment and try again. The terminal is still available."
        )
        XCTAssertEqual(CommandIntelligenceFailure.rateLimited().recoveryAction, "Retry Request")

        XCTAssertEqual(CommandIntelligenceFailure.providerError(message: "HTTP 500").title, "Command intelligence is unavailable")
        XCTAssertEqual(
            CommandIntelligenceFailure.providerError(message: "HTTP 500").message,
            "Try again or continue in the terminal without assistance."
        )
        XCTAssertEqual(CommandIntelligenceFailure.providerError(message: "HTTP 500").recoveryAction, "Retry Request")

        XCTAssertEqual(CommandIntelligenceFailure.redactionBlocked(reasons: ["Private key block"]).title, "Context needs review")
        XCTAssertEqual(
            CommandIntelligenceFailure.redactionBlocked(reasons: ["Private key block"]).message,
            "Sensitive content was detected that cannot be safely sent. Remove it or continue manually."
        )

        XCTAssertEqual(CommandIntelligenceFailure.unsupportedSelection().title, "Selection unavailable")
        XCTAssertEqual(
            CommandIntelligenceFailure.unsupportedSelection().message,
            "Paste the output into the field to continue."
        )
    }

    func testFailureCopyCarriesOptionalRequestID() {
        let failure = CommandIntelligenceFailure.invalidProviderResponse(requestID: "req-json")

        XCTAssertEqual(failure.requestID, "req-json")
        XCTAssertEqual(failure.title, "Command intelligence is unavailable")
    }

    func testFailureCopyDoesNotExposeTechnicalJargon() {
        let failures: [CommandIntelligenceFailure] = [
            .offline(underlyingDescription: "URLError.notConnectedToInternet"),
            .rateLimited(providerMessage: "HTTP status 429"),
            .providerError(message: "NSURLErrorDomain -1001"),
            .providerRefusal(message: "providerRefusal enum case"),
            .invalidProviderResponse(underlyingDescription: "JSON decoding failed"),
            .truncatedResponse(providerMessage: "max_tokens stop_reason")
        ]

        let displayedCopy = failures
            .flatMap { [$0.title, $0.message, $0.recoveryAction, $0.requestID] }
            .compactMap { $0 }
            .joined(separator: " ")

        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("URLError"))
        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("HTTP"))
        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("429"))
        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("JSON"))
        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("decoding"))
        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("NSURLErrorDomain"))
        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("providerRefusal"))
        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("truncatedResponse"))
        XCTAssertFalse(displayedCopy.localizedCaseInsensitiveContains("invalidProviderResponse"))
    }
}
