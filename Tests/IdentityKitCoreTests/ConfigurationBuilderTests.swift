import XCTest
@testable import IdentityKitCore

final class ConfigurationBuilderTests: XCTestCase {

    // MARK: - Happy Path

    func testBuildWithAllRequiredFields() throws {
        let config = try IdentityKitConfiguration.Builder()
            .apiKey("pk_test_123")
            .sessionId("session-abc")
            .build()

        XCTAssertEqual(config.apiKey, "pk_test_123")
        XCTAssertEqual(config.sessionId, "session-abc")
        XCTAssertEqual(config.environment, .production)
        XCTAssertEqual(config.maxRetryAttempts, 3)
        XCTAssertEqual(config.challengeTimeoutSeconds, 30.0)
        XCTAssertEqual(config.logLevel, .warning)
        XCTAssertNil(config.hmacSecret)
    }

    func testBuildWithCustomValues() throws {
        let config = try IdentityKitConfiguration.Builder()
            .apiKey("pk_live_xyz")
            .sessionId("session-999")
            .environment(.staging)
            .enabledChecks([.document(.passport), .liveness])
            .logLevel(.debug)
            .hmacSecret("secret123")
            .maxRetryAttempts(5)
            .challengeTimeoutSeconds(45.0)
            .build()

        XCTAssertEqual(config.environment, .staging)
        XCTAssertEqual(config.enabledChecks.count, 2)
        XCTAssertEqual(config.logLevel, .debug)
        XCTAssertEqual(config.hmacSecret, "secret123")
        XCTAssertEqual(config.maxRetryAttempts, 5)
        XCTAssertEqual(config.challengeTimeoutSeconds, 45.0)
    }

    // MARK: - Validation Errors

    func testBuildFailsWithoutApiKey() {
        let builder = IdentityKitConfiguration.Builder()
            .sessionId("session-abc")

        XCTAssertThrowsError(try builder.build()) { error in
            guard case IdentityKitError.invalidConfiguration(let reason) = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
            XCTAssertTrue(reason.contains("apiKey"))
        }
    }

    func testBuildFailsWithEmptyApiKey() {
        let builder = IdentityKitConfiguration.Builder()
            .apiKey("")
            .sessionId("session-abc")

        XCTAssertThrowsError(try builder.build()) { error in
            guard case IdentityKitError.invalidConfiguration(let reason) = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
            XCTAssertTrue(reason.contains("apiKey"))
        }
    }

    func testBuildFailsWithoutSessionId() {
        let builder = IdentityKitConfiguration.Builder()
            .apiKey("pk_test_123")

        XCTAssertThrowsError(try builder.build()) { error in
            guard case IdentityKitError.invalidConfiguration(let reason) = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
            XCTAssertTrue(reason.contains("sessionId"))
        }
    }

    func testBuildFailsWithEmptyChecks() {
        let builder = IdentityKitConfiguration.Builder()
            .apiKey("pk_test_123")
            .sessionId("session-abc")
            .enabledChecks([])

        XCTAssertThrowsError(try builder.build()) { error in
            guard case IdentityKitError.invalidConfiguration(let reason) = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
            XCTAssertTrue(reason.contains("check"))
        }
    }

    func testBuildFailsWithNegativeRetries() {
        let builder = IdentityKitConfiguration.Builder()
            .apiKey("pk_test_123")
            .sessionId("session-abc")
            .maxRetryAttempts(-1)

        XCTAssertThrowsError(try builder.build()) { error in
            guard case IdentityKitError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
        }
    }

    func testBuildFailsWithZeroChallengeTimeout() {
        let builder = IdentityKitConfiguration.Builder()
            .apiKey("pk_test_123")
            .sessionId("session-abc")
            .challengeTimeoutSeconds(0)

        XCTAssertThrowsError(try builder.build()) { error in
            guard case IdentityKitError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
        }
    }

    // MARK: - Default Theme

    func testDefaultThemeIsApplied() throws {
        let config = try IdentityKitConfiguration.Builder()
            .apiKey("pk_test_123")
            .sessionId("session-abc")
            .build()

        XCTAssertEqual(config.theme.primaryColorHex, "#007AFF")
        XCTAssertEqual(config.theme.cornerRadius, 12.0)
    }
}
