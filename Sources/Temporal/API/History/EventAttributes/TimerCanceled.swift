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
    /// Event attributes for when a timer has been canceled.
    public struct TimerCanceled: Hashable, Sendable {
        /// Will match the `timer_id` from `TIMER_STARTED` event for this timer.
        public var timerID: String

        /// The id of the `TIMER_STARTED` event itself.
        public var startedEventID: Int

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// The id of the worker who requested this cancel.
        public var identity: String?

        /// Creates event attributes for when a timer has been canceled.
        public init(
            timerID: String,
            startedEventID: Int,
            workflowTaskCompletedEventID: Int,
            identity: String? = nil
        ) {
            self.timerID = timerID
            self.startedEventID = startedEventID
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.identity = identity
        }
    }
}
