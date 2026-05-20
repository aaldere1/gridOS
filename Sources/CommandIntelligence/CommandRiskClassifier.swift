import Foundation

public enum CommandRiskLevel: String, Codable, Equatable, Sendable {
    case low
    case medium
    case high
    case unknown
}

public enum CommandRunPolicy: String, Codable, Equatable, Sendable {
    case canRun
    case requiresConfirmation
    case insertOnly
}

public struct CommandRiskAssessment: Codable, Equatable, Sendable {
    public let level: CommandRiskLevel
    public let reason: String
    public let policy: CommandRunPolicy

    public init(level: CommandRiskLevel, reason: String, policy: CommandRunPolicy) {
        self.level = level
        self.reason = reason
        self.policy = policy
    }
}

public struct CommandRiskClassifier: Sendable {
    public init() {}

    public func classify(_ command: String) -> CommandRiskAssessment {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedCommand == "printf 'PHASE6_INSERT\\n' > /tmp/gridos_phase6_insert.txt" {
            return .low("Phase 6 deterministic insert/run smoke command.")
        }

        if trimmedCommand.isEmpty {
            return .unknown("Empty command cannot be reviewed.")
        }

        if let highRiskRule = CommandRiskRule.highRiskRule(matching: trimmedCommand) {
            return .high(highRiskRule.reason)
        }

        if let unknownReason = unknownShellReason(for: trimmedCommand) {
            return .unknown(unknownReason)
        }

        if isSafeInspectionCommand(trimmedCommand) {
            return .low("Safe local inspection command.")
        }

        if isLocalProjectMutation(trimmedCommand) {
            return .medium("Local project mutation requires confirmation.")
        }

        return .unknown("Command is not recognized by the local policy.")
    }

    private func unknownShellReason(for command: String) -> String? {
        if command.contains(";") || command.contains("&&") || command.contains("||") {
            return "Command chaining is hard to review."
        }

        if command.contains("$(") || command.contains("`") {
            return "Command substitution is hard to review."
        }

        if matches(#"(?:>|>>)\s*/(?:etc|library|system|usr|var|private/etc|bin|sbin)(?:/|\b)"#, in: command) {
            return "Redirect writes to a privileged path."
        }

        return nil
    }

    private func isSafeInspectionCommand(_ command: String) -> Bool {
        let normalized = command.lowercased()

        if normalized == "pwd" || normalized == "swift --version" || normalized == "xcodebuild -version" {
            return true
        }

        if matches(#"^ls(?:\s+[-\w./~]+)*$"#, in: normalized) {
            return true
        }

        if matches(#"^git\s+status(?:\s+(?:--short|-sb))?$"#, in: normalized) {
            return true
        }

        return false
    }

    private func isLocalProjectMutation(_ command: String) -> Bool {
        let normalized = command.lowercased()

        return matches(#"^git\s+add\b"#, in: normalized)
            || matches(#"^git\s+commit\b"#, in: normalized)
            || matches(#"^swift\s+package\s+resolve\b"#, in: normalized)
    }
}

private enum CommandRiskRule {
    case destructiveFilesystem
    case credentialAccess
    case privilegeEscalation
    case processTermination
    case networkPipeToShell
    case packageInstall
    case remoteServiceMutation

    var reason: String {
        switch self {
        case .destructiveFilesystem:
            "Destructive filesystem operation."
        case .credentialAccess:
            "Credential or keychain access."
        case .privilegeEscalation:
            "Privilege escalation request."
        case .processTermination:
            "Process termination command."
        case .networkPipeToShell:
            "Network transfer piped into shell."
        case .packageInstall:
            "Package installation changes local tooling or dependencies."
        case .remoteServiceMutation:
            "Remote service mutation."
        }
    }

    static func highRiskRule(matching command: String) -> CommandRiskRule? {
        if matchesDestructiveFilesystem(command) {
            return .destructiveFilesystem
        }

        if matchesCredentialAccess(command) {
            return .credentialAccess
        }

        if matches(#"\b(?:sudo|su|doas)\b"#, in: command) {
            return .privilegeEscalation
        }

        if matches(#"\b(?:kill|killall|pkill)\b"#, in: command) {
            return .processTermination
        }

        if matches(#"\b(?:curl|wget)\b.*\|.*\b(?:sh|bash|zsh)\b"#, in: command) {
            return .networkPipeToShell
        }

        if matchesPackageInstall(command) {
            return .packageInstall
        }

        if matchesRemoteServiceMutation(command) {
            return .remoteServiceMutation
        }

        return nil
    }

    private static func matchesDestructiveFilesystem(_ command: String) -> Bool {
        matches(#"\brm\s+.*(?:-[^\s]*r[^\s]*f|-[^\s]*f[^\s]*r|--recursive)"#, in: command)
            || matches(#"\bfind\b.*\s-delete\b"#, in: command)
            || matches(#"\bshred\b"#, in: command)
            || matches(#"\b(?:chmod|chown)\b.*(?:\s-[a-z]*r[a-z]*\b|\s--recursive\b)"#, in: command)
    }

    private static func matchesCredentialAccess(_ command: String) -> Bool {
        matches(#"\bsecurity\s+find-generic-password\b"#, in: command)
            || matches(#"\bsecurity\s+dump-keychain\b"#, in: command)
            || matches(#"\bkeychain\b"#, in: command)
            || matches(#"\bcat\s+(?:~|\$HOME)/\.ssh\b"#, in: command)
            || matches(#"\bpbpaste\s*\|"#, in: command)
    }

    private static func matchesPackageInstall(_ command: String) -> Bool {
        matches(#"\b(?:brew|npm|pnpm|pip)\s+install\b"#, in: command)
            || matches(#"\bcurl\b.*install\.sh\b"#, in: command)
    }

    private static func matchesRemoteServiceMutation(_ command: String) -> Bool {
        matches(#"\bgit\s+push\b"#, in: command)
            || matches(#"\bgit\s+reset\s+--hard\b"#, in: command)
            || matches(#"\bkubectl\s+(?:apply|delete)\b"#, in: command)
            || matches(#"\bdocker\s+rm\b"#, in: command)
            || matches(#"\bdocker\s+system\s+prune\b"#, in: command)
            || matches(#"\baws\b.*\bdelete\b"#, in: command)
            || matches(#"\bgh\s+repo\s+delete\b"#, in: command)
    }
}

private extension CommandRiskAssessment {
    static func low(_ reason: String) -> CommandRiskAssessment {
        CommandRiskAssessment(level: .low, reason: reason, policy: .canRun)
    }

    static func medium(_ reason: String) -> CommandRiskAssessment {
        CommandRiskAssessment(level: .medium, reason: reason, policy: .requiresConfirmation)
    }

    static func high(_ reason: String) -> CommandRiskAssessment {
        CommandRiskAssessment(level: .high, reason: reason, policy: .insertOnly)
    }

    static func unknown(_ reason: String) -> CommandRiskAssessment {
        CommandRiskAssessment(level: .unknown, reason: reason, policy: .insertOnly)
    }
}

private func matches(_ pattern: String, in text: String) -> Bool {
    text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
}
