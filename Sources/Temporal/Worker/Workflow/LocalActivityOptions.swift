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

/// Configuration options for local activity execution from workflows specifying timeouts, retry policies, and execution behavior.
///
/// Local activity options control how local activities are scheduled, executed, and managed within workflows.
/// These options define critical aspects such as timeouts, retry behavior, and cancellation handling
/// for activities that execute directly on the worker that schedules it.
///
/// ## Required configuration
///
/// At minimum, you must set either:
/// - ``scheduleToCloseTimeout``
/// - ``startToCloseTimeout``
///
/// If neither timeout is set, the activity will fail to start executing.
///
/// ## Cancellation support
///
/// Local activities support cancellation through the ``cancellationType`` property. Unlike remote activities,
/// local activities don't use heartbeat timeouts since they execute directly on the worker.
///
/// ## Usage
///
/// ```swift
/// // Basic local activity with schedule-to-close timeout
/// let options = LocalActivityOptions(scheduleToCloseTimeout: .seconds(30))
///
/// // Local activity with both timeouts
/// let detailedOptions = LocalActivityOptions(
///     scheduleToCloseTimeout: .minutes(5),
///     startToCloseTimeout: .seconds(30)
/// )
///
/// // Local activity with retry policy
/// let robustOptions = LocalActivityOptions(
///     scheduleToCloseTimeout: .minutes(10),
///     retryPolicy: RetryPolicy(maximumAttempts: 3)
/// )
/// ```
public struct LocalActivityOptions: Sendable {
    /// The unique identifier for the activity execution.
    ///
    /// - Important: This should never be set unless you have a strong understanding of Temporal's
    ///   activity deduplication system. Contact Temporal support to discuss your use case before
    ///   setting this value, as incorrect usage can lead to unexpected behavior.
    public var activityID: String?

    /// Defines how the workflow handles activity cancellation confirmation.
    ///
    /// This option controls the workflow's behavior when cancelling an activity, determining
    /// whether to wait for cancellation confirmation or proceed immediately.
    ///
    /// The default value is ``ActivityOptions/CancellationType/tryCancel``.
    public var cancellationType: ActivityOptions.CancellationType = .tryCancel

    /// The maximum time from activity scheduling to completion including all retry attempts.
    ///
    /// This timeout encompasses the entire activity lifecycle from when it's first scheduled
    /// until it completes successfully or fails permanently. It includes time waiting in queues,
    /// execution time, and retry delays.
    ///
    /// Either this timeout or ``startToCloseTimeout`` must be set. If unset, defaults to the
    /// workflow execution timeout.
    public var scheduleToCloseTimeout: Duration?

    /// The maximum time from activity scheduling to when a worker picks it up for execution.
    ///
    /// This timeout controls how long an activity can wait in the task queue before being
    /// assigned to a worker. It helps detect queue congestion or worker availability issues.
    ///
    /// If unset, defaults to the value of ``scheduleToCloseTimeout``.
    public var scheduleToStartTimeout: Duration?

    /// The maximum time for each individual activity execution attempt.
    ///
    /// This timeout applies to each retry attempt separately, measuring from when a worker
    /// starts executing the activity until it completes or fails. It does not include
    /// time spent waiting in queues or retry delays.
    ///
    /// Either this timeout or ``scheduleToCloseTimeout`` must be set.
    public var startToCloseTimeout: Duration?

    /// The retry policy controlling automatic retry behavior for failed activities.
    ///
    /// The retry policy defines how many times to retry, delay between retries, backoff behavior,
    /// and which errors should trigger retries. This enables automatic handling of transient failures.
    ///
    /// If `nil`, activities will retry indefinitely with exponential backoff until they succeed
    /// or the ``scheduleToCloseTimeout`` timeout is exceeded.
    public var retryPolicy: RetryPolicy?

    /// Creates activity options with a schedule-to-close timeout as the primary constraint.
    ///
    /// This initializer is suitable when you want to control the total time allowed for activity
    /// completion including all retries, with optional fine-grained control over individual attempts.
    ///
    /// - Parameters:
    ///   - scheduleToCloseTimeout: The maximum time from scheduling to completion including retries.
    ///   - startToCloseTimeout: The maximum time for each individual execution attempt. If `nil`,
    ///     uses the schedule-to-close timeout for individual attempts.
    ///   - cancellationType: How the workflow handles activity cancellation confirmation.
    ///   - retryPolicy: The retry policy. If `nil`, retries indefinitely with exponential backoff.
    public init(
        scheduleToCloseTimeout: Duration,
        startToCloseTimeout: Duration? = nil,
        cancellationType: ActivityOptions.CancellationType = .tryCancel,
        retryPolicy: RetryPolicy? = nil
    ) {
        self.scheduleToCloseTimeout = scheduleToCloseTimeout
        self.startToCloseTimeout = startToCloseTimeout
        self.cancellationType = cancellationType
        self.retryPolicy = retryPolicy
    }

    /// Creates activity options with a start-to-close timeout as the primary constraint.
    ///
    /// This initializer is suitable when you want to control the time allowed for each individual
    /// execution attempt, with optional control over the total time including retries.
    ///
    /// - Parameters:
    ///   - startToCloseTimeout: The maximum time for each individual execution attempt.
    ///   - scheduleToCloseTimeout: The maximum time from scheduling to completion including retries.
    ///     If `nil`, activities may retry indefinitely within workflow execution limits.
    ///   - cancellationType: How the workflow handles activity cancellation confirmation.
    ///   - retryPolicy: The retry policy. If `nil`, retries indefinitely with exponential backoff.
    public init(
        startToCloseTimeout: Duration,
        scheduleToCloseTimeout: Duration? = nil,
        cancellationType: ActivityOptions.CancellationType = .tryCancel,
        retryPolicy: RetryPolicy? = nil
    ) {
        self.scheduleToCloseTimeout = scheduleToCloseTimeout
        self.startToCloseTimeout = startToCloseTimeout
        self.cancellationType = cancellationType
        self.retryPolicy = retryPolicy
    }
}
