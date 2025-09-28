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
    /// Event attributes for when an activity task has failed.
    public struct ActivityTaskFailed: Hashable, Sendable {
        /// Failure details.
        public var failure: TemporalFailure

        /// The id of the `ACTIVITY_TASK_SCHEDULED` event this failure corresponds to.
        public var scheduledEventID: Int

        /// The id of the `ACTIVITY_TASK_STARTED` event this failure corresponds to.
        public var startedEventID: Int

        /// id of the worker that failed this task.
        public var identity: String?

        /// The retry state of the failed activity task.
        public var retryState: RetryState

        /// Version info of the worker who processed this workflow task.
        /// - Note: Deprecated - Use the info inside the corresponding ActivityTaskStartedEvent.
        public var workerVersion: WorkerVersionStamp?

        /// Creates event attributes for when an activity task has failed.
        public init(
            failure: TemporalFailure,
            scheduledEventID: Int,
            startedEventID: Int,
            identity: String? = nil,
            retryState: RetryState,
            workerVersion: WorkerVersionStamp? = nil
        ) {
            self.failure = failure
            self.scheduledEventID = scheduledEventID
            self.startedEventID = startedEventID
            self.identity = identity
            self.retryState = retryState
            self.workerVersion = workerVersion
        }
    }
}
