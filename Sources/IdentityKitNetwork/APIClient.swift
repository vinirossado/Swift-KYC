import Foundation
import IdentityKitCore

/// HTTP methods supported by the API client.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Encapsulates an API request with typed response decoding.
public struct APIRequest<Response: Decodable & Sendable>: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let body: Data?
    public let headers: [String: String]

    public init(
        path: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.headers = headers
    }
}

/// Networking client that wraps URLSession with retry, circuit breaker, and signing.
///
/// All requests are async/await. Logging redacts PII — only status codes,
/// paths, and timing are recorded, never headers or bodies.
public final class APIClient: Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let retryPolicy: RetryPolicy
    private let circuitBreaker: CircuitBreaker
    private let requestSigner: RequestSigner?
    private let apiKey: String
    private let logger: IdentityKitLogger
    private let logLevel: LogLevel
    private let decoder: JSONDecoder

    public init(
        baseURL: URL,
        apiKey: String,
        session: URLSession? = nil,
        retryPolicy: RetryPolicy = RetryPolicy(),
        circuitBreaker: CircuitBreaker = CircuitBreaker(),
        requestSigner: RequestSigner? = nil,
        certificatePinner: CertificatePinner? = nil,
        logger: IdentityKitLogger = DefaultLogger(),
        logLevel: LogLevel = .warning
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.retryPolicy = retryPolicy
        self.circuitBreaker = circuitBreaker
        self.requestSigner = requestSigner
        self.logger = logger
        self.logLevel = logLevel

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 120
            // Using the pinner as the delegate if provided.
            self.session = URLSession(
                configuration: config,
                delegate: certificatePinner,
                delegateQueue: nil
            )
        }
    }

    /// Performs a request with automatic retry and circuit breaker protection.
    public func perform<T: Decodable & Sendable>(_ request: APIRequest<T>) async throws -> T {
        // Circuit breaker check — fails fast if backend is considered down.
        try circuitBreaker.preRequest()

        var lastError: Error = IdentityKitError.internalError(reason: "No attempts made")

        for attempt in 0...retryPolicy.maxAttempts {
            do {
                let urlRequest = try buildURLRequest(for: request)
                let startTime = CFAbsoluteTimeGetCurrent()

                let (data, response) = try await session.data(for: urlRequest)

                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                log(.debug, "[\(request.method.rawValue)] \(request.path) → \(elapsed.rounded())ms")

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw IdentityKitError.networkFailed(underlying: URLError(.badServerResponse))
                }

                let statusCode = httpResponse.statusCode
                log(.debug, "Status: \(statusCode) for \(request.path)")

                guard (200..<300).contains(statusCode) else {
                    if retryPolicy.isRetryable(statusCode: statusCode) && attempt < retryPolicy.maxAttempts {
                        circuitBreaker.recordFailure()
                        let delay = retryPolicy.delay(forAttempt: attempt)
                        log(.info, "Retrying \(request.path) in \(delay)s (attempt \(attempt + 1))")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    circuitBreaker.recordFailure()
                    throw IdentityKitError.networkFailed(
                        underlying: URLError(.init(rawValue: statusCode))
                    )
                }

                circuitBreaker.recordSuccess()
                let decoded = try decoder.decode(T.self, from: data)
                return decoded

            } catch let error as IdentityKitError {
                lastError = error
                // Never retry IdentityKit-specific errors — they represent
                // final outcomes (circuit breaker open, non-retryable status, etc.)
                throw error
            } catch {
                lastError = error

                if retryPolicy.isRetryable(error: error) && attempt < retryPolicy.maxAttempts {
                    circuitBreaker.recordFailure()
                    let delay = retryPolicy.delay(forAttempt: attempt)
                    log(.info, "Retrying \(request.path) after error: \(error.localizedDescription) in \(delay)s")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                circuitBreaker.recordFailure()
                throw IdentityKitError.networkFailed(underlying: error)
            }
        }

        throw IdentityKitError.networkFailed(underlying: lastError)
    }

    /// Uploads multipart data (for document/liveness images).
    public func uploadMultipart(
        path: String,
        fieldName: String,
        fileName: String,
        mimeType: String,
        data: Data,
        additionalFields: [String: String] = [:]
    ) async throws -> Data {
        try circuitBreaker.preRequest()

        let boundary = "IdentityKit-\(UUID().uuidString)"
        var body = Data()

        // Additional text fields.
        for (key, value) in additionalFields {
            body.appendMultipartField(name: key, value: value, boundary: boundary)
        }

        // File field.
        body.appendMultipartFile(
            name: fieldName,
            fileName: fileName,
            mimeType: mimeType,
            data: data,
            boundary: boundary
        )

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = body

        if let signer = requestSigner {
            signer.sign(request: &urlRequest)
        }

        let (responseData, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            circuitBreaker.recordFailure()
            throw IdentityKitError.uploadFailed(reason: "Server returned non-2xx status")
        }

        circuitBreaker.recordSuccess()
        return responseData
    }

    // MARK: - Private

    private func buildURLRequest<T>(for request: APIRequest<T>) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(request.path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        // Default headers.
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("IdentityKit-iOS/1.0", forHTTPHeaderField: "User-Agent")

        // Custom headers.
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Sign if configured.
        if let signer = requestSigner {
            signer.sign(request: &urlRequest)
        }

        return urlRequest
    }

    private func log(_ level: LogLevel, _ message: String) {
        guard level >= logLevel else { return }
        logger.log(level: level, message: message, file: #file, function: #function, line: #line)
    }
}

// MARK: - Data multipart helpers

extension Data {
    mutating func appendMultipartField(name: String, value: String, boundary: String) {
        let field = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n"
        append(field.data(using: .utf8)!)
    }

    mutating func appendMultipartFile(name: String, fileName: String, mimeType: String, data: Data, boundary: String) {
        var header = "--\(boundary)\r\n"
        header += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
        header += "Content-Type: \(mimeType)\r\n\r\n"
        append(header.data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
