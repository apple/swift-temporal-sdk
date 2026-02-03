//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
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
import GRPCCore
internal import SwiftProtobuf

package protocol BridgeWorkerProtocol: Sendable {
    init(
        client: borrowing BridgeClient,
        configuration: TemporalWorker.Configuration,
        hasActivities: Bool,
        hasWorkflows: Bool,
    ) throws

    func initiateShutdown()
    func finalizeShutdown() async throws
    func pollWorkflowActivation() async throws -> Coresdk_WorkflowActivation_WorkflowActivation
    func completeWorkflowActivation(completion: Coresdk_WorkflowCompletion_WorkflowActivationCompletion) async throws
    func pollActivityTask() async throws -> Coresdk_ActivityTask_ActivityTask
    func completeActivityTask(_ completion: Coresdk_ActivityTaskCompletion) async throws
    func recordActivityHeartbeat(_ heartbeat: Coresdk_ActivityHeartbeat) throws
}

package final class BridgeWorker: BridgeWorkerProtocol {
    private nonisolated(unsafe) let worker: OpaquePointer

    init(
        client: borrowing BridgeClient,
        namespace: String,
        taskQueue: String,
        versioningStrategy: TemporalWorker.Configuration.VersioningStrategy,
        clientIdentity: String,
        identityOverride: String?,
        hasActivities: Bool,
        hasWorkflows: Bool,
        // –– Workflows ––
        workflowTaskPollerBehavior: TemporalWorker.Configuration.PollerBehavior,
        maxCachedWorkflows: UInt32,
        maxConcurrentWorkflowTasks: UInt,
        nonstickyToStickyPollRatio: Float,
        stickyQueueScheduleToStartTimeoutMs: UInt64,
        nondeterminismAsWorkflowFail: Bool,
        nondeterminismAsWorkflowFailForTypes: [String],
        // –– Activities ––
        activityTaskPollerBehavior: TemporalWorker.Configuration.PollerBehavior,
        maxConcurrentActivities: UInt,
        maxConcurrentLocalActivities: UInt,
        maxActivitiesPerSecond: Double,
        maxTaskQueueActivitiesPerSecond: Double,
        // –– Heartbeat throttling ––
        defaultHeartbeatThrottleIntervalMs: UInt64,
        maxHeartbeatThrottleIntervalMs: UInt64,
        // –– Misc ––
        nexusTaskPollerBehavior: TemporalWorker.Configuration.PollerBehavior,
        gracefulShutdownPeriodMs: UInt64
    ) throws {
        var tuner = TemporalCoreTunerHolder()
        tuner.workflow_slot_supplier.tag = FixedSize
        tuner.workflow_slot_supplier.fixed_size.num_slots = maxConcurrentWorkflowTasks
        tuner.activity_slot_supplier.tag = FixedSize
        tuner.activity_slot_supplier.fixed_size.num_slots = maxConcurrentActivities
        tuner.local_activity_slot_supplier.tag = FixedSize
        tuner.local_activity_slot_supplier.fixed_size.num_slots = maxConcurrentLocalActivities

        self.worker = try Self.withWorkerOptions(
            namespace: namespace,
            taskQueue: taskQueue,
            identity: identityOverride ?? "",
            hasActivities: hasActivities,
            hasWorkflows: hasWorkflows,
            versioningStrategy: versioningStrategy,
            tuner: tuner,
            maxCachedWorkflows: maxCachedWorkflows,
            stickyQueueTimeoutMs: stickyQueueScheduleToStartTimeoutMs,
            maxHeartbeatThrottleIntervalMs: maxHeartbeatThrottleIntervalMs,
            defaultHeartbeatThrottleIntervalMs: defaultHeartbeatThrottleIntervalMs,
            maxActivitiesPerSecond: maxActivitiesPerSecond,
            maxTaskQueueActivitiesPerSecond: maxTaskQueueActivitiesPerSecond,
            gracefulShutdownMs: gracefulShutdownPeriodMs,
            workflowTaskPollerBehavior: workflowTaskPollerBehavior,
            nonstickyToStickyRatio: nonstickyToStickyPollRatio,
            activityTaskPollerBehavior: activityTaskPollerBehavior,
            nexusTaskPollerBehavior: nexusTaskPollerBehavior,
            nondeterminismAsWorkflowFail: nondeterminismAsWorkflowFail,
            nondeterminismTypes: nondeterminismAsWorkflowFailForTypes
        ) { workerOptions in
            let maybeWorker = temporal_core_worker_new(
                client.client,
                workerOptions
            )

            if let fail = maybeWorker.fail {
                throw BridgeError(messagePointer: fail)
            }

            guard let worker = maybeWorker.worker else {
                throw BridgeError(message: "`temporal_core_worker_new()` from Rust Bridge returned nil, but no error")
            }

            return worker
        }
    }

    package convenience init(
        client: borrowing BridgeClient,
        configuration: TemporalWorker.Configuration,
        hasActivities: Bool,
        hasWorkflows: Bool,
    ) throws {
        try self.init(
            client: client,
            namespace: configuration.namespace,
            taskQueue: configuration.taskQueue,
            versioningStrategy: configuration.versioningStrategy,
            clientIdentity: configuration.clientIdentity,
            identityOverride: configuration.identityOverride,
            hasActivities: hasActivities,
            hasWorkflows: hasWorkflows,
            workflowTaskPollerBehavior: configuration.workflowTaskPollerBehavior,
            maxCachedWorkflows: UInt32(configuration.maxCachedWorkflows),
            maxConcurrentWorkflowTasks: UInt(configuration.maxConcurrentWorkflowTasks),
            nonstickyToStickyPollRatio: Float(configuration.nonstickyToStickyPollRatio),
            stickyQueueScheduleToStartTimeoutMs: configuration.stickyQueueScheduleToStartTimeout.milliseconds,
            nondeterminismAsWorkflowFail: true,
            nondeterminismAsWorkflowFailForTypes: [],
            activityTaskPollerBehavior: configuration.activityTaskPollerBehavior,
            maxConcurrentActivities: UInt(configuration.maxConcurrentActivities),
            maxConcurrentLocalActivities: UInt(configuration.maxConcurrentLocalActivities),
            maxActivitiesPerSecond: configuration.maxActivitiesPerSecond,
            maxTaskQueueActivitiesPerSecond: configuration.maxTaskQueueActivitiesPerSecond,
            defaultHeartbeatThrottleIntervalMs: configuration.defaultHeartbeatThrottleInterval.milliseconds,
            maxHeartbeatThrottleIntervalMs: configuration.maxHeartbeatThrottleInterval.milliseconds,
            nexusTaskPollerBehavior: configuration.nexusTaskPollerBehavior,
            gracefulShutdownPeriodMs: configuration.gracefulShutdownPeriod.milliseconds
        )
    }

    deinit {
        temporal_core_worker_free(self.worker)
    }

    package func initiateShutdown() {
        temporal_core_worker_initiate_shutdown(self.worker)
    }

    package func finalizeShutdown() async throws {
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

    package func pollWorkflowActivation() async throws -> Coresdk_WorkflowActivation_WorkflowActivation {
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

        return try Coresdk_WorkflowActivation_WorkflowActivation(serializedBytes: result)
    }

    package func pollActivityTask() async throws -> Coresdk_ActivityTask_ActivityTask {
        let result: Data = try await withCheckedThrowingContinuation { continuation in
            let holder = ContinuationHolder(continuation)
            let holderPtr = Unmanaged.passRetained(holder).toOpaque()

            temporal_core_worker_poll_activity_task(self.worker, holderPtr) { user_data, success, fail in
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
                                    "Unexpected result from worker_poll_activity_task, both success and fail are set"
                            )
                    )
                }
            }
        }

        return try Coresdk_ActivityTask_ActivityTask(serializedBytes: result)
    }

    package func completeActivityTask(_ completion: Coresdk_ActivityTaskCompletion) async throws {
        let completionBytes = try completion.serializedData()

        try await withCheckedThrowingContinuation { continuation in
            let holder = ContinuationHolder<Void>(continuation)
            let holderPtr = Unmanaged.passRetained(holder).toOpaque()

            completionBytes.withByteArrayRef { completionBytesRef in
                temporal_core_worker_complete_activity_task(self.worker, completionBytesRef, holderPtr) { user_data, fail in
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

    package func completeWorkflowActivation(completion: Coresdk_WorkflowCompletion_WorkflowActivationCompletion) async throws {
        let completionBytes = try completion.serializedData()
        try await withCheckedThrowingContinuation { continuation in
            let holder = ContinuationHolder<Void>(continuation)
            let holderPtr = Unmanaged.passRetained(holder).toOpaque()

            completionBytes.withByteArrayRef { completionBytesRef in
                temporal_core_worker_complete_workflow_activation(self.worker, completionBytesRef, holderPtr) { user_data, fail in
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

    package func recordActivityHeartbeat(_ heartbeat: Coresdk_ActivityHeartbeat) throws {
        let heartbeatBytes = try heartbeat.serializedData()

        let fail = heartbeatBytes.withByteArrayRef { heartbeatBytesRef in
            temporal_core_worker_record_activity_heartbeat(self.worker, heartbeatBytesRef)
        }

        if let fail {
            throw BridgeError(messagePointer: fail)
        }
    }
}
