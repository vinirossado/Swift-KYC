import Foundation

/// Supported identity document types for verification.
public enum DocumentType: String, Sendable, Codable, CaseIterable {
    case passport
    case idCard
    case drivingLicense
    case residencePermit

    /// Whether this document type requires capturing both front and back sides.
    public var requiresBackCapture: Bool {
        switch self {
        case .passport:
            return false
        case .idCard, .drivingLicense, .residencePermit:
            return true
        }
    }

    /// Human-readable display name for UI presentation.
    public var displayName: String {
        switch self {
        case .passport: return "Passport"
        case .idCard: return "ID Card"
        case .drivingLicense: return "Driving License"
        case .residencePermit: return "Residence Permit"
        }
    }
}
