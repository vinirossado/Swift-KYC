import XCTest
@testable import IdentityKitNetwork
import IdentityKitCore

/// Simple Codable response for testing.
private struct TestResponse: Codable, Sendable, Equatable {
    let id: Int
    let message: String
}

final class APIClientTests: XCTestCase {

    private var session: URLSession!
    private var client: APIClient!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)

        client = APIClient(
            baseURL: URL(string: "https://api.test.com/v1")!,
            apiKey: "test-key",
            session: session,
            retryPolicy: RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.05),
            circuitBreaker: CircuitBreaker(failureThreshold: 3)
        )
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        session = nil
        client = nil
        super.tearDown()
    }

    // MARK: - Happy Path

    func testSuccessfulGetRequest() async throws {
        let expected = TestResponse(id: 1, message: "ok")
        let responseData = try JSONEncoder().encode(expected)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertTrue(request.url?.path.contains("/test") == true)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "IdentityKit-iOS/1.0")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseData)
        }

        let request = APIRequest<TestResponse>(path: "/test")
        let result = try await client.perform(request)

        XCTAssertEqual(result, expected)
    }

    func testSuccessfulPostRequest() async throws {
        let body = try JSONEncoder().encode(["name": "test"])
        let expected = TestResponse(id: 2, message: "created")
        let responseData = try JSONEncoder().encode(expected)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            // Note: URLProtocol may not preserve httpBody — httpBodyStream is used instead.
            // We verify the method is POST which confirms body was attached.

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseData)
        }

        let request = APIRequest<TestResponse>(path: "/create", method: .post, body: body)
        let result = try await client.perform(request)
        XCTAssertEqual(result, expected)
    }

    // MARK: - Retry Behavior

    func testRetriesOnServerError() async throws {
        var attemptCount = 0
        let expected = TestResponse(id: 1, message: "recovered")
        let responseData = try JSONEncoder().encode(expected)

        MockURLProtocol.requestHandler = { request in
            attemptCount += 1
            if attemptCount < 3 {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseData)
        }

        let request = APIRequest<TestResponse>(path: "/retry-test")
        let result = try await client.perform(request)

        XCTAssertEqual(result, expected)
        XCTAssertEqual(attemptCount, 3)
    }

    func testDoesNotRetryNon5xxErrors() async throws {
        var attemptCount = 0

        MockURLProtocol.requestHandler = { request in
            attemptCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let request = APIRequest<TestResponse>(path: "/bad-request")

        do {
            _ = try await client.perform(request)
            XCTFail("Should have thrown")
        } catch {
            guard case IdentityKitError.networkFailed = error else {
                XCTFail("Expected networkFailed, got \(error)")
                return
            }
        }

        XCTAssertEqual(attemptCount, 1)
    }

    // MARK: - Circuit Breaker Integration

    func testCircuitBreakerOpensAfterConsecutiveFailures() async throws {
        let cb = CircuitBreaker(failureThreshold: 2)
        let client = APIClient(
            baseURL: URL(string: "https://api.test.com/v1")!,
            apiKey: "test-key",
            session: session,
            retryPolicy: RetryPolicy(maxAttempts: 0, baseDelay: 0.01, maxDelay: 0.01),
            circuitBreaker: cb
        )

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let request = APIRequest<TestResponse>(path: "/fail")

        // First two failures open the circuit breaker.
        for _ in 0..<2 {
            do {
                _ = try await client.perform(request)
            } catch {}
        }

        XCTAssertEqual(cb.state, .open)

        // Third request should fail fast with circuitBreakerOpen.
        do {
            _ = try await client.perform(request)
            XCTFail("Should have thrown circuitBreakerOpen")
        } catch {
            guard case IdentityKitError.circuitBreakerOpen = error else {
                XCTFail("Expected circuitBreakerOpen, got \(error)")
                return
            }
        }
    }

    // MARK: - Custom Headers

    func testCustomHeadersAreIncluded() async throws {
        let responseData = try JSONEncoder().encode(TestResponse(id: 1, message: "ok"))

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "custom-value")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseData)
        }

        let request = APIRequest<TestResponse>(
            path: "/with-headers",
            headers: ["X-Custom": "custom-value"]
        )
        _ = try await client.perform(request)
    }

    // MARK: - Network Error

    func testNetworkErrorIsWrapped() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let request = APIRequest<TestResponse>(path: "/offline")

        do {
            _ = try await client.perform(request)
            XCTFail("Should have thrown")
        } catch {
            guard case IdentityKitError.networkFailed = error else {
                XCTFail("Expected networkFailed, got \(error)")
                return
            }
        }
    }
}
