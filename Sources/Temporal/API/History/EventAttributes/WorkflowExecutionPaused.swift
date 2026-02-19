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
    /// Event attributes for when a workflow execution was paused.
    public struct WorkflowExecutionPaused: Hashable, Sendable {
        /// The identity of the client who paused the workflow execution.
        public var identity: String?

        /// The reason for pausing the workflow execution.
        public var reason: String?

        /// The request ID of the request that paused the workflow execution.
        public var requestID: String?

        /// Creates event attributes for when a workflow execution was paused.
        public init(
            identity: String? = nil,
            reason: String? = nil,
            requestID: String? = nil
        ) {
            self.identity = identity
            self.reason = reason
            self.requestID = requestID
        }
    }
}
