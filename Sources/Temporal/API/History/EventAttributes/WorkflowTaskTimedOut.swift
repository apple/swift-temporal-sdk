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
    /// Event attributes for when a workflow task has timed out.
    public struct WorkflowTaskTimedOut: Hashable, Sendable {
        /// The id of the `WORKFLOW_TASK_SCHEDULED` event this task corresponds to.
        public var scheduledEventID: Int

        /// The id of the `WORKFLOW_TASK_STARTED` event this task corresponds to.
        public var startedEventID: Int

        public var timeoutType: TimeoutType

        /// Creates event attributes for when a workflow task has timed out.
        public init(
            scheduledEventID: Int,
            startedEventID: Int,
            timeoutType: TimeoutType
        ) {
            self.scheduledEventID = scheduledEventID
            self.startedEventID = startedEventID
            self.timeoutType = timeoutType
        }
    }
}
