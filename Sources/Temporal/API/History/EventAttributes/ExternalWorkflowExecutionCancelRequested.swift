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
    /// Event attributes for when an external workflow execution cancel has been requested.
    public struct ExternalWorkflowExecutionCancelRequested: Hashable, Sendable {
        /// id of the `REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION_INITIATED` event this event corresponds to.
        public var initiatedEventID: Int

        /// Namespace of the to-be-cancelled workflow.
        ///
        /// SDKs and UI tools should use `namespace` field but server must use `namespace_id` only.
        public var namespace: String

        public var namespaceID: String

        public var workflowExecution: WorkflowExecutionID

        /// Creates event attributes for when an external workflow execution cancel has been requested.
        public init(
            initiatedEventID: Int,
            namespace: String,
            namespaceID: String,
            workflowExecution: WorkflowExecutionID
        ) {
            self.initiatedEventID = initiatedEventID
            self.namespace = namespace
            self.namespaceID = namespaceID
            self.workflowExecution = workflowExecution
        }
    }
}
