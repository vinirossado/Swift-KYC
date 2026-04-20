import Foundation

/// Immutable configuration for an IdentityKit verification session.
///
/// Use `IdentityKitConfiguration.Builder` to construct instances.
/// The builder validates required fields at build time, ensuring
/// the SDK always starts with a valid configuration.
public struct IdentityKitConfiguration: Sendable {

    /// API key for authenticating with the backend.
    public let apiKey: String

    /// Unique session identifier.
    public let sessionId: String

    /// Backend environment.
    public let environment: IdentityKitEnvironment

    /// Verification checks to perform.
    public let enabledChecks: [VerificationCheck]

    /// Visual theme.
    public let theme: IdentityKitTheme

    /// Log level threshold for the SDK's internal logger.
    public let logLevel: LogLevel

    /// Optional HMAC secret for request signing. When nil, signing is disabled.
    public let hmacSecret: String?

    /// Maximum number of retry attempts for network requests.
    public let maxRetryAttempts: Int

    /// Timeout in seconds for each liveness challenge.
    public let challengeTimeoutSeconds: TimeInterval

    // Private init — only the Builder can create instances.
    private init(
        apiKey: String,
        sessionId: String,
        environment: IdentityKitEnvironment,
        enabledChecks: [VerificationCheck],
        theme: IdentityKitTheme,
        logLevel: LogLevel,
        hmacSecret: String?,
        maxRetryAttempts: Int,
        challengeTimeoutSeconds: TimeInterval
    ) {
        self.apiKey = apiKey
        self.sessionId = sessionId
        self.environment = environment
        self.enabledChecks = enabledChecks
        self.theme = theme
        self.logLevel = logLevel
        self.hmacSecret = hmacSecret
        self.maxRetryAttempts = maxRetryAttempts
        self.challengeTimeoutSeconds = challengeTimeoutSeconds
    }

    // MARK: - Builder

    /// Fluent builder for constructing `IdentityKitConfiguration`.
    public final class Builder: @unchecked Sendable {
        private var apiKey: String?
        private var sessionId: String?
        private var environment: IdentityKitEnvironment = .production
        private var enabledChecks: [VerificationCheck] = [.document(.idCard), .liveness]
        private var theme: IdentityKitTheme = .default
        private var logLevel: LogLevel = .warning
        private var hmacSecret: String?
        private var maxRetryAttempts: Int = 3
        private var challengeTimeoutSeconds: TimeInterval = 30.0

        public init() {}

        @discardableResult
        public func apiKey(_ value: String) -> Builder {
            self.apiKey = value
            return self
        }

        @discardableResult
        public func sessionId(_ value: String) -> Builder {
            self.sessionId = value
            return self
        }

        @discardableResult
        public func environment(_ value: IdentityKitEnvironment) -> Builder {
            self.environment = value
            return self
        }

        @discardableResult
        public func enabledChecks(_ value: [VerificationCheck]) -> Builder {
            self.enabledChecks = value
            return self
        }

        @discardableResult
        public func theme(_ value: IdentityKitTheme) -> Builder {
            self.theme = value
            return self
        }

        @discardableResult
        public func logLevel(_ value: LogLevel) -> Builder {
            self.logLevel = value
            return self
        }

        @discardableResult
        public func hmacSecret(_ value: String?) -> Builder {
            self.hmacSecret = value
            return self
        }

        @discardableResult
        public func maxRetryAttempts(_ value: Int) -> Builder {
            self.maxRetryAttempts = value
            return self
        }

        @discardableResult
        public func challengeTimeoutSeconds(_ value: TimeInterval) -> Builder {
            self.challengeTimeoutSeconds = value
            return self
        }

        /// Builds and validates the configuration.
        ///
        /// - Throws: `IdentityKitError.invalidConfiguration` if required fields are missing.
        public func build() throws -> IdentityKitConfiguration {
            guard let apiKey, !apiKey.isEmpty else {
                throw IdentityKitError.invalidConfiguration(reason: "apiKey is required and must not be empty.")
            }
            guard let sessionId, !sessionId.isEmpty else {
                throw IdentityKitError.invalidConfiguration(reason: "sessionId is required and must not be empty.")
            }
            guard !enabledChecks.isEmpty else {
                throw IdentityKitError.invalidConfiguration(reason: "At least one verification check must be enabled.")
            }
            guard maxRetryAttempts >= 0 else {
                throw IdentityKitError.invalidConfiguration(reason: "maxRetryAttempts must be non-negative.")
            }
            guard challengeTimeoutSeconds > 0 else {
                throw IdentityKitError.invalidConfiguration(reason: "challengeTimeoutSeconds must be positive.")
            }

            return IdentityKitConfiguration(
                apiKey: apiKey,
                sessionId: sessionId,
                environment: environment,
                enabledChecks: enabledChecks,
                theme: theme,
                logLevel: logLevel,
                hmacSecret: hmacSecret,
                maxRetryAttempts: maxRetryAttempts,
                challengeTimeoutSeconds: challengeTimeoutSeconds
            )
        }
    }
}
