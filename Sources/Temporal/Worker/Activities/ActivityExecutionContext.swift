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

public import Logging
import SwiftProtobuf

public import struct Foundation.Data
public import struct Foundation.Date

/// Execution context information and utilities available during activity execution.
///
/// The activity execution context provides access to activity metadata, heartbeat functionality, and
/// cancellation information. Activities can access the current context using the static ``current`` property
/// and use it to send heartbeats and check cancellation status.
///
/// ## Accessing the Context
///
/// ```swift
/// struct MyActivity {
///     @Activity
///     func run(input: String) async throws -> String {
///         let context = ActivityExecutionContext.current!
///
///         // Send heartbeat during long-running work
///         context.heartbeat(details: "Processing step 1")
///
///         // Check for cancellation
///         if let reason = context.cancellationReason {
///             throw ActivityError.cancelled(reason)
///         }
///
///         return "Completed"
///     }
/// }
/// ```
public struct ActivityExecutionContext: Sendable {
    /// A task-local storage container providing access to the current activity execution context.
    @TaskLocal
    static var taskLocal: ActivityExecutionContext?

    /// Metadata and configuration information about the currently executing activity.
    ///
    /// This structure contains details about the activity execution including timing information, identifiers,
    /// timeout configurations, and workflow context.
    public struct Info: Sendable {
        /// The unique identifier for this activity instance.
        public let activityID: String

        /// The activity type name as registered with the worker.
        public let activityType: String

        /// The current attempt number (starting from 1).
        public let attempt: Int

        /// The timestamp when the current attempt was scheduled.
        public let currentAttemptScheduled: Date

        /// The heartbeat timeout configured for this activity.
        ///
        /// If `nil`, no heartbeat timeout is configured.
        public let heartbeatTimeout: Duration?

        /// A Boolean value that indicates whether this activity runs locally within the workflow process.
        ///
        /// When `true`, the activity executes in the same process as the workflow with different timeout
        /// and retry semantics. When `false`, it might execute on a separate worker.
        public let isLocal: Bool

        /// The schedule-to-close timeout configured for this activity.
        ///
        /// If `nil`, no schedule-to-close timeout is configured.
        public let scheduleToCloseTimeout: Duration?

        /// The timestamp when the activity was first scheduled.
        public let scheduledTime: Date

        /// The start-to-close timeout configured for this activity.
        ///
        /// If `nil`, no start-to-close timeout is configured.
        public let startToCloseTimeout: Duration?

        /// The timestamp when the activity execution started.
        public let startedTime: Date

        /// The name of the task queue this activity is executing on.
        public let taskQueue: String

        /// The unique task token identifying this activity execution.
        public let taskToken: ActivityTaskToken

        /// The workflow ID that scheduled this activity.
        public let workflowID: String

        /// The namespace where the workflow and activity are executing.
        public let workflowNamespace: String

        /// The workflow run ID that scheduled this activity.
        public let workflowRunID: String

        /// The workflow type name that scheduled this activity.
        public let workflowType: String

        /// The heartbeat details from the previous activity attempt.
        ///
        /// These details are preserved across activity retries and can be used
        /// to resume activity execution from a known state.
        private let heartbeatDetails: [TemporalPayload]

        /// The data converter used for payload serialization.
        private let dataConverter: DataConverter

