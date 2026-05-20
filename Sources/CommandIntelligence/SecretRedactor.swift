import Foundation

public enum RedactionKind: String, CaseIterable, Codable, Sendable {
    case apiKey
    case bearerToken
    case basicToken
    case privateKey
    case passwordAssignment
    case envValue
    case credentialURL

    public var label: String {
        switch self {
        case .apiKey:
            "API key"
        case .bearerToken:
            "Bearer token"
        case .basicToken:
            "Basic token"
        case .privateKey:
            "Private key"
        case .passwordAssignment:
            "Password assignment"
        case .envValue:
            ".env value"
        case .credentialURL:
            "Credential URL"
        }
    }

    public var replacement: String {
        switch self {
        case .apiKey:
            "[REDACTED API KEY]"
        case .bearerToken:
            "[REDACTED BEARER TOKEN]"
        case .basicToken:
            "[REDACTED BASIC TOKEN]"
        case .privateKey:
            "[REDACTED PRIVATE KEY]"
        case .passwordAssignment:
            "[REDACTED PASSWORD]"
        case .envValue:
            "[REDACTED ENV VALUE]"
        case .credentialURL:
            "[REDACTED CREDENTIAL URL]"
        }
    }
}

public struct RedactionFinding: Codable, Equatable, Sendable {
    public let kind: RedactionKind
    public let label: String
    public let replacement: String

    public init(kind: RedactionKind, label: String = "", replacement: String = "") {
        self.kind = kind
        self.label = label.isEmpty ? kind.label : label
        self.replacement = replacement.isEmpty ? kind.replacement : replacement
    }
}

public struct RedactionResult: Codable, Equatable, Sendable {
    public let redactedText: String
    public let findings: [RedactionFinding]
    public let blockedReasons: [String]

    public init(redactedText: String, findings: [RedactionFinding], blockedReasons: [String]) {
        self.redactedText = redactedText
        self.findings = findings
        self.blockedReasons = blockedReasons
    }
}

public struct SecretRedactor: Sendable {
    private struct Rule {
        let kind: RedactionKind
        let pattern: String
        let options: NSRegularExpression.Options
        let preservesFirstCapture: Bool
        let blockedReason: String?
    }

    private let rules: [Rule]

    public init() {
        self.rules = [
            Rule(
                kind: .privateKey,
                pattern: #"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z0-9 ]*PRIVATE KEY-----"#,
                options: [.caseInsensitive],
                preservesFirstCapture: false,
                blockedReason: "Private key block requires manual review before sending."
            ),
            Rule(
                kind: .credentialURL,
                pattern: #"\b[a-z][a-z0-9+.-]*://[^\s/:@]+:[^\s/@]+@[^\s]+"#,
                options: [.caseInsensitive],
                preservesFirstCapture: false,
                blockedReason: nil
            ),
            Rule(
                kind: .bearerToken,
                pattern: #"\b(Authorization\s*:\s*Bearer\s+)([A-Za-z0-9._~+/=-]{8,})"#,
                options: [.caseInsensitive],
                preservesFirstCapture: true,
                blockedReason: nil
            ),
            Rule(
                kind: .basicToken,
                pattern: #"\b(Authorization\s*:\s*Basic\s+)([A-Za-z0-9._~+/=-]{8,})"#,
                options: [.caseInsensitive],
                preservesFirstCapture: true,
                blockedReason: nil
            ),
            Rule(
                kind: .passwordAssignment,
                pattern: #"\b((?:password|pass|pwd)\s*=\s*)(?:"[^"\n]*"|'[^'\n]*'|[^\s#]+)"#,
                options: [.caseInsensitive, .anchorsMatchLines],
                preservesFirstCapture: true,
                blockedReason: nil
            ),
            Rule(
                kind: .envValue,
                pattern: #"\b((?:token|api[_-]?key|secret|client_secret|access_token|refresh_token)\s*=\s*)(?:"[^"\n]*"|'[^'\n]*'|[^\s#]+)"#,
                options: [.caseInsensitive, .anchorsMatchLines],
                preservesFirstCapture: true,
                blockedReason: nil
            ),
            Rule(
                kind: .apiKey,
                pattern: #"\b(?:sk-ant-[A-Za-z0-9_-]{6,}|sk-[A-Za-z0-9_-]{8,}|xoxb-[A-Za-z0-9_-]{8,}(?:-[A-Za-z0-9_-]{4,})?|ghp_[A-Za-z0-9_]{8,})\b"#,
                options: [],
                preservesFirstCapture: false,
                blockedReason: nil
            )
        ]
    }

    public func redact(_ text: String) -> RedactionResult {
        var redactedText = text
        var findings: [RedactionFinding] = []
        var blockedReasons: [String] = []

        for rule in rules {
            let regex = try? NSRegularExpression(pattern: rule.pattern, options: rule.options)
            guard let regex else { continue }

            let fullRange = NSRange(redactedText.startIndex..<redactedText.endIndex, in: redactedText)
            let matches = regex.matches(in: redactedText, range: fullRange)
            guard !matches.isEmpty else { continue }

            findings.append(contentsOf: matches.map { _ in
                RedactionFinding(kind: rule.kind)
            })

            if let blockedReason = rule.blockedReason, !blockedReasons.contains(blockedReason) {
                blockedReasons.append(blockedReason)
            }

            for match in matches.reversed() {
                guard let range = Range(match.range, in: redactedText) else { continue }

                let replacementText: String
                if rule.preservesFirstCapture,
                   match.numberOfRanges > 1,
                   let prefixRange = Range(match.range(at: 1), in: redactedText) {
                    replacementText = String(redactedText[prefixRange]) + rule.kind.replacement
                } else {
                    replacementText = rule.kind.replacement
                }

                redactedText.replaceSubrange(range, with: replacementText)
            }
        }

        return RedactionResult(
            redactedText: redactedText,
            findings: findings,
            blockedReasons: blockedReasons
        )
    }
}
