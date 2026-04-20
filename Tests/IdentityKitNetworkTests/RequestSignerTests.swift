import XCTest
@testable import IdentityKitNetwork

final class RequestSignerTests: XCTestCase {

    func testSignProducesDeterministicOutput() {
        let signer = RequestSigner(secret: "test-secret")
        let data = Data("hello world".utf8)

        let sig1 = signer.sign(data: data)
        let sig2 = signer.sign(data: data)

        XCTAssertEqual(sig1, sig2)
    }

    func testSignProducesHexString() {
        let signer = RequestSigner(secret: "key")
        let data = Data("test".utf8)
        let signature = signer.sign(data: data)

        // HMAC-SHA256 produces 32 bytes → 64 hex characters.
        XCTAssertEqual(signature.count, 64)

        // Should only contain hex characters.
        let hexCharSet = CharacterSet(charactersIn: "0123456789abcdef")
        XCTAssertTrue(
            signature.unicodeScalars.allSatisfy { hexCharSet.contains($0) },
            "Signature should be hex-encoded"
        )
    }

    func testDifferentSecretsProduceDifferentSignatures() {
        let data = Data("payload".utf8)
        let sig1 = RequestSigner(secret: "secret-a").sign(data: data)
        let sig2 = RequestSigner(secret: "secret-b").sign(data: data)
        XCTAssertNotEqual(sig1, sig2)
    }

    func testDifferentDataProducesDifferentSignatures() {
        let signer = RequestSigner(secret: "key")
        let sig1 = signer.sign(data: Data("data-a".utf8))
        let sig2 = signer.sign(data: Data("data-b".utf8))
        XCTAssertNotEqual(sig1, sig2)
    }

    func testSignRequestAddsHeader() {
        let signer = RequestSigner(secret: "key")
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpBody = Data("body".utf8)

        signer.sign(request: &request)

        XCTAssertNotNil(request.value(forHTTPHeaderField: "X-Signature"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Signature")?.count, 64)
    }

    func testSignRequestWithoutBodyDoesNothing() {
        let signer = RequestSigner(secret: "key")
        var request = URLRequest(url: URL(string: "https://example.com")!)

        signer.sign(request: &request)

        XCTAssertNil(request.value(forHTTPHeaderField: "X-Signature"))
    }
}
