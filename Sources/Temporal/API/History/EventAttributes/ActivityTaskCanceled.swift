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
    /// Event attributes for when an activity task has been canceled.
    public struct ActivityTaskCanceled: Hashable, Sendable {
        /// Additional information that the activity reported upon confirming cancellation.
        public var details: [Api.Common.V1.Payload]

        /// id of the most recent `ACTIVITY_TASK_CANCEL_REQUESTED` event which refers to the same activity.
        public var latestCancelRequestedEventID: Int

        /// The id of the `ACTIVITY_TASK_SCHEDULED` event this cancel confirmation corresponds to.
        public var scheduledEventID: Int

        /// The id of the `ACTIVITY_TASK_STARTED` event this cancel confirmation corresponds to.
        public var startedEventID: Int

        /// id of the worker who canceled this activity.
        public var identity: String?

        /// Version info of the worker who processed this workflow task.
        /// - Note: Deprecated - Use the info inside the corresponding ActivityTaskStartedEvent.
        public var workerVersion: WorkerVersionStamp?

        /// Creates event attributes for when an activity task has been canceled.
        public init(
            details: [Api.Common.V1.Payload],
            latestCancelRequestedEventID: Int,
            scheduledEventID: Int,
            startedEventID: Int,
            identity: String? = nil,
            workerVersion: WorkerVersionStamp? = nil
        ) {
            self.details = details
            self.latestCancelRequestedEventID = latestCancelRequestedEventID
            self.scheduledEventID = scheduledEventID
            self.startedEventID = startedEventID
            self.identity = identity
            self.workerVersion = workerVersion
        }
    }
}
