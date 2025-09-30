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
    /// Event attributes for when an activity task has started.
    public struct ActivityTaskStarted: Hashable, Sendable {
        /// The id of the `ACTIVITY_TASK_SCHEDULED` event this task corresponds to.
        public var scheduledEventID: Int

        /// id of the worker that picked up this task.
        public var identity: String?

        public var requestID: String

        /// Starting at 1, the number of times this task has been attempted.
        public var attempt: Int

        /// Will be set to the most recent failure details, if this task has previously failed and then
        /// been retried.
        public var lastFailure: TemporalFailure?

        /// Version info of the worker to whom this task was dispatched.
        /// - Note: Deprecated - This field is no longer used.
        public var workerVersion: WorkerVersionStamp?

        /// Used by server internally to properly reapply build ID redirects to an execution
        /// when rebuilding it from events.
        ///
        /// - Note: Deprecated - This field is no longer used.
        public var buildIDRedirectCounter: Int

        /// Creates event attributes for when an activity task has started.
        public init(
            scheduledEventID: Int,
            identity: String? = nil,
            requestID: String,
            attempt: Int,
            lastFailure: TemporalFailure? = nil,
            workerVersion: WorkerVersionStamp? = nil,
            buildIDRedirectCounter: Int
        ) {
            self.scheduledEventID = scheduledEventID
            self.identity = identity
            self.requestID = requestID
            self.attempt = attempt
            self.lastFailure = lastFailure
            self.workerVersion = workerVersion
            self.buildIDRedirectCounter = buildIDRedirectCounter
        }
    }
}
