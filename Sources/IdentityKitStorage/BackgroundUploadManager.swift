import Foundation
import IdentityKitCore

/// Processes the outbox queue, uploading pending items with retry logic.
///
/// Can be triggered from the foreground (when the app resumes) or from
/// a `BGProcessingTask` to drain the queue while the app is backgrounded.
/// Uses the `OutboxQueue` for persistence and reports progress via a callback.
public final class BackgroundUploadManager: @unchecked Sendable {

    /// Callback for upload progress of a single item.
    public typealias ProgressHandler = @Sendable (String, Double) -> Void

    /// Callback invoked when an upload completes (success or permanent failure).
    public typealias CompletionHandler = @Sendable (String, Result<Void, IdentityKitError>) -> Void

    private let outboxQueue: OutboxQueue
    private let uploadAction: @Sendable (OutboxQueue.Item, Data) async throws -> Void
    private let logger: IdentityKitLogger
    private let logLevel: LogLevel
    private let processingState = ProcessingState()

    public init(
        outboxQueue: OutboxQueue,
        uploadAction: @escaping @Sendable (OutboxQueue.Item, Data) async throws -> Void,
        logger: IdentityKitLogger = DefaultLogger(),
        logLevel: LogLevel = .warning
    ) {
        self.outboxQueue = outboxQueue
        self.uploadAction = uploadAction
        self.logger = logger
        self.logLevel = logLevel
    }

    /// Processes all pending items in the outbox queue.
    ///
    /// Items that succeed are removed. Items that fail are retried up to
    /// their `maxRetries` limit, then removed as expired.
    ///
    /// - Parameters:
    ///   - onProgress: Called with (itemId, progress) for each item.
    ///   - onCompletion: Called with (itemId, result) when each item finishes.
    public func processQueue(
        onProgress: ProgressHandler? = nil,
        onCompletion: CompletionHandler? = nil
    ) async {
        guard await processingState.tryStart() else { return }
        defer { Task { await processingState.stop() } }

        let items = outboxQueue.pendingItems()

        log(.info, "Processing outbox queue: \(items.count) items pending")

        for item in items {
            if item.isExpired {
                log(.warning, "Item \(item.id) expired after \(item.retryCount) retries — removing")
                outboxQueue.remove(item: item)
                onCompletion?(item.id, .failure(.uploadFailed(reason: "Max retries exceeded")))
                continue
            }

            guard let data = outboxQueue.data(for: item) else {
                log(.warning, "No data found for item \(item.id) — removing")
                outboxQueue.remove(item: item)
                onCompletion?(item.id, .failure(.uploadFailed(reason: "Payload data missing")))
                continue
            }

            onProgress?(item.id, 0.0)

            do {
                try await uploadAction(item, data)
                outboxQueue.remove(item: item)
                onProgress?(item.id, 1.0)
                onCompletion?(item.id, .success(()))
                log(.info, "Item \(item.id) uploaded successfully")
            } catch {
                let updated = item.incrementingRetry()
                try? outboxQueue.update(item: updated)
                log(.warning, "Item \(item.id) failed (attempt \(updated.retryCount)/\(updated.maxRetries)): \(error.localizedDescription)")
                onCompletion?(item.id, .failure(.uploadFailed(reason: error.localizedDescription)))
            }
        }
    }

    /// Returns the number of pending items in the queue.
    public var pendingCount: Int {
        outboxQueue.count
    }

    // MARK: - Private

    private func log(_ level: LogLevel, _ message: String) {
        guard level >= logLevel else { return }
        logger.log(level: level, message: message, file: #file, function: #function, line: #line)
    }
}

// MARK: - ProcessingState

/// Actor that guards against concurrent queue processing.
private actor ProcessingState {
    private var isProcessing = false

    func tryStart() -> Bool {
        guard !isProcessing else { return false }
        isProcessing = true
        return true
    }

    func stop() {
        isProcessing = false
    }
}
