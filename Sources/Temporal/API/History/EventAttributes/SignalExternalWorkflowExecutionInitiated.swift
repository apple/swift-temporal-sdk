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
    /// Event attributes for when a signal to an external workflow execution has been initiated.
    public struct SignalExternalWorkflowExecutionInitiated: Hashable, Sendable {
        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Namespace of the to-be-signalled workflow.
        ///
        /// SDKs and UI tools should use `namespace` field but server must use `namespace_id` only.
        public var namespace: String

        /// The namespace ID of the workflow to be signaled.
        public var namespaceID: String

        /// The workflow execution identifier of the workflow to be signaled.
        public var workflowExecution: WorkflowExecutionID

        /// Name / type of the signal to fire in the external workflow.
        public var signalName: String

        /// Serialized arguments to provide to the signal handler.
        public var input: [TemporalPayload]

        /// - Note: Deprecated - This field is no longer used.
        public var control: String?

        /// Workers are expected to set this to true if the workflow they are requesting to cancel is a child of the workflow which issued the request.
        public var childWorkflowOnly: Bool

        /// Headers to pass with the signal.
        public var headers: [String: TemporalPayload]

        /// Creates event attributes for when a signal to an external workflow execution has been initiated.
        public init(
            workflowTaskCompletedEventID: Int,
            namespace: String,
            namespaceID: String,
            workflowExecution: WorkflowExecutionID,
            signalName: String,
            input: [TemporalPayload],
            control: String? = nil,
            childWorkflowOnly: Bool,
            headers: [String: TemporalPayload] = [:]
        ) {
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.namespace = namespace
            self.namespaceID = namespaceID
            self.workflowExecution = workflowExecution
            self.signalName = signalName
            self.input = input
            self.control = control
            self.childWorkflowOnly = childWorkflowOnly
            self.headers = headers
        }
    }
}
