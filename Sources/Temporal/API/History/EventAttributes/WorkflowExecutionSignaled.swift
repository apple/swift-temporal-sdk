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
    /// Event attributes for when a workflow execution has been signaled.
    public struct WorkflowExecutionSignaled: Hashable, Sendable {
        /// The name/type of the signal to fire.
        public var signalName: String

        /// Will be deserialized and provided as argument(s) to the signal handler.
        public var input: [TemporalPayload]

        /// id of the worker/client who sent this signal.
        public var identity: String?

        /// Headers that were passed by the sender of the signal and copied by temporal
        /// server into the workflow task.
        public var headers: [String: TemporalPayload]

        /// - Note: Deprecated - This field is deprecated and never respected. It should always be set to false.
        public var skipGenerateWorkflowTask: Bool

        /// When signal origin is a workflow execution, this field is set.
        public var externalWorkflowExecution: WorkflowExecutionID

        /// Creates event attributes for when a workflow execution has been signaled.
        public init(
            signalName: String,
            input: [TemporalPayload],
            identity: String? = nil,
            headers: [String: TemporalPayload],
            skipGenerateWorkflowTask: Bool,
            externalWorkflowExecution: WorkflowExecutionID
        ) {
            self.signalName = signalName
            self.input = input
            self.identity = identity
            self.headers = headers
            self.skipGenerateWorkflowTask = skipGenerateWorkflowTask
            self.externalWorkflowExecution = externalWorkflowExecution
        }
    }
}
