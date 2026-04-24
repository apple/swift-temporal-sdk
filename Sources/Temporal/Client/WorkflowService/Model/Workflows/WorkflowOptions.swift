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

public import struct GRPCCore.CallOptions

/// Configuration options that control how a workflow execution is started and managed.
public struct WorkflowOptions: Sendable {
    /// The unique identifier that distinguishes this workflow execution from others.
    ///
    /// The workflow ID must be unique within the namespace according to the configured ``idReusePolicy``.
    /// This ID is used for workflow queries, signals, and other operations throughout the workflow's lifecycle.
    public var id: String

    /// The task queue where workflow tasks are dispatched and processed by workers.
    ///
    /// Workers poll this task queue for workflow tasks. The task queue name acts as a routing mechanism
    /// to ensure the workflow is executed by workers configured to handle this specific queue.
    public var taskQueue: String

    /// The retry policy that defines how failed workflow executions are retried.
    ///
    /// When specified, this policy controls the automatic retry behavior for workflow execution failures.
    /// If `nil`, the workflow will not be automatically retried upon failure.
    public var retryPolicy: RetryPolicy?

    /// The policy that controls reusing workflow IDs from previously completed executions.
    ///
    /// Determines whether a workflow ID can be reused after a previous workflow with the same ID
    /// has completed. This policy affects workflow uniqueness constraints within the namespace.
    public var idReusePolicy: Api.Enums.V1.WorkflowIdReusePolicy

    /// The conflict resolution policy for workflows started with the same ID as running executions.
    ///
    /// Specifies how to handle attempts to start a workflow when another workflow with the same ID
    /// is currently running. This policy helps prevent unintended duplicate executions.
    public var idConflictPolicy: Api.Enums.V1.WorkflowIdConflictPolicy

    /// The maximum total execution time including retries and continue-as-new transitions.
    ///
    /// This timeout applies to the entire workflow execution lifecycle. If the workflow runs longer
    /// than this duration, it will be terminated. If `nil`, no execution timeout is applied.
    public var executionTimeOut: Duration?

    /// The maximum time for a single workflow run.
    ///
    /// Unlike ``executionTimeOut`` which spans retries and continue-as-new transitions, this timeout
    /// applies only to an individual workflow run. If the workflow run exceeds this duration, it will
    /// be terminated. If `nil`, no run timeout is applied.
    public var runTimeout: Duration?

    /// The maximum time for a single workflow task.
    ///
    /// A workflow task is the processing of a batch of events by the workflow code. If a workflow task
    /// takes longer than this duration, it will be timed out and retried. If `nil`, the server default
    /// (typically 10 seconds) is used.
    public var taskTimeout: Duration?

    /// The delay before the workflow starts executing.
    ///
    /// When set, the server will wait this duration before dispatching the first workflow task.
    /// If the workflow receives a signal before the delay expires, a workflow task will be dispatched
    /// immediately and the remaining delay will be ignored.
    ///
    /// - Note: Cannot be used with ``cronSchedule``.
    public var startDelay: Duration?

    /// The cron schedule expression for the workflow.
    ///
    /// When set, the workflow will be executed on the specified cron schedule. Uses standard cron
    /// expression syntax (for example, `"0 * * * *"` for every hour).
    ///
    /// - Note: Deprecated in favor of Temporal Schedules, but still supported for backward compatibility.
    /// - Note: Cannot be used with ``startDelay``.
    public var cronSchedule: String?

    /// Whether to request eager workflow task dispatch.
    ///
    /// When `true`, the server is encouraged to dispatch the first workflow task to a local worker
    /// running this same client. This can reduce the latency to start the workflow by avoiding
    /// a round-trip through the task queue. Defaults to `false`.
    public var requestEagerStart: Bool

    /// A single-line fixed summary for this workflow execution that may appear in UI/CLI.
    ///
    /// This can be in single-line Temporal markdown format. The summary is set at workflow start
    /// and cannot be changed during execution. The value is limited to 400 bytes.
    ///
    /// - Important: This setting is experimental.
    public var staticSummary: String?

    /// General fixed details for this workflow execution that may appear in UI/CLI.
    ///
    /// This can be in Temporal markdown format and can span multiple lines. The details are set at
    /// workflow start and cannot be changed during execution. For details that can be updated
    /// during the workflow's lifecycle, use `Workflow.currentDetails` within the workflow.
    /// The value is limited to 20000 bytes.
    ///
    /// - Important: This setting is experimental.
    public var staticDetails: String?

