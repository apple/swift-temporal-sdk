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

import struct Foundation.Date

extension HistoryEvent.Attributes {
    /// Always the first event in workflow history.
    public struct WorkflowExecutionStarted: Hashable, Sendable {
        /// The type name of the workflow.
        public var workflowType: String

        /// If this workflow is a child, the namespace our parent lives in.
        ///
        /// SDKs and UI tools should use `parent_workflow_namespace` field but server must use `parent_workflow_namespace_id` only.
        public var parentWorkflowNamespace: String?

        /// The namespace ID of the parent workflow.
        public var parentWorkflowNamespaceID: String?

        /// Contains information about parent workflow execution that initiated the child workflow these attributes belong to.
        ///
        /// If the workflow these attributes belong to is not a child workflow of any other execution, this field will not be populated.
        public var parentWorkflowExecution: WorkflowExecutionID?

        /// EventID of the child execution initiated event in parent workflow.
        public var parentInitiatedEventID: Int?

        /// The task queue on which the workflow should be scheduled.
        public var taskQueue: TaskQueue

        /// SDK will deserialize this and provide it as arguments to the workflow function.
        public var input: [TemporalPayload]

        /// Total workflow execution timeout including retries and continue as new.
        public var workflowExecutionTimeout: Duration?

        /// Timeout of a single workflow run.
        public var workflowRunTimeout: Duration?

        /// Timeout of a single workflow task.
        public var workflowTaskTimeout: Duration?

        /// Run id of the previous workflow which continued-as-new or retired or cron executed into this workflow.
        public var continuedExecutionRunID: String?

        /// The initiator of the continue-as-new operation.
        public var initiator: ContinueAsNewInitiator

        /// If this workflow was a continuation and that continuation failed, the details of that.
        public var continuedFailure: TemporalFailure?

        /// The completion result from the previous execution.
        public var lastCompletionResult: [TemporalPayload]

        /// This is the run id when the WorkflowExecutionStarted event was written.
        ///
        /// A workflow reset changes the execution run_id, but preserves this field.
        public var originalExecutionRunID: String

        /// Identity of the client who requested this execution.
        public var identity: String?

        /// This is the very first runId along the chain of ContinueAsNew, Retry, Cron and Reset.
        ///
        /// Used to identify a chain.
        public var firstExecutionRunID: String

        /// The retry policy for the workflow.
        public var retryPolicy: RetryPolicy?

        /// Starting at 1, the number of times we have tried to execute this workflow.
        public var attempt: Int

        /// The absolute time at which the workflow will be timed out.
        ///
        /// This is passed without change to the next run/retry of a workflow.
        public var workflowExecutionExpirationTime: Date?

        /// If this workflow runs on a cron schedule, it will appear here.
        public var cronSchedule: String?

        /// For a cron workflow, this contains the amount of time between when this iteration of the cron workflow was scheduled and when it should run next per its cron_schedule.
        public var firstWorkflowTaskBackoff: Duration?

        /// Memo data attached to the workflow.
        public var memo: [String: TemporalPayload]

        /// Search attributes for the workflow.
        public var searchAttributes: SearchAttributeCollection

        /// Previous auto-reset points for the workflow.
        public var prevAutoResetPoints: [ResetPoint]

        /// Headers passed to the workflow.
        public var headers: [String: TemporalPayload]

        /// Version of the child execution initiated event in parent workflow.
        ///
        /// It should be used together with parent_initiated_event_id to identify a child initiated event for global namespace.
        public var parentInitiatedEventVersion: Int?

        /// This field is new in 1.21.
        public var workflowID: String

        /// If this workflow intends to use anything other than the current overall default version for the queue, then we include it here.
        ///
        /// - Note: Deprecated - This field is no longer used.
        public var sourceVersionStamp: WorkerVersionStamp?

        /// Completion callbacks attached when this workflow was started.
        public var completionCallbacks: [Callback]

        /// Contains information about the root workflow execution.
        ///
        /// The root workflow execution is defined as follows:
        /// 1. A workflow without parent workflow is its own root workflow.
        /// 2. A workflow that has a parent workflow has the same root workflow as its parent workflow.
        /// Note: workflows continued as new or reseted may or may not have parents, check examples below.
        ///
        /// Examples:
        ///   Scenario 1: Workflow W1 starts child workflow W2, and W2 starts child workflow W3.
        ///     - The root workflow of all three workflows is W1.
        ///   Scenario 2: Workflow W1 starts child workflow W2, and W2 continued as new W3.
        ///     - The root workflow of all three workflows is W1.
        ///   Scenario 3: Workflow W1 continued as new W2.
        ///     - The root workflow of W1 is W1 and the root workflow of W2 is W2.
        ///   Scenario 4: Workflow W1 starts child workflow W2, and W2 is reseted, creating W3.
        ///     - The root workflow of all three workflows is W1.
        ///   Scenario 5: Workflow W1 is reseted, creating W2.
        ///     - The root workflow of W1 is W1 and the root workflow of W2 is W2.
        public var rootWorkflowExecution: WorkflowExecutionID?

