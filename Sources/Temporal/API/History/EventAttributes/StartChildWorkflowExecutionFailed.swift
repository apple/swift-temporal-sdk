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
    /// Event attributes for when a child workflow execution has failed to start.
    public struct StartChildWorkflowExecutionFailed: Hashable, Sendable {
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

        /// The cause of the start failure.
        public var cause: StartChildWorkflowExecutionFailedCause

        /// - Note: Deprecated - This field is no longer used.
        public var control: String?

        /// Id of the `START_CHILD_WORKFLOW_EXECUTION_INITIATED` event which this event corresponds to.
        public var initiatedEventID: Int

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Creates event attributes for when a child workflow execution has failed to start.
        public init(
            namespace: String,
            namespaceID: String,
            workflowID: String,
            workflowType: String,
            cause: StartChildWorkflowExecutionFailedCause = .unspecified,
            control: String?,
            initiatedEventID: Int,
            workflowTaskCompletedEventID: Int
        ) {
            self.namespace = namespace
            self.namespaceID = namespaceID
            self.workflowID = workflowID
            self.workflowType = workflowType
            self.cause = cause
            self.control = control
            self.initiatedEventID = initiatedEventID
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
        }
    }
}
