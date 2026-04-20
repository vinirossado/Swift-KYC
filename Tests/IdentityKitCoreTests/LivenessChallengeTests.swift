import XCTest
@testable import IdentityKitCore

final class LivenessChallengeTests: XCTestCase {

    func testAllChallengesHaveInstructionText() {
        for challenge in LivenessChallenge.allCases {
            XCTAssertFalse(challenge.instructionText.isEmpty)
        }
    }

    func testAllChallengesHaveAccessibilityInstruction() {
        for challenge in LivenessChallenge.allCases {
            XCTAssertFalse(challenge.accessibilityInstruction.isEmpty)
            // Accessibility instructions should be longer/more descriptive than regular instructions.
            XCTAssertTrue(challenge.accessibilityInstruction.count > challenge.instructionText.count)
        }
    }

    func testCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for challenge in LivenessChallenge.allCases {
            let data = try encoder.encode(challenge)
            let decoded = try decoder.decode(LivenessChallenge.self, from: data)
            XCTAssertEqual(decoded, challenge)
        }
    }

    func testChallengeCount() {
        XCTAssertEqual(LivenessChallenge.allCases.count, 3)
    }
}
