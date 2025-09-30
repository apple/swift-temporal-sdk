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
    /// Event attributes for when an external workflow execution has been signaled.
    public struct ExternalWorkflowExecutionSignaled: Hashable, Sendable {
        /// ID of the `SIGNAL_EXTERNAL_WORKFLOW_EXECUTION_INITIATED` event this event corresponds to.
        public var initiatedEventID: Int

        /// Namespace of the workflow which was signaled.
        ///
        /// SDKs and UI tools should use `namespace` field but server must use `namespace_id` only.
        public var namespace: String

        /// The namespace ID of the workflow which was signaled.
        public var namespaceID: String

        /// The workflow execution identifier of the workflow which was signaled.
        public var workflowExecution: WorkflowExecutionID

        /// - Note: Deprecated - This field is no longer used.
        public var control: String?

        /// Creates event attributes for when an external workflow execution has been signaled.
        public init(
            initiatedEventID: Int,
            namespace: String,
            namespaceID: String,
            workflowExecution: WorkflowExecutionID,
            control: String? = nil
        ) {
            self.initiatedEventID = initiatedEventID
            self.namespace = namespace
            self.namespaceID = namespaceID
            self.workflowExecution = workflowExecution
            self.control = control
        }
    }
}
