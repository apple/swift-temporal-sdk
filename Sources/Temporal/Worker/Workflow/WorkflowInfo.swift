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

import Foundation

/// Information about a workflow execution.
///
/// This structure provides detailed metadata about the workflow execution including
/// identifiers, timing information, configuration, and parent workflow details.
/// The information is determined when the workflow is initialized and remains
/// consistent throughout the workflow's lifecycle.
///
/// ## Usage
///
/// Workflow info is accessed through the workflow context:
///
/// ```swift
/// func run(context: WorkflowContext, input: MyInput) async throws -> MyOutput {
///     let info = context.info
///     print("Workflow ID: \(info.workflowID)")
///     print("Attempt: \(info.attempt)")
///     print("Task Queue: \(info.taskQueue)")
/// }
/// ```
public struct WorkflowInfo: Sendable {
    /// The current attempt number for this workflow execution (starting from 1).
    ///
    /// This value increments each time the workflow is retried due to failures
    /// or other retry-triggering conditions.
    public var attempt: Int

    /// The timestamp when this workflow execution was started.
    ///
    /// This represents the time when the workflow was first scheduled,
    /// not when it began executing on a worker.
    public var startTime: Date

    /// The human-readable name of the workflow.
    ///
    /// This corresponds to the workflow's registration name and is used
    /// for workflow identification and routing.
    public var workflowName: String

    /// The unique identifier for this workflow execution.
    ///
    /// This ID remains constant across all attempts and retries of the same
    /// workflow execution instance.
    public var workflowID: String

    /// The type name of the workflow implementation.
    ///
    /// This typically corresponds to the Swift type name of the workflow
    /// definition unless explicitly overridden.
    public var workflowType: String

    /// The unique run identifier for the current workflow execution attempt.
    ///
    /// This ID changes for each retry or continuation of the workflow.
    public var runID: String

    /// The run ID of the previous workflow execution if continued as new.
    ///
    /// This value is `nil` for the initial workflow execution and contains
    /// the previous run ID when the workflow was continued as new.
    public var continuedRunID: String?

    /// The name of the task queue where this workflow is executing.
    ///
    /// Task queues are used to route workflow and activity tasks to appropriate workers.
    public var taskQueue: String

    /// The Temporal namespace where this workflow is executing.
    ///
    /// Namespaces provide isolation and multitenancy within a Temporal cluster.
    public var namespace: String

    /// The cron schedule for this workflow if it's a scheduled workflow.
    ///
    /// This value is `nil` for non-scheduled workflows and contains the
    /// cron expression for scheduled workflow executions.
    public var cronSchedule: String?

    /// The run timeout for the workflow execution.
    ///
    /// This timeout applies to a single workflow run and is reset on retry.
    /// `nil` indicates no run timeout is configured.
    public var runTimeout: Duration?

    /// The task timeout for workflow tasks.
    ///
    /// This timeout applies to individual workflow task executions.
    /// `nil` indicates no task timeout is configured.
    public var taskTimeout: Duration?

    /// The execution timeout for the entire workflow.
    ///
    /// This timeout applies to the entire lifecycle of the workflow,
    /// including all retries. `nil` indicates no execution timeout is configured.
    public var executionTimeout: Duration?

    /// The error from the previous workflow execution if this is a retry.
    ///
    /// This value is `nil` for the initial execution attempt and contains
    /// the error that caused the previous execution to fail.
    public var lastFailure: (any Error)?

    /// The successful result from the previous workflow execution if continued as new.
    ///
    /// This value contains the result data when a workflow continues as new
    /// after successful completion.
    public var lastResult: [TemporalRawValue]?

    /// Headers associated with this workflow execution.
    ///
    /// Headers can be used to pass additional metadata and context
    /// to the workflow execution.
    public var headers: [String: TemporalPayload]

    /// Information about the parent workflow if this is a child workflow.
    ///
    /// This value is `nil` for root workflows and contains parent information
    /// for child workflow executions.
    public var parent: Parent?

    /// The retry policy configuration for this workflow.
    ///
    /// This policy defines how the workflow should be retried in case of failures.
    /// `nil` indicates no custom retry policy is configured.
    public var retryPolicy: RetryPolicy?

    /// Creates a new workflow information instance.
    ///
    /// - Parameters:
    ///   - attempt: The current attempt number.
    ///   - startTime: When the workflow was started.
    ///   - workflowName: The workflow's name.
    ///   - workflowID: The unique workflow identifier.
    ///   - workflowType: The workflow type name.
    ///   - runID: The current run identifier.
    ///   - taskQueue: The task queue name.
    ///   - namespace: The Temporal namespace.
    ///   - headers: Associated headers.
    public init(
        attempt: Int,
        startTime: Date,
        workflowName: String,
        workflowID: String,
        workflowType: String,
        runID: String,
        taskQueue: String,
        namespace: String,
        headers: [String: TemporalPayload]
    ) {
        self.attempt = attempt
        self.startTime = startTime
        self.workflowName = workflowName
        self.workflowID = workflowID
        self.workflowType = workflowType
        self.runID = runID
        self.taskQueue = taskQueue
        self.namespace = namespace
        self.headers = headers
    }
}

extension WorkflowInfo {
    /// Information about the parent workflow of a child workflow.
    ///
    /// This structure contains identifying information about the parent workflow
    /// when the current workflow is executing as a child workflow.
    public struct Parent: Sendable {
        /// The workflow ID of the parent workflow.
        ///
        /// This identifier uniquely identifies the parent workflow execution.
        public var workflowID: String

        /// The run ID of the parent workflow.
        ///
        /// This identifier specifies the particular execution run of the parent workflow.
        public var runID: String

        /// The namespace of the parent workflow.
        ///
        /// This specifies the Temporal namespace where the parent workflow is executing.
        public var namespace: String

        /// Creates a new parent workflow information instance.
        ///
        /// - Parameters:
        ///   - workflowID: The parent workflow's ID.
        ///   - runID: The parent workflow's run ID.
        ///   - namespace: The parent workflow's namespace.
        public init(workflowID: String, runID: String, namespace: String) {
            self.workflowID = workflowID
            self.runID = runID
            self.namespace = namespace
        }
    }
}