        /// Creates a new activity information instance.
        ///
        /// - Parameters:
        ///   - activityID: The unique identifier for this activity instance.
        ///   - activityType: The activity type name.
        ///   - attempt: The current attempt number.
        ///   - currentAttemptScheduled: When the current attempt was scheduled.
        ///   - heartbeatTimeout: The heartbeat timeout configuration.
        ///   - isLocal: Whether this is a local activity.
        ///   - scheduleToCloseTimeout: The schedule-to-close timeout configuration.
        ///   - scheduledTime: When the activity was first scheduled.
        ///   - startToCloseTimeout: The start-to-close timeout configuration.
        ///   - startedTime: When the activity execution started.
        ///   - taskQueue: The task queue name.
        ///   - taskToken: The unique task token.
        ///   - workflowID: The workflow ID that scheduled this activity.
        ///   - workflowNamespace: The namespace for execution.
        ///   - workflowRunID: The workflow run ID.
        ///   - workflowType: The workflow type name.
        ///   - heartbeatDetails: Previous heartbeat details.
        ///   - dataConverter: Data converter for serialization.
        init(
            activityID: String,
            activityType: String,
            attempt: Int,
            currentAttemptScheduled: Date,
            heartbeatTimeout: Duration?,
            isLocal: Bool,
            scheduleToCloseTimeout: Duration?,
            scheduledTime: Date,
            startToCloseTimeout: Duration?,
            startedTime: Date,
            taskQueue: String,
            taskToken: ActivityTaskToken,
            workflowID: String,
            workflowNamespace: String,
            workflowRunID: String,
            workflowType: String,
            heartbeatDetails: [TemporalPayload],
            dataConverter: DataConverter
        ) {
            self.activityID = activityID
            self.activityType = activityType
            self.attempt = attempt
            self.currentAttemptScheduled = currentAttemptScheduled
            self.heartbeatTimeout = heartbeatTimeout
            self.isLocal = isLocal
            self.scheduleToCloseTimeout = scheduleToCloseTimeout
            self.scheduledTime = scheduledTime
            self.startToCloseTimeout = startToCloseTimeout
            self.startedTime = startedTime
            self.taskQueue = taskQueue
            self.taskToken = taskToken
            self.workflowID = workflowID
            self.workflowNamespace = workflowNamespace
            self.workflowRunID = workflowRunID
            self.workflowType = workflowType
            self.heartbeatDetails = heartbeatDetails
            self.dataConverter = dataConverter
        }

        /// Retrieves and converts heartbeat details from the previous activity attempt.
        ///
        /// Heartbeat details are preserved across activity retries, allowing activities to resume execution
        /// from a known checkpoint. The details are converted from their serialized form using the
        /// configured data converter.
        ///
        /// - Important: This method will throw an error if the number of variadic types doesn't match
        /// with the number of received details.
        ///
        /// - Parameter detailTypes: The types to convert the heartbeat details to, specified as
        /// variadic generic parameters.
        /// - Returns: A tuple containing the converted heartbeat details in the order specified. Returns `nil` if there are no heartbeat details available from a previous activity attempt.
        /// - Throws: Conversion errors if the number of types doesn't match the stored details or if
        /// deserialization fails.
        public func heartbeatDetails<each HeartbeatDetail: Sendable>(
            as detailTypes: repeat (each HeartbeatDetail).Type
        ) async throws -> (repeat each HeartbeatDetail)? {
            guard !self.heartbeatDetails.isEmpty else {
                return nil
            }

            return try await self.dataConverter.convertPayloads(
                self.heartbeatDetails,
                as: repeat (each detailTypes).self
            ) as (repeat each HeartbeatDetail)
        }
    }

    /// The current activity execution context if one is available.
    ///
    /// Returns `nil` if called outside of an activity execution context. Activity implementations should
    /// check for `nil` before using the context.
    ///
    /// - Note: Internally this is stored as a task local and will propagate down the structured task tree.
    public static var current: ActivityExecutionContext? {
        self.taskLocal
    }

    /// The metadata and configuration information for this activity execution.
    public var info: Info

    /// The logger associated with the current activity execution.
    public let logger: Logger

    private let heartbeatContinuation: AsyncStream<[any Sendable]>.Continuation

    private let lookupCancellationReason: @Sendable () -> ActivityCancellationReason?

    private let implementation: Implementation

    init(
        info: Info,
        logger: Logger,
        outboundInterceptors: [any ActivityOutboundInterceptor],
        heartbeatContinuation: AsyncStream<[any Sendable]>.Continuation,
        lookupCancellationReason: @escaping @Sendable () -> ActivityCancellationReason?
    ) {
        self.info = info
        self.logger = logger
        self.heartbeatContinuation = heartbeatContinuation
        self.lookupCancellationReason = lookupCancellationReason
        self.implementation = .init(interceptors: outboundInterceptors)
    }

    /// Records a heartbeat signal with optional progress details.
    ///
    /// Heartbeats serve multiple purposes: they indicate that long-running activities are still alive, provide a
    /// mechanism for receiving cancellation signals, and allow activities to record progress checkpoints for
    /// retry scenarios.
    ///
    /// ## Usage Guidelines
    ///
    /// - Use heartbeats for all non-immediate, non-local activities
    /// - Required for activities that need to receive cancellation signals
    /// - Call periodically during long-running operations
    /// - Include progress details that help with retry recovery
    ///
    /// ## Throttling and Error Handling
    ///
    /// The system automatically throttles heartbeat calls based on the activity's heartbeat timeout
    /// configuration, so frequent calls don't burden the server. Heartbeats are processed asynchronously -
    /// serialization errors in details cause activity cancellation and failure rather than immediate errors.
    ///
    /// - Parameter details: Progress information to include with the heartbeat, preserved across retries.
    public func heartbeat<each Detail: Sendable>(
        details: repeat each Detail
    ) {
        self.implementation.heartbeat(
            heartbeatContinuation: heartbeatContinuation,
            input: .init(
                details: repeat each details
            )
        )
    }

