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
    /// Event attributes for when workflow properties have been modified externally.
    public struct WorkflowPropertiesModifiedExternally: Hashable, Sendable {
        /// Not used.
        public var newTaskQueue: String?

        /// Not used.
        public var newWorkflowTaskTimeout: Duration?

        /// Not used.
        public var newWorkflowRunTimeout: Duration?

        /// Not used.
        public var newWorkflowExecutionTimeout: Duration?

        /// Not used.
        public var upsertedMemo: [String: TemporalPayload]

        /// Creates event attributes for when workflow properties have been modified externally.
        public init(
            newTaskQueue: String? = nil,
            newWorkflowTaskTimeout: Duration? = nil,
            newWorkflowRunTimeout: Duration? = nil,
            newWorkflowExecutionTimeout: Duration? = nil,
            upsertedMemo: [String: TemporalPayload] = [:]
        ) {
            self.newTaskQueue = newTaskQueue
            self.newWorkflowTaskTimeout = newWorkflowTaskTimeout
            self.newWorkflowRunTimeout = newWorkflowRunTimeout
            self.newWorkflowExecutionTimeout = newWorkflowExecutionTimeout
            self.upsertedMemo = upsertedMemo
        }
    }
}
