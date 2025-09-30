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
    /// Event attributes for when a request to cancel an external workflow execution has failed.
    public struct RequestCancelExternalWorkflowExecutionFailed: Hashable, Sendable {
        /// The cause of the cancellation failure.
        public var cause: CancelExternalWorkflowExecutionFailedCause

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Namespace of the workflow which failed to cancel.
        ///
        /// SDKs and UI tools should use `namespace` field but server must use `namespace_id` only.
        public var namespace: String

        /// The namespace ID of the workflow which failed to cancel.
        public var namespaceID: String

        /// The workflow execution identifier of the workflow which failed to cancel.
        public var workflowExecution: WorkflowExecutionID

        /// id of the `REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION_INITIATED` event this failure corresponds to.
        public var initiatedEventID: Int

        /// - Note: Deprecated - This field is no longer used.
        public var control: String?

        /// Creates event attributes for when a request to cancel an external workflow execution has failed.
        public init(
            cause: CancelExternalWorkflowExecutionFailedCause = .unspecified,
            workflowTaskCompletedEventID: Int,
            namespace: String,
            namespaceID: String,
            workflowExecution: WorkflowExecutionID,
            initiatedEventID: Int,
            control: String? = nil
        ) {
            self.cause = cause
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.namespace = namespace
            self.namespaceID = namespaceID
            self.workflowExecution = workflowExecution
            self.initiatedEventID = initiatedEventID
            self.control = control
        }
    }
}
