import Foundation

#if DEBUG
public struct DebugCommandIntelligenceFixtureProvider: LLMCommandProvider {
    public let providerID: LLMProviderID = .debugSmokeFixture

    public init() {}

    public func complete(_ request: LLMCommandRequest, apiKey: String) async throws -> LLMCommandResponse {
        let promptText = request.approvedPreview.redactedBlocks
            .map(\.redactedText)
            .joined(separator: "\n")

        if promptText.localizedCaseInsensitiveContains("PHASE6_HIGH_RISK")
            || promptText.localizedCaseInsensitiveContains("high-risk")
            || promptText.localizedCaseInsensitiveContains("destructive") {
            return Self.highRiskResponse
        }

        return Self.insertResponse
    }

    private static let insertCommand = #"printf 'PHASE6_INSERT\n' > /tmp/gridos_phase6_insert.txt"#
    private static let highRiskCommand = "rm -rf ~/tmp/gridos-test"

    private static let insertResponse = LLMCommandResponse(
        summary: "Deterministic Phase 6 insert smoke command.",
        commands: [
            GeneratedCommand(
                command: insertCommand,
                explanation: "Writes PHASE6_INSERT to a temporary file only after the user explicitly runs it.",
                workingDirectoryAssumption: "Current terminal directory",
                contextUsed: [.prompt],
                providerRiskLabel: "low"
            )
        ],
            explanation: "Use this fixture to verify insert-before-run behavior without a live hosted-provider key.",
        requestID: "debug-smoke-fixture-insert"
    )

    private static let highRiskResponse = LLMCommandResponse(
        summary: "Deterministic Phase 6 high-risk smoke command.",
        commands: [
            GeneratedCommand(
                command: highRiskCommand,
                explanation: "Attempts to recursively delete a test directory and must never run automatically.",
                workingDirectoryAssumption: "Current terminal directory",
                contextUsed: [.prompt],
                providerRiskLabel: "high"
            )
        ],
        explanation: "Use this fixture to verify high-risk insert-only or exact-command confirmation behavior.",
        requestID: "debug-smoke-fixture-high-risk"
    )
}
#endif
