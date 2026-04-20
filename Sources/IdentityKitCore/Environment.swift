import Foundation

/// The backend environment the SDK should communicate with.
public enum IdentityKitEnvironment: String, Sendable {
    case production
    case staging
    case mock

    /// Base URL for API requests in this environment.
    public var baseURL: URL {
        switch self {
        case .production:
            // Using a placeholder URL — host app provides the real one via configuration.
            return URL(string: "https://api.identitykit.io/v1")!
        case .staging:
            return URL(string: "https://api.staging.identitykit.io/v1")!
        case .mock:
            return URL(string: "https://mock.identitykit.local/v1")!
        }
    }
}