        /// When present, this execution is assigned to the build ID of its parent or previous execution.
        ///
        /// - Note: Deprecated - This field is no longer used.
        public var inheritedBuildID: String?

        /// Versioning override applied to this workflow when it was started.
        public var versioningOverride: VersioningOverride?

        /// When present, it means this is a child workflow of a parent that is Pinned to this Worker Deployment Version.
        ///
        /// In this case, child workflow will start as Pinned to this Version instead of starting on the Current Version of its Task Queue.
        /// This is set only if the child workflow is starting on a Task Queue belonging to the same Worker Deployment Version.
        public var parentPinnedWorkerDeploymentVersion: String?

        /// Priority metadata for the workflow.
        public var priority: Priority?

        /// Creates event attributes for when a workflow execution has started.
        public init(
            workflowType: String,
            parentWorkflowNamespace: String? = nil,
            parentWorkflowNamespaceID: String? = nil,
            parentWorkflowExecution: WorkflowExecutionID? = nil,
            parentInitiatedEventID: Int? = nil,
            taskQueue: TaskQueue,
            input: [TemporalPayload],
            workflowExecutionTimeout: Duration? = nil,
            workflowRunTimeout: Duration? = nil,
            workflowTaskTimeout: Duration? = nil,
            continuedExecutionRunID: String? = nil,
            initiator: ContinueAsNewInitiator,
            continuedFailure: TemporalFailure? = nil,
            lastCompletionResult: [TemporalPayload] = [],
            originalExecutionRunID: String,
            identity: String? = nil,
            firstExecutionRunID: String,
            retryPolicy: RetryPolicy? = nil,
            attempt: Int,
            workflowExecutionExpirationTime: Date? = nil,
            cronSchedule: String? = nil,
            firstWorkflowTaskBackoff: Duration? = nil,
            memo: [String: TemporalPayload] = [:],
            searchAttributes: SearchAttributeCollection,
            prevAutoResetPoints: [ResetPoint] = [],
            headers: [String: TemporalPayload] = [:],
            parentInitiatedEventVersion: Int? = nil,
            workflowID: String,
            sourceVersionStamp: WorkerVersionStamp? = nil,
            completionCallbacks: [Callback] = [],
            rootWorkflowExecution: WorkflowExecutionID? = nil,
            inheritedBuildID: String? = nil,
            versioningOverride: VersioningOverride? = nil,
            parentPinnedWorkerDeploymentVersion: String? = nil,
            priority: Priority? = nil
        ) {
            self.workflowType = workflowType
            self.parentWorkflowNamespace = parentWorkflowNamespace
            self.parentWorkflowNamespaceID = parentWorkflowNamespaceID
            self.parentWorkflowExecution = parentWorkflowExecution
            self.parentInitiatedEventID = parentInitiatedEventID
            self.taskQueue = taskQueue
            self.input = input
            self.workflowExecutionTimeout = workflowExecutionTimeout
            self.workflowRunTimeout = workflowRunTimeout
            self.workflowTaskTimeout = workflowTaskTimeout
            self.continuedExecutionRunID = continuedExecutionRunID
            self.initiator = initiator
            self.continuedFailure = continuedFailure
            self.lastCompletionResult = lastCompletionResult
            self.originalExecutionRunID = originalExecutionRunID
            self.identity = identity
            self.firstExecutionRunID = firstExecutionRunID
            self.retryPolicy = retryPolicy
            self.attempt = attempt
            self.workflowExecutionExpirationTime = workflowExecutionExpirationTime
            self.cronSchedule = cronSchedule
            self.firstWorkflowTaskBackoff = firstWorkflowTaskBackoff
            self.memo = memo
            self.searchAttributes = searchAttributes
            self.prevAutoResetPoints = prevAutoResetPoints
            self.headers = headers
            self.parentInitiatedEventVersion = parentInitiatedEventVersion
            self.workflowID = workflowID
            self.sourceVersionStamp = sourceVersionStamp
            self.completionCallbacks = completionCallbacks
            self.rootWorkflowExecution = rootWorkflowExecution
            self.inheritedBuildID = inheritedBuildID
            self.versioningOverride = versioningOverride
            self.parentPinnedWorkerDeploymentVersion = parentPinnedWorkerDeploymentVersion
            self.priority = priority
        }
    }
}
