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

import struct GRPCCore.CallOptions

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
    public var idReusePolicy: WorkflowIDReusePolicy

    /// The conflict resolution policy for workflows started with the same ID as running executions.
    ///
    /// Specifies how to handle attempts to start a workflow when another workflow with the same ID
    /// is currently running. This policy helps prevent unintended duplicate executions.
    public var idConflictPolicy: WorkflowIDConflictPolicy

    /// The maximum total execution time including retries and continue-as-new transitions.
    ///
    /// This timeout applies to the entire workflow execution lifecycle. If the workflow runs longer
    /// than this duration, it will be terminated. If `nil`, no execution timeout is applied.
    public var executionTimeOut: Duration?

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
    ///   - searchAttributes: The search attributes for the workflow. Defaults to `nil`.
    ///   - idReusePolicy: The workflow ID reuse policy. Defaults to allowing duplicate IDs after completion.
    ///   - idConflictPolicy: The workflow ID conflict policy. Defaults to failing when conflicts occur.
    ///   - callOptions: Options for the underlying gRPC call.
    public init(
        id: String,
        taskQueue: String,
        retryPolicy: RetryPolicy? = nil,
        executionTimeOut: Duration? = nil,
        searchAttributes: SearchAttributeCollection? = nil,
        idReusePolicy: WorkflowIDReusePolicy = .allowDuplicate,
        idConflictPolicy: WorkflowIDConflictPolicy = .fail,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.taskQueue = taskQueue
        self.retryPolicy = retryPolicy
        self.idReusePolicy = idReusePolicy
        self.idConflictPolicy = idConflictPolicy
        self.executionTimeOut = executionTimeOut
        self.searchAttributes = searchAttributes
        self.callOptions = callOptions
    }

    //    CronSchedule
    //    RequestEagerStart
    //    RunTimeout
    //    StartDelay
    //    StartSignal
    //    StartSignalArgs
    //    StaticDetails
    //    StaticSummary
    //    TaskTimeout
}
