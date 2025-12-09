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
public import Temporal

#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

@usableFromInline
func randomBytes(count: Int) -> [UInt8] {
    var rng = SystemRandomNumberGenerator()
    return (0..<count).map { _ in UInt8.random(in: .min ... .max, using: &rng) }
}

/// Create a new activity test environment to test your Temporal Activity that relies on the `ActivityExecutionContext`.
///
/// Use this method to test your Temporal Activity that relies on the `ActivityExecutionContext`.
///
/// - Parameters:
///   - info: The activity info that should be supplied to your activity.
///   - cancellationReason: Provide a activity cancellation reason to test the scenario in which your activity was cancelled.
///   - logger: The logger to use with the activity execution context.
///   - body: The body that will be evaluated with the activity test environment set up.
/// - Throws: Rethrows the error from your body closure.
/// - Returns: Returns the value returned from your body closure.
public func withActivityTestEnvironment<Return>(
    info: ActivityExecutionContext.Info,
    cancellationReason: ActivityCancellationReason? = nil,
    logger: Logger = Logger(label: "no-log-handler", factory: { _ in SwiftLogNoOpLogHandler() }),
    _ body: () async throws -> Return
) async rethrows -> Return {
    let heartbeatDetails = AsyncStream<[any Sendable]>.makeStream()

    let context = ActivityExecutionContext(
        info: info,
        logger: logger,
        outboundInterceptors: [],
        heartbeatContinuation: heartbeatDetails.continuation
    ) {
        cancellationReason
    }

    defer {
        heartbeatDetails.continuation.finish()
    }

    return try await ActivityExecutionContext.$taskLocal.withValue(context) {
        try await body()
    }
}

/// Create a new activity test environment to test your Temporal Activity that relies on the `ActivityExecutionContext`.
///
/// Use this method to test your Temporal Activity that relies on the `ActivityExecutionContext`.
///
/// - Parameters:
///   - info: The activity info that should be supplied to your activity.
///   - cancellationReason: Provide a activity cancellation reason to test the scenario in which your activity was cancelled.
///   - body: The body that will be evaluated with the activity test environment set up.
///   - logger: The logger to use with the activity execution context.
///   - assertHeartbeatDetails: A closure you can run to concurrently assert heartbeats emitted by the activity while it is running.
/// - Throws: Rethrows the error from your body closure.
/// - Returns: Returns the value returned from your body closure.
public func withActivityTestEnvironment<Result>(
    info: ActivityExecutionContext.Info,
    cancellationReason: ActivityCancellationReason? = nil,
    logger: Logger = Logger(label: "no-log-handler", factory: { _ in SwiftLogNoOpLogHandler() }),
    _ body: () async throws -> Result,
    assertHeartbeatDetails: @Sendable (HeartbeatDetailsSequence) async throws -> Void
) async rethrows -> Result {
    let heartbeatDetails = AsyncStream<[any Sendable]>.makeStream()

    let context = ActivityExecutionContext(
        info: info,
        logger: logger,
        outboundInterceptors: [],
        heartbeatContinuation: heartbeatDetails.continuation
    ) {
        cancellationReason
    }

    return try await withoutActuallyEscaping(assertHeartbeatDetails) { escapingClosure in
        try await withThrowingTaskGroup { group in
            group.addTask {
                try await escapingClosure(HeartbeatDetailsSequence(base: heartbeatDetails.stream))
            }

            let result: Result
            do {
                result = try await ActivityExecutionContext.$taskLocal.withValue(context) {
                    try await body()
                }
                heartbeatDetails.continuation.finish()
            } catch {
                heartbeatDetails.continuation.finish()
                throw error
            }

            try await group.waitForAll()

            return result
        }
    }
}

extension ActivityExecutionContext.Info {
    /// Create a new Activity Information for testing purposes.
    ///
    /// - Parameters:
    ///   - activityID: The unique identifier for this activity instance.
    ///   - activityType: The activity type name.
    ///   - attempt: The current attempt number.
    ///   - isLocal: Whether this is a local activity.
    ///   - scheduleToCloseTimeout: The schedule-to-close timeout configuration.
    ///   - startToCloseTimeout: The start-to-close timeout configuration.
    ///   - heartbeatTimeout: The heartbeat timeout configuration.
    ///   - scheduledTime: When the activity was first scheduled.
    ///   - currentAttemptScheduled: When the current attempt was scheduled.
    ///   - startedTime: When the activity execution started.
    ///   - taskQueue: The task queue name.
    ///   - taskToken: The unique task token.
    ///   - workflowID: The workflow ID that scheduled this activity.
    ///   - workflowNamespace: The namespace for execution.
    ///   - workflowRunID: The workflow run ID.
    ///   - workflowType: The workflow type name.
    ///   - heartbeatDetails: Previous heartbeat details.
    ///   - dataConverter: Data converter for serialization.
    public init<each Value>(
        activityID: String = "test-activity-id",
        activityType: String = "TestActivity",
        attempt: Int = 1,
        isLocal: Bool = false,
        scheduleToCloseTimeout: Duration? = nil,
        startToCloseTimeout: Duration? = nil,
        heartbeatTimeout: Duration? = nil,
        scheduledTime: Date = .now,
        currentAttemptScheduled: Date = .now,
        startedTime: Date = .now,
        taskQueue: String = "test-queue",
        taskToken: ActivityTaskToken = { ActivityTaskToken(bytes: randomBytes(count: 32)) }(),
        workflowID: String = "test-workflow",
        workflowNamespace: String = "default",
        workflowRunID: String = UUID().uuidString,
        workflowType: String = "TestWorkflow",
        heartbeatDetails: repeat (each Value)?,
        dataConverter: DataConverter = .default
    ) async throws {
        let heartbeatDetailsPayloads = try await dataConverter.convertValues(repeat each heartbeatDetails)

        self.init(
            activityID: activityID,
            activityType: activityType,
            attempt: attempt,
            currentAttemptScheduled: currentAttemptScheduled,
            heartbeatTimeout: heartbeatTimeout,
            isLocal: isLocal,
            scheduleToCloseTimeout: scheduleToCloseTimeout,
            scheduledTime: scheduledTime,
            startToCloseTimeout: startToCloseTimeout,
            startedTime: startedTime,
            taskQueue: taskQueue,
            taskToken: taskToken,
            workflowID: workflowID,
            workflowNamespace: workflowNamespace,
            workflowRunID: workflowRunID,
            workflowType: workflowType,
            heartbeatDetails: heartbeatDetailsPayloads,
            dataConverter: dataConverter
        )
    }
}
