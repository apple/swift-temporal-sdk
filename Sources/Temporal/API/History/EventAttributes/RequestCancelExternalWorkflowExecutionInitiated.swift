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

extension HistoryEvent.Attributes {
    /// Event attributes for when a request to cancel an external workflow execution has been initiated.
    public struct RequestCancelExternalWorkflowExecutionInitiated: Hashable, Sendable {
        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// The namespace the workflow to be cancelled lives in.
        ///
        /// SDKs and UI tools should use `namespace` field but server must use `namespace_id` only.
        public var namespace: String

        /// The namespace ID of the workflow to be cancelled.
        public var namespaceID: String

        /// The workflow execution identifier of the workflow to be cancelled.
        public var workflowExecution: WorkflowExecutionID

        /// - Note: Deprecated - This field is no longer used.
        public var control: String?

        /// Workers are expected to set this to true if the workflow they are requesting to cancel is
        /// a child of the workflow which issued the request.
        public var childWorkflowOnly: Bool

        /// Reason for requesting the cancellation.
        public var reason: String?

        /// Creates event attributes for when a request to cancel an external workflow execution has been initiated.
        public init(
            workflowTaskCompletedEventID: Int,
            namespace: String,
            namespaceID: String,
            workflowExecution: WorkflowExecutionID,
            control: String? = nil,
            childWorkflowOnly: Bool,
            reason: String? = nil
        ) {
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.namespace = namespace
            self.namespaceID = namespaceID
            self.workflowExecution = workflowExecution
            self.control = control
            self.childWorkflowOnly = childWorkflowOnly
            self.reason = reason
        }
    }
}
