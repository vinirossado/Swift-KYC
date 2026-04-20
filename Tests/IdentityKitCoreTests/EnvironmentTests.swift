import XCTest
@testable import IdentityKitCore

final class EnvironmentTests: XCTestCase {

    func testProductionBaseURL() {
        let url = IdentityKitEnvironment.production.baseURL
        XCTAssertEqual(url.scheme, "https")
        XCTAssertTrue(url.absoluteString.contains("api.identitykit.io"))
    }

    func testStagingBaseURL() {
        let url = IdentityKitEnvironment.staging.baseURL
        XCTAssertEqual(url.scheme, "https")
        XCTAssertTrue(url.absoluteString.contains("staging"))
    }

    func testMockBaseURL() {
        let url = IdentityKitEnvironment.mock.baseURL
        XCTAssertTrue(url.absoluteString.contains("mock"))
    }

    func testAllEnvironmentsUseHTTPS() {
        let environments: [IdentityKitEnvironment] = [.production, .staging, .mock]
        for env in environments {
            XCTAssertEqual(env.baseURL.scheme, "https", "\(env) should use HTTPS")
        }
    }
}
