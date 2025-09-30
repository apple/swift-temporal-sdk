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

extension HistoryEvent.Attributes {
    /// Event attributes for when a child workflow execution has been initiated.
    public struct StartChildWorkflowExecutionInitiated: Hashable, Sendable {
        /// Namespace of the child workflow.
        ///
        /// SDKs and UI tools should use `namespace` field but server must use `namespace_id` only.
        public var namespace: String

        /// The namespace ID of the child workflow.
        public var namespaceID: String

        /// The workflow ID of the child workflow.
        public var workflowID: String

        /// The type name of the child workflow.
        public var workflowType: String

        /// The task queue for the child workflow.
        public var taskQueue: TaskQueue

        /// Input arguments for the child workflow.
        public var input: [TemporalPayload]

        /// Total workflow execution timeout including retries and continue as new.
        public var workflowExecutionTimeout: Duration?

        /// Timeout of a single workflow run.
        public var workflowRunTimeout: Duration?

        /// Timeout of a single workflow task.
        public var workflowTaskTimeout: Duration?

        /// Default: PARENT_CLOSE_POLICY_TERMINATE.
        public var parentClosePolicy: ParentClosePolicy

        /// - Note: Deprecated - This field is no longer used.
        public var control: String?

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Default: WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE.
        public var workflowIDReusePolicy: WorkflowIDReusePolicy

        /// The retry policy for the child workflow.
        public var retryPolicy: RetryPolicy?

        /// If this child runs on a cron schedule, it will appear here.
        public var cronSchedule: String?

        /// Headers for the child workflow.
        public var headers: [String: TemporalPayload]

        /// Memo data for the child workflow.
        public var memo: [String: TemporalPayload]

        /// Search attributes for the child workflow.
        public var searchAttributes: SearchAttributeCollection

        /// If this is set, the child workflow inherits the Build ID of the parent.
        ///
        /// Otherwise, the assignment rules of the child's Task Queue will be used to independently assign a Build ID to it.
        public var inheritBuildID: Bool

        /// Priority metadata.
        public var priority: Priority?

        /// Creates event attributes for when a child workflow execution has been initiated.
        public init(
            namespace: String,
            namespaceID: String,
            workflowID: String,
            workflowType: String,
            taskQueue: TaskQueue,
            input: [TemporalPayload],
            workflowExecutionTimeout: Duration? = nil,
            workflowRunTimeout: Duration? = nil,
            workflowTaskTimeout: Duration? = nil,
            parentClosePolicy: ParentClosePolicy,
            control: String? = nil,
            workflowTaskCompletedEventID: Int,
            workflowIDReusePolicy: WorkflowIDReusePolicy = .unspecified,
            retryPolicy: RetryPolicy? = nil,
            cronSchedule: String?,
            headers: [String: TemporalPayload] = [:],
            memo: [String: TemporalPayload] = [:],
            searchAttributes: SearchAttributeCollection,
            inheritBuildID: Bool,
            priority: Priority? = nil
        ) {
            self.namespace = namespace
            self.namespaceID = namespaceID
            self.workflowID = workflowID
            self.workflowType = workflowType
            self.taskQueue = taskQueue
            self.input = input
            self.workflowExecutionTimeout = workflowExecutionTimeout
            self.workflowRunTimeout = workflowRunTimeout
            self.workflowTaskTimeout = workflowTaskTimeout
            self.parentClosePolicy = parentClosePolicy
            self.control = control
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.workflowIDReusePolicy = workflowIDReusePolicy
            self.retryPolicy = retryPolicy
            self.cronSchedule = cronSchedule
            self.headers = headers
            self.memo = memo
            self.searchAttributes = searchAttributes
            self.inheritBuildID = inheritBuildID
            self.priority = priority
        }
    }
}
