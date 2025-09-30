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

/// Configuration options for activity execution from workflows specifying timeouts, retry policies, and execution behavior.
///
/// Activity options control how activities are scheduled, executed, and managed within workflows.
/// These options define critical aspects such as timeouts, retry behavior, cancellation handling,
/// and worker selection for activity execution.
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
/// To make activities cancellable, set the ``heartbeatTimeout`` property. Activities that complete
/// nearly instantly may omit this timeout, but most long-running activities should configure
/// heartbeat timeouts for proper cancellation handling.
///
/// ## Usage
///
/// ```swift
/// // Basic activity with schedule-to-close timeout
/// let options = ActivityOptions(scheduleToCloseTimeout: .seconds(30))
///
/// // Activity with both timeouts and heartbeat
/// let detailedOptions = ActivityOptions(
///     scheduleToCloseTimeout: .minutes(5),
///     startToCloseTimeout: .seconds(30),
///     heartbeatTimeout: .seconds(10)
/// )
///
/// // Activity with retry policy and custom task queue
/// let robustOptions = ActivityOptions(
///     scheduleToCloseTimeout: .minutes(10),
///     heartbeatTimeout: .seconds(15),
///     taskQueue: "specialized-workers",
///     retryPolicy: RetryPolicy(maximumAttempts: 3)
/// )
/// ```
///
/// ## Worker versioning
///
/// When using worker versioning features, configure ``versioningIntent`` to control
/// whether activities run on workers with compatible build IDs.
public struct ActivityOptions: Hashable, Sendable {
    /// The unique identifier for the activity execution.
    ///
    /// - Important: This should never be set unless you have a strong understanding of Temporal's
    ///   activity deduplication system. Contact Temporal support to discuss your use case before
    ///   setting this value, as incorrect usage can lead to unexpected behavior.
    public var activityID: String?

    /// A boolean value that indicates whether eager activity execution is disabled for this activity.
    ///
    /// Eager activity execution is a server optimization that sends activities back to the same worker
    /// as the calling workflow if the worker has available capacity. When `false` (the default),
    /// eager execution may still be disabled at the worker level or unavailable due to capacity constraints.
    ///
    /// Set to `true` to force activities to go through the normal task queue distribution mechanism,
    /// which may be useful for load balancing or when activities require specialized workers.
    public var disableEagerActivityExecution: Bool = false

    /// Defines how the workflow handles activity cancellation confirmation.
    ///
    /// This option controls the workflow's behavior when cancelling an activity, determining
    /// whether to wait for cancellation confirmation or proceed immediately.
    ///
    /// The default value is ``CancellationType/tryCancel``.
    public var cancellationType: CancellationType = .tryCancel

    /// The maximum time between activity heartbeat signals.
    ///
    /// Heartbeats indicate that long-running activities are still alive and making progress.
    /// If an activity doesn't send a heartbeat within this timeout, it's considered failed and
    /// will be retried or cancelled.
    ///
    /// - Note: This timeout must be set for activities to receive cancellation signals.
    ///   All but the most instantly completing activities should configure this timeout.
    ///
    /// If `nil`, the activity will not send heartbeats and cannot be cancelled.
    public var heartbeatTimeout: Duration?

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

    /// The task queue where this activity should be executed.
    ///
    /// Task queues route activities to appropriate workers with specific capabilities.
    /// Different task queues can have workers with different configurations, dependencies,
    /// or geographic locations.
    ///
    /// If unset, the activity uses the same task queue as the calling workflow.
    public var taskQueue: String?

    /// The retry policy controlling automatic retry behavior for failed activities.
    ///
    /// The retry policy defines how many times to retry, delay between retries, backoff behavior,
    /// and which errors should trigger retries. This enables automatic handling of transient failures.
    ///
    /// If `nil`, activities will retry indefinitely with exponential backoff until they succeed
    /// or the ``scheduleToCloseTimeout`` timeout is exceeded.
    public var retryPolicy: RetryPolicy?

    /// Controls whether this activity should run on workers with compatible build IDs.
    ///
    /// When using Temporal's worker versioning feature, this option determines if the activity
    /// must run on a worker with a build ID compatible with the calling workflow's version.
    ///
    /// The default value is ``VersioningIntent/unspecified``.
    public var versioningIntent: VersioningIntent = .unspecified

    /// Creates activity options with a schedule-to-close timeout as the primary constraint.
    ///
    /// This initializer is suitable when you want to control the total time allowed for activity
    /// completion including all retries, with optional fine-grained control over individual attempts.
    ///
    /// - Parameters:
    ///   - scheduleToCloseTimeout: The maximum time from scheduling to completion including retries.
    ///   - startToCloseTimeout: The maximum time for each individual execution attempt. If `nil`,
    ///     uses the schedule-to-close timeout for individual attempts.
    ///   - disableEagerActivityExecution: If `true`, disables eager execution optimization.
    ///   - cancellationType: How the workflow handles activity cancellation confirmation.
    ///   - heartbeatTimeout: The maximum time between heartbeat signals. Required for cancellation.
    ///   - taskQueue: The task queue for execution. If `nil`, uses the workflow's task queue.
    ///   - retryPolicy: The retry policy. If `nil`, retries indefinitely with exponential backoff.
    ///   - versioningIntent: Whether to require compatible worker build IDs.
    public init(
        scheduleToCloseTimeout: Duration,
        startToCloseTimeout: Duration? = nil,
        disableEagerActivityExecution: Bool = false,
        cancellationType: CancellationType = .tryCancel,
        heartbeatTimeout: Duration? = nil,
        taskQueue: String? = nil,
        retryPolicy: RetryPolicy? = nil,
        versioningIntent: VersioningIntent = .unspecified
    ) {
        self.scheduleToCloseTimeout = scheduleToCloseTimeout
        self.startToCloseTimeout = startToCloseTimeout
        self.disableEagerActivityExecution = disableEagerActivityExecution
        self.cancellationType = cancellationType
        self.heartbeatTimeout = heartbeatTimeout
        self.taskQueue = taskQueue
        self.retryPolicy = retryPolicy
        self.versioningIntent = versioningIntent
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
    ///   - disableEagerActivityExecution: If `true`, disables eager execution optimization.
    ///   - cancellationType: How the workflow handles activity cancellation confirmation.
    ///   - heartbeatTimeout: The maximum time between heartbeat signals. Required for cancellation.
    ///   - taskQueue: The task queue for execution. If `nil`, uses the workflow's task queue.
    ///   - retryPolicy: The retry policy. If `nil`, retries indefinitely with exponential backoff.
    ///   - versioningIntent: Whether to require compatible worker build IDs.
    public init(
        startToCloseTimeout: Duration,
        scheduleToCloseTimeout: Duration? = nil,
        disableEagerActivityExecution: Bool = false,
        cancellationType: CancellationType = .tryCancel,
        heartbeatTimeout: Duration? = nil,
        taskQueue: String? = nil,
        retryPolicy: RetryPolicy? = nil,
        versioningIntent: VersioningIntent = .unspecified
    ) {
        self.scheduleToCloseTimeout = scheduleToCloseTimeout
        self.startToCloseTimeout = startToCloseTimeout
        self.disableEagerActivityExecution = disableEagerActivityExecution
        self.cancellationType = cancellationType
        self.heartbeatTimeout = heartbeatTimeout
        self.taskQueue = taskQueue
        self.retryPolicy = retryPolicy
        self.versioningIntent = versioningIntent
    }
}
