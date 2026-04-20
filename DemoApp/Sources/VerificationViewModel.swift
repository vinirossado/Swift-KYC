import SwiftUI
import IdentityKitCore

enum AppEnvironment: String, CaseIterable {
    case mock
    case staging

    var sdkEnvironment: IdentityKitEnvironment {
        switch self {
        case .mock: return .mock
        case .staging: return .staging
        }
    }
}

/// View model that manages the verification flow state.
///
/// Bridges the SDK's delegate callbacks into SwiftUI-friendly published properties.
@MainActor
final class VerificationViewModel: ObservableObject {
    @Published var showingVerification = false
    @Published var showingResult = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var simulateNetworkFailure = false
    @Published var selectedEnvironment: AppEnvironment = .mock
    @Published var verificationResult: VerificationResultData?

    func startVerification() {
        showingVerification = true
    }

    func handleResult(_ result: VerificationResultData) {
        showingVerification = false
        verificationResult = result
        showingResult = true
    }

    func handleError(_ message: String) {
        showingVerification = false
        errorMessage = message
        showingError = true
    }

    func handleCancel() {
        showingVerification = false
    }

    /// Builds the SDK configuration based on current settings.
    func buildConfiguration() throws -> IdentityKitConfiguration {
        try IdentityKitConfiguration.Builder()
            .apiKey("pk_demo_\(UUID().uuidString.prefix(8))")
            .sessionId("session-\(UUID().uuidString.prefix(8))")
            .environment(selectedEnvironment.sdkEnvironment)
            .enabledChecks([.document(.passport), .liveness])
            .logLevel(.debug)
            .build()
    }
}

/// SwiftUI-friendly representation of the verification result.
struct VerificationResultData: Identifiable {
    let id = UUID()
    let sessionId: String
    let documentImages: [DocumentImageData]
    let livenessFrameCount: Int
    let completedAt: Date
    let metadata: [String: String]
}

struct DocumentImageData: Identifiable {
    let id = UUID()
    let typeName: String
    let frontData: Data
    let backData: Data?
}
