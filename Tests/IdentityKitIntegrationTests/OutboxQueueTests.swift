import XCTest
@testable import IdentityKitStorage

final class OutboxQueueTests: XCTestCase {

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

    func testEnqueueAndRetrieve() throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload"
        )
        let data = Data("image-bytes".utf8)

        try queue.enqueue(item: item, data: data)

        let pending = queue.pendingItems()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.sessionId, "s1")
        XCTAssertEqual(pending.first?.fileName, "doc.jpg")
    }

    func testDataCanBeRetrieved() throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload"
        )
        let payload = Data("payload".utf8)

        try queue.enqueue(item: item, data: payload)

        let retrieved = queue.data(for: item)
        XCTAssertEqual(retrieved, payload)
    }

    func testRemoveItem() throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload"
        )
        try queue.enqueue(item: item, data: Data("data".utf8))

        queue.remove(item: item)

        XCTAssertEqual(queue.pendingItems().count, 0)
        XCTAssertNil(queue.data(for: item))
    }

    func testPendingItemsOrderedByCreationDate() throws {
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

        // Enqueue out of order.
        try queue.enqueue(item: item2, data: Data("2".utf8))
        try queue.enqueue(item: item1, data: Data("1".utf8))

        let pending = queue.pendingItems()
        XCTAssertEqual(pending.count, 2)
        XCTAssertEqual(pending[0].fileName, "first.jpg")
        XCTAssertEqual(pending[1].fileName, "second.jpg")
    }

    func testUpdateItem() throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload",
            retryCount: 0,
            maxRetries: 5
        )
        try queue.enqueue(item: item, data: Data("data".utf8))

        let updated = item.incrementingRetry()
        try queue.update(item: updated)

        let pending = queue.pendingItems()
        XCTAssertEqual(pending.first?.retryCount, 1)
    }

    func testIncrementingRetry() {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload",
            retryCount: 2,
            maxRetries: 5
        )

        let incremented = item.incrementingRetry()
        XCTAssertEqual(incremented.retryCount, 3)
        XCTAssertEqual(incremented.id, item.id)
        XCTAssertEqual(incremented.sessionId, item.sessionId)
    }

    func testIsExpired() {
        let fresh = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload",
            retryCount: 2,
            maxRetries: 5
        )
        XCTAssertFalse(fresh.isExpired)

        let expired = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload",
            retryCount: 5,
            maxRetries: 5
        )
        XCTAssertTrue(expired.isExpired)
    }

    func testCount() throws {
        XCTAssertEqual(queue.count, 0)

        try queue.enqueue(
            item: OutboxQueue.Item(sessionId: "s1", fileName: "a.jpg", mimeType: "image/jpeg", endpoint: "/upload"),
            data: Data("a".utf8)
        )
        try queue.enqueue(
            item: OutboxQueue.Item(sessionId: "s2", fileName: "b.jpg", mimeType: "image/jpeg", endpoint: "/upload"),
            data: Data("b".utf8)
        )

        XCTAssertEqual(queue.count, 2)
    }

    func testRemoveAll() throws {
        try queue.enqueue(
            item: OutboxQueue.Item(sessionId: "s1", fileName: "a.jpg", mimeType: "image/jpeg", endpoint: "/upload"),
            data: Data("a".utf8)
        )
        try queue.enqueue(
            item: OutboxQueue.Item(sessionId: "s2", fileName: "b.jpg", mimeType: "image/jpeg", endpoint: "/upload"),
            data: Data("b".utf8)
        )

        queue.removeAll()
        XCTAssertEqual(queue.count, 0)
    }

    func testQueueSurvivesReinit() throws {
        let item = OutboxQueue.Item(
            sessionId: "s1",
            fileName: "doc.jpg",
            mimeType: "image/jpeg",
            endpoint: "/upload"
        )
        try queue.enqueue(item: item, data: Data("data".utf8))

        // Simulate app restart by creating a new queue with same directory.
        let queue2 = OutboxQueue(baseDirectory: tempDir)
        let pending = queue2.pendingItems()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.id, item.id)
    }
}
