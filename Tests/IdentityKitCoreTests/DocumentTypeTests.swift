import XCTest
@testable import IdentityKitCore

final class DocumentTypeTests: XCTestCase {

    func testPassportDoesNotRequireBackCapture() {
        XCTAssertFalse(DocumentType.passport.requiresBackCapture)
    }

    func testIdCardRequiresBackCapture() {
        XCTAssertTrue(DocumentType.idCard.requiresBackCapture)
    }

    func testDrivingLicenseRequiresBackCapture() {
        XCTAssertTrue(DocumentType.drivingLicense.requiresBackCapture)
    }

    func testResidencePermitRequiresBackCapture() {
        XCTAssertTrue(DocumentType.residencePermit.requiresBackCapture)
    }

    func testAllCasesAreCovered() {
        // Ensures we don't add a new case without updating requiresBackCapture.
        XCTAssertEqual(DocumentType.allCases.count, 4)
    }

    func testDisplayNames() {
        XCTAssertEqual(DocumentType.passport.displayName, "Passport")
        XCTAssertEqual(DocumentType.idCard.displayName, "ID Card")
        XCTAssertEqual(DocumentType.drivingLicense.displayName, "Driving License")
        XCTAssertEqual(DocumentType.residencePermit.displayName, "Residence Permit")
    }

    func testRawValueRoundTrip() {
        for docType in DocumentType.allCases {
            XCTAssertEqual(DocumentType(rawValue: docType.rawValue), docType)
        }
    }

    func testCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for docType in DocumentType.allCases {
            let data = try encoder.encode(docType)
            let decoded = try decoder.decode(DocumentType.self, from: data)
            XCTAssertEqual(decoded, docType)
        }
    }
}
