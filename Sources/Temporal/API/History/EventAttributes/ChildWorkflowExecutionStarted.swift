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
    /// Event attributes for when a child workflow execution has started.
    public struct ChildWorkflowExecutionStarted: Hashable, Sendable {
        /// Namespace of the child workflow.
        ///
        /// SDKs and UI tools should use `namespace` field but server must use `namespace_id` only.
        public var namespace: String

        /// The namespace ID of the child workflow.
        public var namespaceID: String

        /// Id of the `START_CHILD_WORKFLOW_EXECUTION_INITIATED` event which this event corresponds to.
        public var initiatedEventID: Int

        /// The workflow execution identifier of the child workflow.
        public var workflowExecution: WorkflowExecutionID

        /// The type name of the child workflow.
        public var workflowType: String

        /// Headers passed to the child workflow.
        public var headers: [String: Api.Common.V1.Payload]

        /// Creates event attributes for when a child workflow execution has started.
        public init(
            namespace: String,
            namespaceID: String,
            initiatedEventID: Int,
            workflowExecution: WorkflowExecutionID,
            workflowType: String,
            headers: [String: Api.Common.V1.Payload]
        ) {
            self.namespace = namespace
            self.namespaceID = namespaceID
            self.initiatedEventID = initiatedEventID
            self.workflowExecution = workflowExecution
            self.workflowType = workflowType
            self.headers = headers
        }
    }
}
