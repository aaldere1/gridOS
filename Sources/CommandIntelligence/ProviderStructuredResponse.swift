import Foundation

enum CommandProviderPrompt {
    static let systemInstruction = """
    You are gridOS Command Intelligence. Return only a JSON object matching this schema:
    {
      "summary": "short user-facing summary",
      "explanation": "plain-language explanation",
      "commands": [
        {
          "command": "optional shell command",
          "explanation": "what the command inspects or changes",
          "workingDirectoryAssumption": "path or Current terminal directory",
          "contextUsed": ["prompt", "workingDirectory", "selectedOutput", "pastedOutput", "screenshotAttachments", "failedCommand", "failedOutput"],
          "providerRiskLabel": "low, medium, high, or unknown"
        }
      ]
    }
    For read-only explanations, commands may be an empty array. Never include markdown, prose outside JSON, API keys, hidden shell history, or unapproved raw context.
    """

    static func userMessageContent(from request: LLMCommandRequest, encoder: JSONEncoder) throws -> String {
        let payloadData = try encoder.encode(request.approvedPreview)
        guard let payload = String(data: payloadData, encoding: .utf8) else {
            throw CommandIntelligenceFailure.invalidProviderResponse()
        }

        return """
        Flow: \(request.flow.rawValue)
        Provider: \(request.providerID.rawValue)
        Model: \(request.modelID.rawValue)

        approvedPreview:
        \(payload)

        Use only the approvedPreview payload above. Do not infer unapproved terminal data, hidden history, environment variables, keys, metrics, or unrequested scrollback.
        """
    }
}

struct ProviderStructuredResponse: Decodable {
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
