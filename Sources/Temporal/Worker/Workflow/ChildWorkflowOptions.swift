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

/// Configuration options for starting child workflows specifying execution parameters, timeouts, and lifecycle behavior.
///
/// Child workflow options control how child workflows are created, executed, and managed within parent workflows.
/// These options define execution environments, timeout constraints, retry policies, and the relationship
/// between parent and child workflow lifecycles.
public struct ChildWorkflowOptions: Sendable {
    /// The unique identifier for the child workflow execution.
    ///
    /// When specified, this identifier uniquely identifies the child workflow within its namespace.
    /// The workflow ID is used for workflow deduplication, signaling, and querying operations.
    ///
    /// If `nil`, a deterministic random identifier is generated based on the parent workflow's
    /// execution context, ensuring consistent behavior during workflow replay.
    public var id: String?

    /// The task queue where the child workflow should execute.
    ///
    /// Task queues route workflows to appropriate workers with specific capabilities, configurations,
    /// or geographic locations.
    ///
    /// If `nil`, the child workflow uses the same task queue as the parent workflow.
    public var taskQueue: String?

    /// The retry policy controlling automatic retry behavior for failed child workflow executions.
    ///
    /// The retry policy defines how many times to retry, delay between retries, backoff behavior,
    /// and which errors should trigger retries. This enables automatic handling of transient
    /// failures at the workflow level.
    ///
    /// If `nil`, child workflows will retry indefinitely with exponential backoff according
    /// to the default retry policy.
    public var retryPolicy: RetryPolicy?

    /// The maximum total time allowed for child workflow execution including all retries and continue-as-new operations.
    ///
    /// This timeout encompasses the entire child workflow lifecycle from start to final completion,
    /// including time spent in retries, continue-as-new chains, and all intermediate executions.
    /// It provides an upper bound on total resource consumption.
    ///
    /// If `nil`, the child workflow can execute indefinitely within the parent workflow's constraints.
    public var executionTimeout: Duration?

    /// The maximum time allowed for a single child workflow execution run.
    ///
    /// This timeout applies to individual workflow runs, measuring from workflow start to completion
    /// of a single execution attempt. It does not include retry delays or continue-as-new operations.
    /// When exceeded, the workflow run fails and may be retried based on the retry policy.
    ///
    /// If `nil`, individual runs can execute indefinitely within the execution timeout constraints.
    public var runTimeout: Duration?

    /// The maximum time allowed for processing a single workflow task.
    ///
    /// This timeout controls how long a workflow task can take to process on a worker. Workflow tasks
    /// include decision logic, activity scheduling, and state updates. Tasks exceeding this timeout
    /// are considered failed and will be retried.
    ///
    /// If `nil`, uses the system default task timeout.
    public var taskTimeout: Duration?

    /// Arbitrary key-value metadata associated with the child workflow execution.
    ///
    /// Memo data is stored with the workflow execution and can contain any serializable information
    /// useful for workflow identification, debugging, or business context. Unlike search attributes,
    /// memo data is not indexed and cannot be used for workflow queries.
    ///
    /// If `nil`, no memo data is associated with the child workflow.
    public var memo: [String: any Sendable]?

    /// Indexed attributes that can be used for workflow search and filtering operations.
    ///
    /// Search attributes enable querying and filtering workflows based on business data.
    /// These attributes are indexed by the Temporal server and can be used in workflow
    /// list operations and advanced queries.
    ///
    /// If `nil`, no search attributes are associated with the child workflow.
    public var searchAttributes: SearchAttributeCollection?

    /// Defines how the child workflow is handled when the parent workflow closes.
    ///
    /// This policy controls the child workflow's fate when the parent workflow completes,
    /// fails, or is cancelled, enabling different coupling patterns between parent and
    /// child executions.
    ///
    /// The default value is ``ParentClosePolicy/terminate``.
    public var parentClosePolicy: ParentClosePolicy = .terminate

    /// Controls whether the child workflow can reuse a workflow ID from a previously closed workflow.
    ///
    /// This policy determines the behavior when starting a child workflow with an ID that was
    /// previously used by a completed workflow. Different policies enable various patterns
    /// for workflow deduplication and restart behavior.
    ///
    /// The default value is ``WorkflowIDReusePolicy/allowDuplicate``.
    public var idReusePolicy: WorkflowIDReusePolicy = .allowDuplicate

