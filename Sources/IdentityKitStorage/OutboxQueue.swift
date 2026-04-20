import Foundation
import IdentityKitCore

/// Persistent queue for pending uploads that survives app restarts.
///
/// When a network upload fails, the item is enqueued here. The queue
/// persists items to disk via `FileManager` and retries them when
/// the app returns to the foreground or on a background task.
///
/// Each item is stored as a separate file in the outbox directory,
/// named by its unique ID, making concurrent access safe and
/// individual item deletion straightforward.
public final class OutboxQueue: @unchecked Sendable {

    /// Represents a pending upload item.
    public struct Item: Codable, Sendable, Identifiable {
        public let id: String
        public let sessionId: String
        public let fileName: String
        public let mimeType: String
        public let endpoint: String
        public let createdAt: Date
        public let retryCount: Int
        public let maxRetries: Int

        public init(
            id: String = UUID().uuidString,
            sessionId: String,
            fileName: String,
            mimeType: String,
            endpoint: String,
            createdAt: Date = Date(),
            retryCount: Int = 0,
            maxRetries: Int = 5
        ) {
            self.id = id
            self.sessionId = sessionId
            self.fileName = fileName
            self.mimeType = mimeType
            self.endpoint = endpoint
            self.createdAt = createdAt
            self.retryCount = retryCount
            self.maxRetries = maxRetries
        }

        /// Returns a copy with an incremented retry count.
        public func incrementingRetry() -> Item {
            Item(
                id: id,
                sessionId: sessionId,
                fileName: fileName,
                mimeType: mimeType,
                endpoint: endpoint,
                createdAt: createdAt,
                retryCount: retryCount + 1,
                maxRetries: maxRetries
            )
        }

        /// Whether this item has exhausted all retry attempts.
        public var isExpired: Bool {
            retryCount >= maxRetries
        }
    }

    private let outboxDirectory: URL
    private let dataDirectory: URL
    private let fileManager: FileManager
    private let lock = NSLock()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        baseDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        let base = baseDirectory ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.outboxDirectory = base.appendingPathComponent("com.identitykit.outbox", isDirectory: true)
        self.dataDirectory = base.appendingPathComponent("com.identitykit.outbox.data", isDirectory: true)

        // Create directories if needed.
        try? fileManager.createDirectory(at: outboxDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Enqueue / Dequeue

    /// Enqueues an item with its associated binary data.
    public func enqueue(item: Item, data: Data) throws {
        lock.lock()
        defer { lock.unlock() }

        // Write the metadata.
        let metadataURL = outboxDirectory.appendingPathComponent("\(item.id).json")
        let metadataData = try encoder.encode(item)
        try metadataData.write(to: metadataURL, options: .atomic)

        // Write the binary payload.
        let dataURL = dataDirectory.appendingPathComponent(item.id)
        try data.write(to: dataURL, options: .atomic)
    }

    /// Returns all pending items, ordered by creation date (oldest first).
    public func pendingItems() -> [Item] {
        lock.lock()
        defer { lock.unlock() }

        guard let files = try? fileManager.contentsOfDirectory(
            at: outboxDirectory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        let items: [Item] = files.compactMap { url in
            guard url.pathExtension == "json",
                  let data = try? Data(contentsOf: url),
                  let item = try? decoder.decode(Item.self, from: data) else {
                return nil
            }
            return item
        }

        return items.sorted { $0.createdAt < $1.createdAt }
    }

    /// Reads the binary data for a queued item.
    public func data(for item: Item) -> Data? {
        let dataURL = dataDirectory.appendingPathComponent(item.id)
        return try? Data(contentsOf: dataURL)
    }

    /// Removes a completed or expired item from the queue.
    public func remove(item: Item) {
        lock.lock()
        defer { lock.unlock() }

        let metadataURL = outboxDirectory.appendingPathComponent("\(item.id).json")
        let dataURL = dataDirectory.appendingPathComponent(item.id)

        try? fileManager.removeItem(at: metadataURL)
        try? fileManager.removeItem(at: dataURL)
    }

    /// Updates an item's metadata (e.g., after incrementing retry count).
    public func update(item: Item) throws {
        lock.lock()
        defer { lock.unlock() }

        let metadataURL = outboxDirectory.appendingPathComponent("\(item.id).json")
        let data = try encoder.encode(item)
        try data.write(to: metadataURL, options: .atomic)
    }

    /// Returns the number of pending items.
    public var count: Int {
        pendingItems().count
    }

    /// Removes all items from the queue.
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }

        try? fileManager.removeItem(at: outboxDirectory)
        try? fileManager.removeItem(at: dataDirectory)
        try? fileManager.createDirectory(at: outboxDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }
}
