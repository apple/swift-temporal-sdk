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
    /// Event attributes for when a workflow execution cancel has been requested.
    public struct WorkflowExecutionCancelRequested: Hashable, Sendable {
        /// User provided reason for requesting cancellation.
        public var cause: String?

        public var externalInitiatedEventID: Int

        /// The workflow execution that initiated the cancel request.
        public var externalWorkflowExecution: WorkflowExecutionID

        /// id of the worker or client who requested this cancel.
        public var identity: String?

        /// Creates event attributes for when a workflow execution cancel has been requested.
        public init(
            cause: String? = nil,
            externalInitiatedEventID: Int,
            externalWorkflowExecution: WorkflowExecutionID,
            identity: String? = nil
        ) {
            self.cause = cause
            self.externalInitiatedEventID = externalInitiatedEventID
            self.externalWorkflowExecution = externalWorkflowExecution
            self.identity = identity
        }
    }
}
