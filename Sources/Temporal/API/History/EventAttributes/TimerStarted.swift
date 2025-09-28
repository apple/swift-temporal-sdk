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
    /// Event attributes for when a timer has started.
    public struct TimerStarted: Hashable, Sendable {
        /// The worker/user assigned id for this timer.
        public var timerID: String

        /// How long until this timer fires.
        public var startToFireTimeout: Duration

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Creates event attributes for when a timer has started.
        public init(
            timerID: String,
            startToFireTimeout: Duration,
            workflowTaskCompletedEventID: Int
        ) {
            self.timerID = timerID
            self.startToFireTimeout = startToFireTimeout
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
        }
    }
}
