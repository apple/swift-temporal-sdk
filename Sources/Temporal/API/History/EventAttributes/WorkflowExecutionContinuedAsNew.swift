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
    /// Event attributes for when a workflow execution has continued as new.
    public struct WorkflowExecutionContinuedAsNew: Hashable, Sendable {
        /// The run ID of the new workflow started by this continue-as-new.
        public var newExecutionRunID: String

        /// The type name of the new workflow.
        public var workflowType: String

        /// The task queue for the new workflow.
        public var taskQueue: TaskQueue

        /// Input arguments for the new workflow.
        public var input: [Api.Common.V1.Payload]

        /// Timeout of a single workflow run.
        public var workflowRunTimeout: Duration?

        /// Timeout of a single workflow task.
        public var workflowTaskTimeout: Duration?

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        public var backoffStartInterval: Duration?

        /// The initiator of the continue-as-new operation.
        public var initiator: ContinueAsNewInitiator

        /// The failure from the previous execution if it failed.
        /// - Note: Deprecated - When supported by the server the final event will be `WorkflowExecutionFailed` with `newExecutionRunID` set.
        public var failure: Api.Failure.V1.Failure?

        public var lastCompletionResult: [Api.Common.V1.Payload]

        /// Headers for the new workflow.
        public var headers: [String: Api.Common.V1.Payload]

        /// Memo data for the new workflow.
        public var memo: [String: Api.Common.V1.Payload]

        /// Search attributes for the new workflow.
        public var searchAttributes: SearchAttributeCollection

        /// If this is set, the new execution inherits the Build ID of the current execution.
        ///
        /// Otherwise, the assignment rules will be used to independently assign a Build ID to the new execution.
        public var inheritBuildID: Bool

        public init(
            newExecutionRunID: String,
            workflowType: String,
            taskQueue: TaskQueue,
            input: [Api.Common.V1.Payload],
            workflowRunTimeout: Duration? = nil,
            workflowTaskTimeout: Duration? = nil,
            workflowTaskCompletedEventID: Int,
            backoffStartInterval: Duration? = nil,
            initiator: ContinueAsNewInitiator,
            failure: Api.Failure.V1.Failure? = nil,
            lastCompletionResult: [Api.Common.V1.Payload],
            headers: [String: Api.Common.V1.Payload] = [:],
            memo: [String: Api.Common.V1.Payload] = [:],
            searchAttributes: SearchAttributeCollection,
            inheritBuildID: Bool
        ) {
            self.newExecutionRunID = newExecutionRunID
            self.workflowType = workflowType
            self.taskQueue = taskQueue
            self.input = input
            self.workflowRunTimeout = workflowRunTimeout
            self.workflowTaskTimeout = workflowTaskTimeout
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.backoffStartInterval = backoffStartInterval
            self.initiator = initiator
            self.failure = failure
            self.lastCompletionResult = lastCompletionResult
            self.headers = headers
            self.memo = memo
            self.searchAttributes = searchAttributes
            self.inheritBuildID = inheritBuildID
        }
    }
}
