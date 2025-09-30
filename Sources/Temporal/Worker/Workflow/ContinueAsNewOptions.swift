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

/// Options for continue-as-new workflow operations specifying execution parameters and state transitions.
public struct ContinueAsNewOptions: Sendable {
    /// The task queue where the new workflow execution should be processed.
    ///
    /// Task queues route workflows to appropriate workers with specific capabilities, configurations,
    /// or geographic locations. Changing the task queue enables load balancing, deployment strategies,
    /// or routing to workers with updated code versions.
    ///
    /// If `nil`, the new workflow execution uses the same task queue as the current workflow.
    public var taskQueue: String?

    /// The maximum time allowed for processing a single workflow task in the new execution.
    ///
    /// This timeout controls how long a workflow task can take to process on a worker. Workflow tasks
    /// include decision logic, activity scheduling, and state updates. Tasks exceeding this timeout
    /// are considered failed and will be retried.
    ///
    /// If `nil`, the new workflow execution uses the same task timeout as the current workflow.
    public var taskTimeout: Duration?

    /// The maximum time allowed for a single workflow execution run in the new execution.
    ///
    /// This timeout applies to individual workflow runs, measuring from workflow start to completion
    /// of a single execution attempt. It does not include retry delays or subsequent continue-as-new
    /// operations. When exceeded, the workflow run fails and may be retried based on the retry policy.
    ///
    /// If `nil`, the new workflow execution uses the same run timeout as the current workflow.
    public var runTimeout: Duration?

    /// The retry policy controlling automatic retry behavior for the new workflow execution.
    ///
    /// The retry policy defines how many times to retry, delay between retries, backoff behavior,
    /// and which errors should trigger retries. This enables automatic handling of transient
    /// failures at the workflow level.
    ///
    /// If `nil`, the new workflow execution uses the same retry policy as the current workflow.
    public var retryPolicy: RetryPolicy?

    /// Arbitrary key-value metadata associated with the new workflow execution.
    ///
    /// Memo data is stored with the workflow execution and can contain any serializable information
    /// useful for workflow identification, debugging, or business context. Unlike search attributes,
    /// memo data is not indexed and cannot be used for workflow queries.
    ///
    /// If `nil`, the new workflow execution uses the same memo as the current workflow.
    // TODO: Double check if this should be TemporalPayload or Any
    public var memo: [String: any Sendable]?

    // TODO: Add support for the below
    // VersioningIntent

    /// Indexed attributes that can be used for workflow search and filtering operations in the new execution.
    ///
    /// Search attributes enable querying and filtering workflows based on business data.
    /// These attributes are indexed by the Temporal server and can be used in workflow
    /// list operations and advanced queries.
    ///
    /// If `nil`, the new workflow execution uses the same search attributes as the current workflow.
    public var searchAttributes: SearchAttributeCollection?

    /// Creates continue-as-new options with the specified configuration parameters.
    ///
    /// All parameters are optional, allowing you to configure only the aspects that need to change
    /// from the current workflow execution. Unspecified parameters will inherit their values from
    /// the current workflow, ensuring continuity of operational settings.
    ///
    /// - Parameters:
    ///   - taskQueue: The task queue for the new execution. If `nil`, uses current workflow's task queue.
    ///   - taskTimeout: Maximum time for processing workflow tasks. If `nil`, uses current workflow's task timeout.
    ///   - runTimeout: Maximum time for a single workflow run. If `nil`, uses current workflow's run timeout.
    ///   - retryPolicy: Retry policy for failed executions. If `nil`, uses current workflow's retry policy.
    ///   - memo: Metadata for the new execution. If `nil`, uses current workflow's memo.
    ///   - searchAttributes: Indexed attributes for workflow search. If `nil`, uses current workflow's search attributes.
    public init(
        taskQueue: String? = nil,
        taskTimeout: Duration? = nil,
        runTimeout: Duration? = nil,
        retryPolicy: RetryPolicy? = nil,
        memo: [String: any Sendable]? = nil,
        searchAttributes: SearchAttributeCollection? = nil
    ) {
        self.taskQueue = taskQueue
        self.taskTimeout = taskTimeout
        self.runTimeout = runTimeout
        self.retryPolicy = retryPolicy
        self.memo = memo
        self.searchAttributes = searchAttributes
    }
}
