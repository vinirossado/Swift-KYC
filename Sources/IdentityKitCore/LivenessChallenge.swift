import Foundation

/// Challenges presented during the liveness check to confirm a real person.
public enum LivenessChallenge: String, Sendable, Codable, CaseIterable {
    case blink
    case turnLeft
    case turnRight

    /// Instruction text shown to the user during this challenge.
    public var instructionText: String {
        switch self {
        case .blink: return "Blink your eyes"
        case .turnLeft: return "Slowly turn your head left"
        case .turnRight: return "Slowly turn your head right"
        }
    }

    /// Accessibility description for VoiceOver users.
    public var accessibilityInstruction: String {
        switch self {
        case .blink: return "Please blink your eyes naturally. The camera will detect the motion."
        case .turnLeft: return "Please slowly turn your head to the left."
        case .turnRight: return "Please slowly turn your head to the right."
        }
    }
}
