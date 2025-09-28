//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import GRPCCore
import Synchronization

/// A queue for scheduling and executing asynchronous jobs, mostly RPC calls of the Temporal Core SDKs `WorkerClient`.
///
/// `WorkerClientQueue` accepts tasks—async closures producing `Element`s—
/// via `submit(work:completion:)`, and processes them concurrently once `runQueue()` is called.
/// Call `shutdown()` to finish the underlying stream, cancel in-flight work, and prevent further submissions.
package final class WorkerClientQueue<Element: Sendable>: Sendable {
    typealias Input = @Sendable () async throws -> ClientResponse<Element>
    typealias Output = @Sendable (Result<ClientResponse<Element>, Error>) -> Void
    typealias WorkerClientTask = (Input, Output)

    /// Errors that can occur during task queue operation.
    enum QueueError: Error, Sendable {
        /// The queue has not been started
        case notStarted

        /// The queue submission failed
        case submissionFailed

        /// The queue was cancelled
        case cancelled

        /// The queue is already running
        case alreadyRunning

        /// The queue was already shut down
        case alreadyShutdown
    }

    /// Represents the current state of the task queue.
    private enum State: Sendable {
        /// Idle state of the queue, including a buffer of tasks to be processed once the queue is started.
        case idle(buffer: [WorkerClientTask])
        /// Processing state of the queue, holding an `AsyncStream` to receive tasks and the matching `Continuation` yielding the tasks into.
        case processing(
            taskStream: AsyncStream<WorkerClientTask>,
            continuation: AsyncStream<WorkerClientTask>.Continuation
        )
        /// Shutdown state of the queue.
        case shutdown
    }

    /// The current state of the task queue.
    private let state: Mutex<State> = .init(.idle(buffer: []))

    /// Start the task queue.
    ///
    /// This returns once `shutdown()` has been called and all in-flight tasks have finished or cancelled.
    /// If you need to abruptly stop all work you should cancel the `Task` executing this method.
    ///
    /// The task queue, and by extension this function, can only be run once. If the task queue is already
    /// running or has already been closed then a `WorkerClientTaskQueue/QueueError` is thrown.
    func runQueue() async throws {
        let (stream, pending) = try self.state.withLock { state in
            switch state {
            case .processing:
                throw QueueError.alreadyRunning
            case .shutdown:
                throw QueueError.alreadyShutdown
            case .idle(let buffer):
                // TODO: Investigate backpressure needs
                let (stream, continuation) = AsyncStream<WorkerClientTask>.makeStream(bufferingPolicy: .unbounded)

                state = .processing(
                    taskStream: stream,
                    continuation: continuation
                )

                return (stream, buffer)  // return buffered tasks from submissions during idle queue state
            }
        }

        // Enqueue previously buffered tasks now that continuation exists
        for (work, completion) in pending {
            try submit(work: work, completion)
        }

        try await withThrowingDiscardingTaskGroup { group in
            // Start processing `WorkerClientTask`s as they come in
            for await (job, callback) in stream {
                group.addTask {
                    do {
                        let result = try await job()
                        callback(.success(result))
                    } catch {
                        callback(.failure(error))
                    }
                }
            }

            // Cancel all tasks currently in process when stream/continuation finishes
            group.cancelAll()
        }
    }

    /// Enqueues a unit of work for the worker client queue.
    ///
    /// - Parameters:
    ///   - work: An async-producing closure that returns the data to hand to the completion closure.
    ///   - completion: A callback invoked with the result or error once processing finishes.
    /// - Throws:
    ///   - `QueueError.notStarted` if the queue has not been started.
    ///   - `QueueError.submissionFailed` if the queue is full or has been terminated.
    ///
    /// After enqueuing, the worker queue will pick up this work and invoke
    /// `completion` with either a successful `Element` or an `Error`.
    func submit(
        work: @escaping Input,
        _ completion: @escaping Output
    ) throws {
        // Package the work into a worker client task tuple
        let task: WorkerClientTask = (work, completion)

        // Either append to buffer in idle state or obtain continuation in processing state
        let continuation: AsyncStream<WorkerClientTask>.Continuation? = try self.state.withLock { state in
            switch state {
            case .processing(_, let continuation):
                return continuation
            case .idle(var buffer):  // Buffer submitted tasks if queue is not yet processing
                buffer.append(task)
                state = .idle(buffer: buffer)
                return nil
            case .shutdown:
                throw QueueError.alreadyShutdown
            }
        }

        // If processing has begun, yield immediately
        if let continuation {
            switch continuation.yield(task) {
            case .enqueued:
                break
            case .dropped, .terminated:
                throw QueueError.submissionFailed
            @unknown default:
                fatalError("Unknown yield return case from the continuation of the Worker Client Task Queue.")
            }
        }
    }

    /// Stops the task queue and prevents any further submissions.
    ///
    /// Calling this method finishes the underlying async stream, which in turn
    /// cancels any in-flight `Task`s. After shutdown, the queue transitions to the
    /// `.shutdown` state and any subsequent `submit(...)` calls will throw.
    ///
    /// - Note: Calling `shutdown()` when the queue has already been shut down results in a
    /// runtime error. If the queue is not yet running then all pending jobs will be cancelled.
    func shutdown() {
        self.state.withLock { state in
            switch state {
            case .processing(_, let continuation):
                continuation.finish()  // also cancels the task group
            case .idle(let buffer):
                for (_, callback) in buffer {
                    callback(.failure(QueueError.alreadyShutdown))
                }
            case .shutdown:
                fatalError("The Worker Client Task Queue has already been shut down.")
            }

            state = .shutdown
        }
    }
}