    /// The cron schedule expression for recurring child workflow execution.
    ///
    /// When specified, the child workflow executes according to the cron schedule, creating
    /// new workflow runs at scheduled intervals. The schedule uses standard cron syntax
    /// with support for seconds, minutes, hours, days, months, and years.
    ///
    /// If `nil`, the child workflow executes once without recurring behavior.
    ///
    /// **Example schedules:**
    /// - `"0 0 * * *"` - Daily at midnight
    /// - `"0 */6 * * *"` - Every 6 hours
    /// - `"0 0 1 * *"` - Monthly on the 1st day
    public var cronSchedule: String?

    /// Defines how the parent workflow handles child workflow cancellation.
    ///
    /// This option controls the parent workflow's behavior when cancelling a child workflow,
    /// determining whether to wait for cancellation confirmation or proceed immediately.
    /// It affects workflow execution flow and resource cleanup behavior.
    ///
    /// The default value is ``ChildWorkflowCancellationType/waitCancellationCompleted``.
    public var cancellationType: ChildWorkflowCancellationType = .waitCancellationCompleted

    /// Controls whether the child workflow should run on workers with compatible build IDs.
    ///
    /// When using Temporal's worker versioning feature, this option determines if the child
    /// workflow must run on a worker with a build ID compatible with the parent workflow's
    /// version or can run on any available worker.
    ///
    /// The default value is ``VersioningIntent/unspecified``.
    public var versioningIntent: VersioningIntent = .unspecified

    /// Creates child workflow options with the specified configuration parameters.
    ///
    /// All parameters are optional, allowing you to configure only the aspects relevant to your
    /// use case while accepting sensible defaults for other options.
    ///
    /// - Parameters:
    ///   - id: The unique workflow identifier. If `nil`, generates a deterministic random identifier.
    ///   - taskQueue: The task queue for execution. If `nil`, uses the parent workflow's task queue.
    ///   - retryPolicy: The retry policy for failed executions. If `nil`, uses default retry behavior.
    ///   - executionTimeout: Maximum total execution time including retries and continue-as-new.
    ///   - runTimeout: Maximum time for a single workflow run.
    ///   - taskTimeout: Maximum time for processing a single workflow task.
    ///   - memo: Arbitrary metadata associated with the workflow execution.
    ///   - searchAttributes: Indexed attributes for workflow search and filtering.
    ///   - parentClosePolicy: How the child is handled when the parent closes.
    ///   - idReusePolicy: Whether to allow reusing workflow IDs from previously closed workflows.
    ///   - cronSchedule: Cron schedule expression for recurring execution.
    ///   - cancellationType: How the parent handles child workflow cancellation.
    ///   - versioningIntent: Whether to require compatible worker build IDs.
    public init(
        id: String? = nil,
        taskQueue: String? = nil,
        retryPolicy: RetryPolicy? = nil,
        executionTimeout: Duration? = nil,
        runTimeout: Duration? = nil,
        taskTimeout: Duration? = nil,
        memo: [String: any Sendable]? = nil,
        searchAttributes: SearchAttributeCollection? = nil,
        parentClosePolicy: ParentClosePolicy = .terminate,
        idReusePolicy: WorkflowIDReusePolicy = .allowDuplicate,
        cronSchedule: String? = nil,
        cancellationType: ChildWorkflowCancellationType = .waitCancellationCompleted,
        versioningIntent: VersioningIntent = .unspecified
    ) {
        self.id = id
        self.taskQueue = taskQueue
        self.retryPolicy = retryPolicy
        self.executionTimeout = executionTimeout
        self.runTimeout = runTimeout
        self.taskTimeout = taskTimeout
        self.memo = memo
        self.searchAttributes = searchAttributes
        self.parentClosePolicy = parentClosePolicy
        self.idReusePolicy = idReusePolicy
        self.cronSchedule = cronSchedule
        self.cancellationType = cancellationType
        self.versioningIntent = versioningIntent
    }
}
