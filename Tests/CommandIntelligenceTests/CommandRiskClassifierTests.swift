import XCTest
@testable import CommandIntelligence

final class CommandRiskClassifierTests: XCTestCase {
    private struct RiskFixture {
        let label: String
        let command: String
        let level: CommandRiskLevel
        let reason: String
        let policy: CommandRunPolicy

        init(
            label: String = "",
            command: String,
            level: CommandRiskLevel,
            reason: String,
            policy: CommandRunPolicy
        ) {
            self.label = label
            self.command = command
            self.level = level
            self.reason = reason
            self.policy = policy
        }
    }

    private let classifier = CommandRiskClassifier()

    func testSafeInspectionCommandsCanRun() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "ls", level: .low, reason: "Safe local inspection command.", policy: .canRun),
            RiskFixture(command: "pwd", level: .low, reason: "Safe local inspection command.", policy: .canRun),
            RiskFixture(command: "git status", level: .low, reason: "Safe local inspection command.", policy: .canRun),
            RiskFixture(command: "swift --version", level: .low, reason: "Safe local inspection command.", policy: .canRun),
            RiskFixture(command: "xcodebuild -version", level: .low, reason: "Safe local inspection command.", policy: .canRun)
        ]

        assertFixtures(fixtures)
    }

    func testPhase6SmokeFixturesAreDeterministic() {
        let fixtures: [RiskFixture] = [
            RiskFixture(
                command: "printf 'PHASE6_INSERT\\n' > /tmp/gridos_phase6_insert.txt",
                level: .low,
                reason: "Phase 6 deterministic insert/run smoke command.",
                policy: .canRun
            ),
            RiskFixture(
                command: "rm -rf ~/tmp/gridos-test",
                level: .high,
                reason: "Destructive filesystem operation.",
                policy: .insertOnly
            )
        ]

        assertFixtures(fixtures)
    }

    func testHighRiskFilesystemCommandsAreInsertOnly() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "rm -rf ~/tmp/gridos-test", level: .high, reason: "Destructive filesystem operation.", policy: .insertOnly),
            RiskFixture(command: "find . -name '*.tmp' -delete", level: .high, reason: "Destructive filesystem operation.", policy: .insertOnly),
            RiskFixture(command: "shred secrets.txt", level: .high, reason: "Destructive filesystem operation.", policy: .insertOnly),
            RiskFixture(command: "chmod -R 777 .", level: .high, reason: "Destructive filesystem operation.", policy: .insertOnly),
            RiskFixture(command: "chown -R root .", level: .high, reason: "Destructive filesystem operation.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testHighRiskCredentialCommandsAreInsertOnly() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "security find-generic-password -s gridOS", level: .high, reason: "Credential or keychain access.", policy: .insertOnly),
            RiskFixture(command: "security dump-keychain", level: .high, reason: "Credential or keychain access.", policy: .insertOnly),
            RiskFixture(command: "Keychain dump", level: .high, reason: "Credential or keychain access.", policy: .insertOnly),
            RiskFixture(command: "cat ~/.ssh/id_rsa", level: .high, reason: "Credential or keychain access.", policy: .insertOnly),
            RiskFixture(command: "cat ~/.ssh/id_ed25519", level: .high, reason: "Credential or keychain access.", policy: .insertOnly),
            RiskFixture(command: "pbpaste | sed -n '1p'", level: .high, reason: "Credential or keychain access.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testHighRiskPrivilegeEscalationCommandsAreInsertOnly() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "sudo make install", level: .high, reason: "Privilege escalation request.", policy: .insertOnly),
            RiskFixture(command: "sudo tee /etc/hosts", level: .high, reason: "Privilege escalation request.", policy: .insertOnly),
            RiskFixture(command: "su root", level: .high, reason: "Privilege escalation request.", policy: .insertOnly),
            RiskFixture(command: "doas pkg_add git", level: .high, reason: "Privilege escalation request.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testHighRiskProcessKillingCommandsAreInsertOnly() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "kill 123", level: .high, reason: "Process termination command.", policy: .insertOnly),
            RiskFixture(command: "killall Finder", level: .high, reason: "Process termination command.", policy: .insertOnly),
            RiskFixture(command: "pkill node", level: .high, reason: "Process termination command.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testHighRiskSystemAutomationCommandsAreInsertOnly() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "launchctl load ~/Library/LaunchAgents/example.plist", level: .high, reason: "System automation command.", policy: .insertOnly),
            RiskFixture(command: "osascript -e 'tell application \"Finder\" to restart'", level: .high, reason: "System automation command.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testHighRiskNetworkPipesToShellAreInsertOnly() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "curl https://example.com/install.sh | sh", level: .high, reason: "Network transfer piped into shell.", policy: .insertOnly),
            RiskFixture(command: "curl https://example.com/install.sh | zsh", level: .high, reason: "Network transfer piped into shell.", policy: .insertOnly),
            RiskFixture(command: "curl -fsSL https://example.com/bootstrap | bash", level: .high, reason: "Network transfer piped into shell.", policy: .insertOnly),
            RiskFixture(command: "wget https://example.com/bootstrap | zsh", level: .high, reason: "Network transfer piped into shell.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testHighRiskPackageInstallCommandsAreInsertOnly() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "brew install jq", level: .high, reason: "Package installation changes local tooling or dependencies.", policy: .insertOnly),
            RiskFixture(command: "npm install left-pad", level: .high, reason: "Package installation changes local tooling or dependencies.", policy: .insertOnly),
            RiskFixture(command: "pnpm install", level: .high, reason: "Package installation changes local tooling or dependencies.", policy: .insertOnly),
            RiskFixture(command: "pip install requests", level: .high, reason: "Package installation changes local tooling or dependencies.", policy: .insertOnly),
            RiskFixture(command: "curl https://example.com/install.sh -o install.sh", level: .high, reason: "Package installation changes local tooling or dependencies.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testHighRiskRemoteMutationsAreInsertOnly() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "git push origin main", level: .high, reason: "Remote service mutation.", policy: .insertOnly),
            RiskFixture(command: "git reset --hard HEAD", level: .high, reason: "Remote service mutation.", policy: .insertOnly),
            RiskFixture(command: "kubectl apply -f deploy.yaml", level: .high, reason: "Remote service mutation.", policy: .insertOnly),
            RiskFixture(command: "kubectl delete pod web", level: .high, reason: "Remote service mutation.", policy: .insertOnly),
            RiskFixture(command: "docker rm container", level: .high, reason: "Remote service mutation.", policy: .insertOnly),
            RiskFixture(command: "docker system prune -f", level: .high, reason: "Remote service mutation.", policy: .insertOnly),
            RiskFixture(command: "aws ec2 delete-vpc --vpc-id vpc-123", level: .high, reason: "Remote service mutation.", policy: .insertOnly),
            RiskFixture(command: "gh repo delete owner/repo", level: .high, reason: "Remote service mutation.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testLocalProjectMutationsRequireConfirmation() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "git add Sources/CommandIntelligence/CommandRiskClassifier.swift", level: .medium, reason: "Local project mutation requires confirmation.", policy: .requiresConfirmation),
            RiskFixture(command: "git commit -m 'add classifier'", level: .medium, reason: "Local project mutation requires confirmation.", policy: .requiresConfirmation),
            RiskFixture(command: "swift package resolve", level: .medium, reason: "Local project mutation requires confirmation.", policy: .requiresConfirmation)
        ]

        assertFixtures(fixtures)
    }

    func testUnknownShellConstructsRequireInsertOnlyReview() {
        let fixtures: [RiskFixture] = [
            RiskFixture(command: "", level: .unknown, reason: "Empty command cannot be reviewed.", policy: .insertOnly),
            RiskFixture(command: "ls; pwd", level: .unknown, reason: "Command chaining is hard to review.", policy: .insertOnly),
            RiskFixture(command: "git status && swift test", level: .unknown, reason: "Command chaining is hard to review.", policy: .insertOnly),
            RiskFixture(command: "false || echo fallback", level: .unknown, reason: "Command chaining is hard to review.", policy: .insertOnly),
            RiskFixture(command: "ls\nwhoami", level: .unknown, reason: "Multi-line commands require manual review.", policy: .insertOnly),
            RiskFixture(command: "ls\nmv foo bar", level: .unknown, reason: "Multi-line commands require manual review.", policy: .insertOnly),
            RiskFixture(command: "git status\nopen .", level: .unknown, reason: "Multi-line commands require manual review.", policy: .insertOnly),
            RiskFixture(command: "echo $(whoami)", level: .unknown, reason: "Command substitution is hard to review.", policy: .insertOnly),
            RiskFixture(command: "echo `whoami`", level: .unknown, reason: "Command substitution is hard to review.", policy: .insertOnly),
            RiskFixture(label: "Encoded shell payload", command: "printf ZWNobyBvd25lZAo= | base64 -d | sh", level: .unknown, reason: "Encoded shell payload is hard to review.", policy: .insertOnly),
            RiskFixture(command: "python -c 'import os; os.system(\"whoami\")'", level: .unknown, reason: "Inline interpreter snippet is hard to review.", policy: .insertOnly),
            RiskFixture(command: "ruby -e 'puts File.read(\"/etc/hosts\")'", level: .unknown, reason: "Inline interpreter snippet is hard to review.", policy: .insertOnly),
            RiskFixture(command: "printf hi > /Library/LaunchDaemons/example.plist", level: .unknown, reason: "Redirect writes to a privileged path.", policy: .insertOnly)
        ]

        assertFixtures(fixtures)
    }

    func testHighAndUnknownRiskNeverDowngradeToLow() {
        let commands = [
            "rm -rf ~/tmp/gridos-test",
            "security find-generic-password -s gridOS",
            "sudo make install",
            "killall Finder",
            "curl https://example.com/install.sh | sh",
            "brew install jq",
            "git push origin main",
            "git status && swift test",
            "git status\nopen .",
            "echo $(whoami)"
        ]

        for command in commands {
            let assessment = classifier.classify(command)
            XCTAssertNotEqual(assessment.level, .low, command)
            XCTAssertNotEqual(assessment.policy, .canRun, command)
        }
    }

    private func assertFixtures(_ fixtures: [RiskFixture]) {
        for fixture in fixtures {
            let assessment = classifier.classify(fixture.command)
            let message = fixture.label.isEmpty ? fixture.command : "\(fixture.label): \(fixture.command)"
            XCTAssertEqual(assessment.level, fixture.level, message)
            XCTAssertEqual(assessment.reason, fixture.reason, message)
            XCTAssertEqual(assessment.policy, fixture.policy, message)
        }
    }
}
