import XCTest
@testable import IdentityKitCapture
import IdentityKitCore

final class LivenessCaptureControllerTests: XCTestCase {

    func testRandomChallengesReturnsRequestedCount() {
        let challenges = LivenessCaptureController.randomChallenges(count: 2)
        XCTAssertEqual(challenges.count, 2)
    }

    func testRandomChallengesNeverExceedsAvailable() {
        // Requesting more than allCases should cap at allCases.count.
        let challenges = LivenessCaptureController.randomChallenges(count: 10)
        XCTAssertLesssThanOrEqual(challenges.count, LivenessChallenge.allCases.count)
    }

    func testRandomChallengesAreFromValidSet() {
        let allValid = Set(LivenessChallenge.allCases)
        for _ in 0..<20 {
            let challenges = LivenessCaptureController.randomChallenges(count: 2)
            for challenge in challenges {
                XCTAssertTrue(allValid.contains(challenge))
            }
        }
    }
}

// Helper for <= comparison
private func XCTAssertLesssThanOrEqual<T: Comparable>(
    _ a: T, _ b: T,
    file: StaticString = #filePath, line: UInt = #line
) {
    XCTAssertTrue(a <= b, "\(a) is not <= \(b)", file: file, line: line)
}
