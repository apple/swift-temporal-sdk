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
    /// Event attributes for when an activity task cancel has been requested.
    public struct ActivityTaskCancelRequested: Hashable, Sendable {
        /// The id of the `ACTIVITY_TASK_SCHEDULED` event this cancel request corresponds to.
        public var scheduledEventID: Int

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Creates event attributes for when an activity task cancel has been requested.
        public init(
            scheduledEventID: Int,
            workflowTaskCompletedEventID: Int
        ) {
            self.scheduledEventID = scheduledEventID
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
        }
    }
}
