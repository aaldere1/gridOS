import XCTest
@testable import TerminalCore

final class TerminalSessionConfigurationTests: XCTestCase {
    func testDefaultShellFallsBackToZshWhenEnvironmentIsMissing() {
        XCTAssertEqual(TerminalSessionConfiguration.resolvedDefaultShell(environment: [:]), "/bin/zsh")
    }

    func testDefaultShellUsesAbsoluteShellEnvironmentValue() {
        XCTAssertEqual(
            TerminalSessionConfiguration.resolvedDefaultShell(environment: ["SHELL": "/opt/homebrew/bin/fish"]),
            "/opt/homebrew/bin/fish"
        )
    }

    func testDefaultShellIgnoresRelativeShellEnvironmentValue() {
        XCTAssertEqual(
            TerminalSessionConfiguration.resolvedDefaultShell(environment: ["SHELL": "zsh"]),
            "/bin/zsh"
        )
    }

    func testLoginShellNameUsesBasename() {
        let configuration = TerminalSessionConfiguration(shellPath: "/bin/zsh")

        XCTAssertEqual(configuration.shellDisplayName, "zsh")
        XCTAssertEqual(configuration.loginShellName, "-zsh")
    }

    func testStartupCommandCanBeReadFromProcessArguments() {
        let configuration = TerminalSessionConfiguration.fromProcessArguments([
            "gridOS",
            "--cmd",
            "echo ok"
        ])

        XCTAssertEqual(configuration.startupCommand, "echo ok")
    }

    func testSessionStateReportsActiveOnlyWhenRunning() {
        XCTAssertFalse(TerminalSessionState.idle.isActive)
        XCTAssertTrue(TerminalSessionState.running.isActive)
        XCTAssertFalse(TerminalSessionState.terminated(exitCode: 0).isActive)
    }
}
