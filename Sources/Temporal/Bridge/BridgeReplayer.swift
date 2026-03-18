//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Bridge
import Foundation
internal import SwiftProtobuf

package final class BridgeReplayer: Sendable {
    /// The underlying worker pointer from the Core SDK.
    private nonisolated(unsafe) let worker: OpaquePointer

    /// The pusher pointer for pushing histories to the replayer.
    private nonisolated(unsafe) let pusher: OpaquePointer

    /// The runtime associated with this replayer.
    private let runtime: BridgeRuntime

    /// Creates a new bridge replayer.
    ///
    /// - Parameters:
    ///   - runtime: The bridge runtime to use.
    ///   - namespace: The namespace for replay context.
    ///   - taskQueue: The task queue for replay context.
    /// - Throws: An error if the replayer cannot be created.
    init(
        runtime: BridgeRuntime,
        namespace: String,
        taskQueue: String
    ) throws {
        self.runtime = runtime

        var tuner = TemporalCoreTunerHolder()
        tuner.workflow_slot_supplier.tag = FixedSize
        tuner.workflow_slot_supplier.fixed_size.num_slots = 1
        tuner.activity_slot_supplier.tag = FixedSize
        tuner.activity_slot_supplier.fixed_size.num_slots = 0
        tuner.local_activity_slot_supplier.tag = FixedSize
        tuner.local_activity_slot_supplier.fixed_size.num_slots = 0
        tuner.nexus_task_slot_supplier.tag = FixedSize
        tuner.nexus_task_slot_supplier.fixed_size.num_slots = 0

        let result = Self.withReplayerOptions(
            namespace: namespace,
            taskQueue: taskQueue,
            tuner: tuner
        ) { options in
            temporal_core_worker_replayer_new(runtime.runtime, options)
        }

        if let fail = result.fail {
            throw BridgeError(messagePointer: fail)
        }

        guard let worker = result.worker else {
            throw BridgeError(message: "`temporal_core_worker_replayer_new()` returned nil worker")
        }

        guard let pusher = result.worker_replay_pusher else {
            throw BridgeError(message: "`temporal_core_worker_replayer_new()` returned nil pusher")
        }

        self.worker = worker
        self.pusher = pusher
    }

    deinit {
        temporal_core_worker_replay_pusher_free(self.pusher)
        temporal_core_worker_free(self.worker)
    }

    /// Pushes a workflow history for replay.
    func pushHistory(workflowID: String, history: Data) throws {
        let result = workflowID.withByteArrayRef { workflowIDRef in
            history.withByteArrayRef { historyRef in
                temporal_core_worker_replay_push(
                    self.worker,
                    self.pusher,
                    workflowIDRef,
                    historyRef
                )
            }
        }

        if let fail = result.fail {
            throw BridgeError(messagePointer: fail)
        }
    }

    // MARK: - BridgeWorkerProtocol Methods

    /// Initiates shutdown of the replayer worker.
    func initiateShutdown() {
        temporal_core_worker_initiate_shutdown(self.worker)
    }

    /// Finalizes shutdown of the replayer worker.
    func finalizeShutdown() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            let continuationHolder = ContinuationHolder(continuation)
            let continuationHolderPointer = Unmanaged.passRetained(continuationHolder).toOpaque()
            temporal_core_worker_finalize_shutdown(self.worker, continuationHolderPointer) { userData, failure in
                let continuationHolder = Unmanaged<ContinuationHolder<Void>>.fromOpaque(userData!).takeRetainedValue()
                if let failure {
                    continuationHolder.continuation.resume(throwing: BridgeError(messagePointer: failure))
                } else {
                    continuationHolder.continuation.resume()
                }
            }
        }
    }

    /// Polls for the next workflow activation.
    func pollWorkflowActivation() async throws -> Coresdk.WorkflowActivation.WorkflowActivation {
        let result: Data = try await withCheckedThrowingContinuation { continuation in
            let holder = ContinuationHolder(continuation)
            let holderPtr = Unmanaged.passRetained(holder).toOpaque()

            temporal_core_worker_poll_workflow_activation(self.worker, holderPtr) { user_data, success, fail in
                let holder = Unmanaged<ContinuationHolder<Data>>.fromOpaque(user_data!).takeRetainedValue()

                switch (success, fail) {
                // Success
                case (.some(let success), nil):
                    holder.continuation.resume(returning: Data(byteArrayPointer: success))

                // Failure
                case (nil, .some(let fail)):
                    holder.continuation.resume(throwing: BridgeError(messagePointer: fail))

                // Cancelled
                case (nil, nil):
                    holder.continuation.resume(throwing: CancellationError())

                default:
                    holder.continuation.resume(
                        throwing:
                            BridgeError(
                                message:
                                    "Unexpected result from worker_poll_workflow_activation, both success and fail are set"
                            )
                    )
                }
            }
        }

        return try Coresdk.WorkflowActivation.WorkflowActivation(serializedBytes: result)
    }

    /// Completes a workflow activation.
    func completeWorkflowActivation(
        completion: Coresdk.WorkflowCompletion.WorkflowActivationCompletion
    ) async throws {
        let completionBytes = try completion.serializedData()
        try await withCheckedThrowingContinuation { continuation in
            let holder = ContinuationHolder<Void>(continuation)
            let holderPtr = Unmanaged.passRetained(holder).toOpaque()

            completionBytes.withByteArrayRef { completionBytesRef in
                temporal_core_worker_complete_workflow_activation(
                    self.worker,
                    completionBytesRef,
                    holderPtr
                ) { user_data, fail in
                    let holder = Unmanaged<ContinuationHolder<Void>>.fromOpaque(user_data!).takeRetainedValue()

                    if let fail {
                        holder.continuation.resume(throwing: BridgeError(messagePointer: fail))
                    } else {
                        holder.continuation.resume()
                    }
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Creates worker options for the replayer.
    private static func withReplayerOptions<T>(
        namespace: String,
        taskQueue: String,
        tuner: TemporalCoreTunerHolder,
        _ body: (UnsafePointer<TemporalCoreWorkerOptions>) throws -> T
    ) rethrows -> T {
        try namespace.withByteArrayRef { namespaceRef in
            try taskQueue.withByteArrayRef { taskQueueRef in
                // Create a minimal versioning strategy (none)
                try "".withByteArrayRef { emptyRef in
                    var versioningStrategy = TemporalCoreWorkerVersioningStrategy()
                    versioningStrategy.tag = None
                    versioningStrategy.none = TemporalCoreWorkerVersioningNone(build_id: emptyRef)

                    // Create simple maximum poller behavior
                    // Must be created inside withUnsafePointer to keep it alive
                    let simpleMaximum = TemporalCorePollerBehaviorSimpleMaximum(simple_maximum: 2)
                    return try withUnsafePointer(to: simpleMaximum) { simpleMaxPtr in
                        let pollerBehavior = TemporalCorePollerBehavior(
                            simple_maximum: simpleMaxPtr,
                            autoscaling: nil
                        )

                        var opts = TemporalCoreWorkerOptions(
                            namespace_: namespaceRef,
                            task_queue: taskQueueRef,
                            versioning_strategy: versioningStrategy,
                            identity_override: emptyRef,
                            max_cached_workflows: 1,
                            tuner: tuner,
                            task_types: TemporalCoreWorkerTaskTypes(
                                enable_workflows: true,
                                enable_local_activities: false,
                                enable_remote_activities: false,
                                enable_nexus: false
                            ),
                            sticky_queue_schedule_to_start_timeout_millis: 10_000,
                            max_heartbeat_throttle_interval_millis: 60_000,
                            default_heartbeat_throttle_interval_millis: 30_000,
                            max_activities_per_second: 0,
                            max_task_queue_activities_per_second: 0,
                            graceful_shutdown_period_millis: 0,
                            workflow_task_poller_behavior: pollerBehavior,
                            nonsticky_to_sticky_poll_ratio: 0.2,
                            activity_task_poller_behavior: pollerBehavior,
                            nexus_task_poller_behavior: pollerBehavior,
                            nondeterminism_as_workflow_fail: true,
                            nondeterminism_as_workflow_fail_for_types: .init(),
                            plugins: .init(),
                            storage_drivers: .init()
                        )

                        return try body(&opts)
                    }
                }
            }
        }
    }
}
