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
    /// Event attributes for when a workflow execution has completed.
    public struct WorkflowExecutionCompleted: Hashable, Sendable {
        /// Serialized result of workflow completion (ie: The return value of the workflow function).
        public var result: [Api.Common.V1.Payload]

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// If another run is started by cron, this contains the new run id.
        public var newExecutionRunID: String?

        public init(
            result: [Api.Common.V1.Payload],
            workflowTaskCompletedEventID: Int,
            newExecutionRunID: String? = nil
        ) {
            self.result = result
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.newExecutionRunID = newExecutionRunID
        }
    }
}
