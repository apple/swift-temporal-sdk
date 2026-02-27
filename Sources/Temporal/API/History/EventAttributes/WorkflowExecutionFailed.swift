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
    /// Event attributes for when a workflow execution has failed.
    public struct WorkflowExecutionFailed: Hashable, Sendable {
        /// Serialized result of workflow failure (ex: An exception thrown, or error returned).
        public var failure: Api.Failure.V1.Failure

        public var retryState: RetryState

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// If another run is started by cron or retry, this contains the new run id.
        public var newExecutionRunID: String?

        public init(
            failure: Api.Failure.V1.Failure,
            retryState: RetryState,
            workflowTaskCompletedEventID: Int,
            newExecutionRunID: String? = nil
        ) {
            self.failure = failure
            self.retryState = retryState
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.newExecutionRunID = newExecutionRunID
        }
    }
}
