import XCTest
@testable import IdentityKitStorage
import IdentityKitCore

final class BackgroundUploadManagerTests: XCTestCase {

    private var tempDir: URL!
    private var queue: OutboxQueue!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        queue = OutboxQueue(baseDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testSuccessfulUploadRemovesItem() async throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload"
        )
        try queue.enqueue(item: item, data: Data("image".utf8))

        let manager = BackgroundUploadManager(
            outboxQueue: queue,
            uploadAction: { _, _ in
                // Simulate successful upload.
            }
        )

        let completedIds = CompletedCollector()
        await manager.processQueue(onCompletion: { id, result in
            if case .success = result {
                completedIds.append(id)
            }
        })

        XCTAssertEqual(completedIds.ids, [item.id])
        XCTAssertEqual(queue.count, 0)
    }

    func testFailedUploadIncrementsRetry() async throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload",
            retryCount: 0,
            maxRetries: 3
        )
        try queue.enqueue(item: item, data: Data("image".utf8))

        let manager = BackgroundUploadManager(
            outboxQueue: queue,
            uploadAction: { _, _ in
                throw URLError(.notConnectedToInternet)
            }
        )

        await manager.processQueue()

        let pending = queue.pendingItems()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.retryCount, 1)
    }

    func testExpiredItemIsRemoved() async throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload",
            retryCount: 5,
            maxRetries: 5
        )
        try queue.enqueue(item: item, data: Data("image".utf8))

        let manager = BackgroundUploadManager(
            outboxQueue: queue,
            uploadAction: { _, _ in
                XCTFail("Should not attempt upload for expired item")
            }
        )

        let failedIds = CompletedCollector()
        await manager.processQueue(onCompletion: { id, result in
            if case .failure = result {
                failedIds.append(id)
            }
        })

        XCTAssertEqual(failedIds.ids, [item.id])
        XCTAssertEqual(queue.count, 0)
    }

    func testMultipleItemsProcessedInOrder() async throws {
        let item1 = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "first.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload",
            createdAt: Date(timeIntervalSince1970: 1000)
        )
        let item2 = OutboxQueue.Item(
            sessionId: "s2",
            fileName: "second.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload",
            createdAt: Date(timeIntervalSince1970: 2000)
        )

        try queue.enqueue(item: item1, data: Data("1".utf8))
        try queue.enqueue(item: item2, data: Data("2".utf8))

        let processedOrder = CompletedCollector()
        let manager = BackgroundUploadManager(
            outboxQueue: queue,
            uploadAction: { item, _ in
                processedOrder.append(item.id)
            }
        )

        await manager.processQueue()

        XCTAssertEqual(processedOrder.ids, [item1.id, item2.id])
        XCTAssertEqual(queue.count, 0)
    }

    func testPendingCount() async throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload"
        )
        try queue.enqueue(item: item, data: Data("image".utf8))

        let manager = BackgroundUploadManager(
            outboxQueue: queue,
            uploadAction: { _, _ in }
        )

        XCTAssertEqual(manager.pendingCount, 1)
        await manager.processQueue()
        XCTAssertEqual(manager.pendingCount, 0)
    }
}

// MARK: - Thread-safe collector for test assertions

/// Collects IDs in a thread-safe way for use in `@Sendable` closures.
private final class CompletedCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var _ids: [String] = []

    var ids: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _ids
    }

    func append(_ id: String) {
        lock.lock()
        defer { lock.unlock() }
        _ids.append(id)
    }
}
