import Foundation
import CryptoKit
import IdentityKitCore

/// Signs outgoing request payloads using HMAC-SHA256.
///
/// When enabled, adds an `X-Signature` header containing the HMAC
/// of the request body. The backend can verify this to ensure
/// payload integrity and authenticity.
public struct RequestSigner: Sendable {
    private let secretKey: SymmetricKey

    public init(secret: String) {
        self.secretKey = SymmetricKey(data: Data(secret.utf8))
    }

    /// Signs the given data and returns a hex-encoded HMAC-SHA256 signature.
    public func sign(data: Data) -> String {
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: secretKey)
        return signature.map { String(format: "%02x", $0) }.joined()
    }

    /// Applies the signature header to a mutable URLRequest.
    public func sign(request: inout URLRequest) {
        guard let body = request.httpBody else { return }
        let signature = sign(data: body)
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
    }
}