    /// The priority for this workflow execution.
    ///
    /// Priority controls the relative ordering of task processing when tasks are backlogged in a queue.
    /// Lower priority key values correspond to higher priorities (tasks run sooner). Activities and
    /// child workflows inherit priority from the workflow that created them, but may override fields.
    public var priority: Priority?

    /// The versioning override for this workflow execution.
    ///
    /// When set, takes precedence over the versioning behavior sent by the SDK on workflow task
    /// completion. The workflow can be pinned to a specific deployment version or set to auto-upgrade
    /// to the current deployment version. To unset the override after the workflow is running, use
    /// `UpdateWorkflowExecutionOptions`.
    public var versioningOverride: VersioningOverride?

    /// Key-value metadata attached to the workflow for application-specific purposes.
    ///
    /// Memos provide a way to attach custom metadata to workflows that is accessible throughout
    /// the workflow lifecycle. Unlike search attributes, memos are not indexed for search but
    /// can store arbitrary application data.
    public var memo: [String: any Sendable]?

    /// The indexed attributes that enable workflow search and filtering capabilities.
    ///
    /// Search attributes are indexed by the Temporal server and enable filtering and searching
    /// workflows through the Web UI, CLI, and APIs. These attributes must be pre-registered
    /// with the Temporal cluster before use.
    public var searchAttributes: SearchAttributeCollection?

    /// Options for the underlying gRPC call.
    ///
    /// If nil, the SDK applies default metadata headers and retry policies.
    public var callOptions: CallOptions?

    /// Creates workflow options with the specified configuration.
    ///
    /// - Parameters:
    ///   - id: The unique workflow identifier.
    ///   - taskQueue: The task queue to run the workflow on.
    ///   - retryPolicy: The workflow's retry policy. Defaults to `nil` (no retries).
    ///   - executionTimeOut: The total execution timeout of the workflow. Defaults to `nil` (no timeout).
    ///   - runTimeout: The timeout for a single workflow run. Defaults to `nil` (no timeout).
    ///   - taskTimeout: The timeout for a single workflow task. Defaults to `nil` (server default).
    ///   - startDelay: The delay before the workflow starts executing. Defaults to `nil` (no delay).
    ///   - cronSchedule: The cron schedule expression. Defaults to `nil` (no cron).
    ///   - requestEagerStart: Whether to request eager workflow task dispatch. Defaults to `false`.
    ///   - staticSummary: A fixed summary for the workflow. Defaults to `nil`.
    ///   - staticDetails: Fixed details for the workflow. Defaults to `nil`.
    ///   - priority: The workflow execution priority. Defaults to `nil`.
    ///   - versioningOverride: The versioning override. Defaults to `nil`.
    ///   - searchAttributes: The search attributes for the workflow. Defaults to `nil`.
    ///   - idReusePolicy: The workflow ID reuse policy. Defaults to allowing duplicate IDs after completion.
    ///   - idConflictPolicy: The workflow ID conflict policy. Defaults to failing when conflicts occur.
    ///   - callOptions: Options for the underlying gRPC call.
    public init(
        id: String,
        taskQueue: String,
        retryPolicy: RetryPolicy? = nil,
        executionTimeOut: Duration? = nil,
        runTimeout: Duration? = nil,
        taskTimeout: Duration? = nil,
        startDelay: Duration? = nil,
        cronSchedule: String? = nil,
        requestEagerStart: Bool = false,
        staticSummary: String? = nil,
        staticDetails: String? = nil,
        priority: Priority? = nil,
        versioningOverride: VersioningOverride? = nil,
        searchAttributes: SearchAttributeCollection? = nil,
        idReusePolicy: Api.Enums.V1.WorkflowIdReusePolicy = .allowDuplicate,
        idConflictPolicy: Api.Enums.V1.WorkflowIdConflictPolicy = .fail,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.taskQueue = taskQueue
        self.retryPolicy = retryPolicy
        self.idReusePolicy = idReusePolicy
        self.idConflictPolicy = idConflictPolicy
        self.executionTimeOut = executionTimeOut
        self.runTimeout = runTimeout
        self.taskTimeout = taskTimeout
        self.startDelay = startDelay
        self.cronSchedule = cronSchedule
        self.requestEagerStart = requestEagerStart
        self.staticSummary = staticSummary
        self.staticDetails = staticDetails
        self.priority = priority
        self.versioningOverride = versioningOverride
        self.searchAttributes = searchAttributes
        self.callOptions = callOptions
    }
}
