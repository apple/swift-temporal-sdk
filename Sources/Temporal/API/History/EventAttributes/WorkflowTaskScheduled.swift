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
    /// Event attributes for when a workflow task has been scheduled.
    public struct WorkflowTaskScheduled: Hashable, Sendable {
        /// The task queue this workflow task was enqueued in, which could be a normal or sticky queue.
        public var taskQueue: TaskQueue

        /// How long the worker has to process this task once receiving it before it times out.
        public var startToCloseTimeout: Duration?

        /// Starting at 1, how many attempts there have been to complete this task.
        public var attempt: Int

        /// Creates event attributes for when a workflow task has been scheduled.
        public init(
            taskQueue: TaskQueue,
            startToCloseTimeout: Duration? = nil,
            attempt: Int
        ) {
            self.taskQueue = taskQueue
            self.startToCloseTimeout = startToCloseTimeout
            self.attempt = attempt
        }
    }
}
