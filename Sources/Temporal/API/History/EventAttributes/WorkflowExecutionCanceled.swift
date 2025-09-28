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
    /// Event attributes for when a workflow execution has been canceled.
    public struct WorkflowExecutionCanceled: Hashable, Sendable {
        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Details provided when the workflow was canceled.
        public var details: [TemporalPayload]

        /// Creates event attributes for when a workflow execution has been canceled.
        public init(
            workflowTaskCompletedEventID: Int,
            details: [TemporalPayload]
        ) {
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.details = details
        }
    }
}
