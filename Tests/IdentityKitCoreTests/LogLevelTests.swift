import XCTest
@testable import IdentityKitCore

final class LogLevelTests: XCTestCase {

    func testLogLevelOrdering() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
        XCTAssertTrue(LogLevel.error < LogLevel.none)
    }

    func testAllLogLevelsExist() {
        XCTAssertEqual(LogLevel.allCases.count, 5)
    }
}
