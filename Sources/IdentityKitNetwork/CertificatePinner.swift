import Foundation
import CryptoKit
import IdentityKitCore

/// Validates server certificates against embedded public key hashes.
///
/// Uses public key pinning (not full certificate pinning) so that
/// certificate rotation doesn't break the SDK — only key changes do.
/// The host app provides SHA-256 hashes of the SubjectPublicKeyInfo
/// at configuration time.
public final class CertificatePinner: NSObject, @unchecked Sendable {
    private let pinnedKeyHashes: Set<String>
    private let logger: IdentityKitLogger?
    private let logLevel: LogLevel

    /// - Parameter pinnedKeyHashes: Base64-encoded SHA-256 hashes of the server's SPKI.
    public init(
        pinnedKeyHashes: Set<String>,
        logger: IdentityKitLogger? = nil,
        logLevel: LogLevel = .warning
    ) {
        self.pinnedKeyHashes = pinnedKeyHashes
        self.logger = logger
        self.logLevel = logLevel
    }

    /// Evaluates the server trust against pinned keys.
    /// Returns `true` if at least one certificate in the chain matches a pinned key hash.
    public func validate(serverTrust: SecTrust) -> Bool {
        guard !pinnedKeyHashes.isEmpty else {
            // No pins configured — skip pinning (dev/staging mode).
            return true
        }

        let certificateCount = SecTrustGetCertificateCount(serverTrust)

        for index in 0..<certificateCount {
            guard let chain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
                  index < chain.count else {
                continue
            }

            let cert = chain[index]

            guard let publicKey = SecCertificateCopyKey(cert),
                  let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
                continue
            }

            let hash = sha256Base64(of: publicKeyData)
            if pinnedKeyHashes.contains(hash) {
                return true
            }
        }

        logger?.log(
            level: .warning,
            message: "Certificate pinning validation failed — no matching public key found",
            file: #file,
            function: #function,
            line: #line
        )

        return false
    }

    // MARK: - Private

    private func sha256Base64(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
    }
}

// MARK: - URLSessionDelegate

extension CertificatePinner: URLSessionDelegate {
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if validate(serverTrust: serverTrust) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