    /// The reason for activity cancellation if the activity has been cancelled.
    public var cancellationReason: ActivityCancellationReason? {
        self.lookupCancellationReason()
    }
}

extension ActivityExecutionContext {
    init(
        activityTaskStart: Coresdk_ActivityTask_Start,
        taskQueue: String,
        taskToken: ActivityTaskToken,
        dataConverter: DataConverter,
        logger: Logger,
        outboundInterceptors: [any ActivityOutboundInterceptor],
        heartbeatContinuation: AsyncStream<[any Sendable]>.Continuation,
        lookupCancellationReason: @escaping @Sendable () -> ActivityCancellationReason?
    ) {
        let heartbeatTimeout = activityTaskStart.hasHeartbeatTimeout ? Duration(protobufDuration: activityTaskStart.heartbeatTimeout) : nil
        let scheduleToCloseTimeout =
            activityTaskStart.hasScheduleToCloseTimeout ? Duration(protobufDuration: activityTaskStart.scheduleToCloseTimeout) : nil
        let startToCloseTimeout = activityTaskStart.hasStartToCloseTimeout ? Duration(protobufDuration: activityTaskStart.startToCloseTimeout) : nil

        let info = Info(
            activityID: activityTaskStart.activityID,
            activityType: activityTaskStart.activityType,
            attempt: Int(activityTaskStart.attempt),
            currentAttemptScheduled: activityTaskStart.currentAttemptScheduledTime.date,
            heartbeatTimeout: heartbeatTimeout,
            isLocal: activityTaskStart.isLocal,
            scheduleToCloseTimeout: scheduleToCloseTimeout,
            scheduledTime: activityTaskStart.scheduledTime.date,
            startToCloseTimeout: startToCloseTimeout,
            startedTime: activityTaskStart.startedTime.date,
            taskQueue: taskQueue,
            taskToken: taskToken,
            workflowID: activityTaskStart.workflowExecution.workflowID,
            workflowNamespace: activityTaskStart.workflowNamespace,
            workflowRunID: activityTaskStart.workflowExecution.runID,
            workflowType: activityTaskStart.workflowType,
            heartbeatDetails: activityTaskStart.heartbeatDetails.map { .init(temporalAPIPayload: $0) },
            dataConverter: dataConverter
        )

        var logger = logger
        logger[metadataKey: LoggingKeys.taskQueue] = "\(info.taskQueue)"
        logger[metadataKey: LoggingKeys.workflowNamespace] = "\(info.workflowNamespace)"
        logger[metadataKey: LoggingKeys.workflowID] = "\(info.workflowID)"
        logger[metadataKey: LoggingKeys.workflowRunID] = "\(info.workflowRunID)"
        logger[metadataKey: LoggingKeys.workflowType] = "\(info.workflowType)"
        logger[metadataKey: LoggingKeys.activityID] = "\(info.activityID)"
        logger[metadataKey: LoggingKeys.activityName] = "\(info.activityType)"
        logger[metadataKey: LoggingKeys.activityAttempt] = "\(info.attempt)"

        self.init(
            info: info,
            logger: logger,
            outboundInterceptors: outboundInterceptors,
            heartbeatContinuation: heartbeatContinuation,
            lookupCancellationReason: lookupCancellationReason
        )
    }
}

extension ActivityExecutionContext {
    struct Implementation: InterceptorImplementation {
        let interceptors: [any ActivityOutboundInterceptor]
    }
}

extension ActivityExecutionContext.Implementation {
    func heartbeat<each Detail>(
        heartbeatContinuation: AsyncStream<[any Sendable]>.Continuation,
        input: HeartbeatInput<repeat each Detail>
    ) {
        intercept((any ActivityOutboundInterceptor).heartbeat, input: input) { input in
            var anyDetails = [any Sendable]()
            for detail in repeat each input.details {
                anyDetails.append(detail)
            }

            heartbeatContinuation.yield(anyDetails)
        }
    }
}
