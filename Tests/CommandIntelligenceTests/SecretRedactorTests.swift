import XCTest
@testable import CommandIntelligence

final class SecretRedactorTests: XCTestCase {
    func testRedactsAPIKeyFamilies() {
        let input = """
        anthropic=sk-ant-api03-abcdEFGH1234567890
        openai sk-proj_abcdefghijklmnopqrstuvwxyz
        slack xoxb-123456789012-abcdefghijklmnop
        github ghp_abcdefghijklmnopqrstuvwxyz123456
        """

        let result = SecretRedactor().redact(input)

        XCTAssertFalse(result.redactedText.contains("sk-ant-api03"))
        XCTAssertFalse(result.redactedText.contains("sk-proj_"))
        XCTAssertFalse(result.redactedText.contains("xoxb-123456789012"))
        XCTAssertFalse(result.redactedText.contains("ghp_abcdefghijklmnopqrstuvwxyz"))
        XCTAssertEqual(result.findings.filter { $0.kind == .apiKey }.count, 4)
        XCTAssertTrue(result.redactedText.contains("[REDACTED API KEY]"))
    }

    func testRedactsBearerAndBasicTokens() {
        let input = """
        Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
        Authorization: Basic dXNlcjpwYXNzd29yZA==
        """

        let result = SecretRedactor().redact(input)

        XCTAssertFalse(result.redactedText.contains("eyJhbGciOiJIUzI1NiI"))
        XCTAssertFalse(result.redactedText.contains("dXNlcjpwYXNzd29yZA"))
        XCTAssertTrue(result.redactedText.contains("Authorization: Bearer [REDACTED BEARER TOKEN]"))
        XCTAssertTrue(result.redactedText.contains("Authorization: Basic [REDACTED BASIC TOKEN]"))
        XCTAssertEqual(result.findings.map(\.kind), [.bearerToken, .basicToken])
    }

    func testRedactsPrivateKeyBlocks() {
        let input = """
        before
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAA=
        -----END OPENSSH PRIVATE KEY-----
        after
        """

        let result = SecretRedactor().redact(input)

        XCTAssertFalse(result.redactedText.contains("b3BlbnNzaC1rZXktdjE"))
        XCTAssertTrue(result.redactedText.contains("[REDACTED PRIVATE KEY]"))
        XCTAssertEqual(result.findings.first?.kind, .privateKey)
        XCTAssertFalse(result.blockedReasons.isEmpty)
    }

    func testRedactsPasswordAssignmentsAndEnvValues() {
        let input = """
        password=hunter2
        PASS='super-secret'
        TOKEN=token-value
        API_KEY="key-value"
        SECRET=secret-value
        """

        let result = SecretRedactor().redact(input)

        XCTAssertFalse(result.redactedText.contains("hunter2"))
        XCTAssertFalse(result.redactedText.contains("super-secret"))
        XCTAssertFalse(result.redactedText.contains("token-value"))
        XCTAssertFalse(result.redactedText.contains("key-value"))
        XCTAssertFalse(result.redactedText.contains("secret-value"))
        XCTAssertEqual(result.findings.filter { $0.kind == .passwordAssignment }.count, 2)
        XCTAssertEqual(result.findings.filter { $0.kind == .envValue }.count, 3)
        XCTAssertTrue(result.redactedText.contains("password=[REDACTED PASSWORD]"))
        XCTAssertTrue(result.redactedText.contains("TOKEN=[REDACTED ENV VALUE]"))
    }

    func testRedactsCredentialURLs() {
        let input = "clone from https://deploy-user:deploy-pass@example.com/private/repo.git now"

        let result = SecretRedactor().redact(input)

        XCTAssertFalse(result.redactedText.contains("deploy-user"))
        XCTAssertFalse(result.redactedText.contains("deploy-pass"))
        XCTAssertTrue(result.redactedText.contains("[REDACTED CREDENTIAL URL]"))
        XCTAssertEqual(result.findings.first?.kind, .credentialURL)
    }

    func testRedactsRealisticStructuredConfigAndTerminalOutputSecrets() {
        let input = """
        AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
        AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        {"api_key": "sk-proj_abcdefghijklmnopqrstuvwxyz"}
        access_token: ghp_abcdefghijklmnopqrstuvwxyz123456
        curl output:
        HTTP/1.1 401 Unauthorized
        Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.secret
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAA=
        -----END OPENSSH PRIVATE KEY-----
        """

        let result = SecretRedactor().redact(input)

        XCTAssertFalse(result.redactedText.contains("AKIAIOSFODNN7EXAMPLE"))
        XCTAssertFalse(result.redactedText.contains("wJalrXUtnFEMI"))
        XCTAssertFalse(result.redactedText.contains("sk-proj_abcdefghijklmnopqrstuvwxyz"))
        XCTAssertFalse(result.redactedText.contains("ghp_abcdefghijklmnopqrstuvwxyz123456"))
        XCTAssertFalse(result.redactedText.contains("eyJhbGciOiJIUzI1NiI"))
        XCTAssertFalse(result.redactedText.contains("b3BlbnNzaC1rZXktdjE"))
        XCTAssertTrue(result.redactedText.contains("AWS_ACCESS_KEY_ID=[REDACTED ENV VALUE]"))
        XCTAssertTrue(result.redactedText.contains("\"api_key\": [REDACTED ENV VALUE]"))
        XCTAssertTrue(result.redactedText.contains("access_token: [REDACTED ENV VALUE]"))
        XCTAssertTrue(result.redactedText.contains("Authorization: Bearer [REDACTED BEARER TOKEN]"))
        XCTAssertTrue(result.redactedText.contains("[REDACTED PRIVATE KEY]"))
        XCTAssertTrue(result.blockedReasons.contains("Private key block requires manual review before sending."))
    }

    func testLeavesBenignFalsePositiveTextUnchanged() {
        let input = "false-positive: task tokenization api keyword should not redact"

        let result = SecretRedactor().redact(input)

        XCTAssertEqual(result.redactedText, input)
        XCTAssertTrue(result.findings.isEmpty)
        XCTAssertTrue(result.blockedReasons.isEmpty)
    }
}
