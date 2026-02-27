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
    /// Event attributes for when an activity task has timed out.
    public struct ActivityTaskTimedOut: Hashable, Sendable {
        /// If this activity had failed, was retried, and then timed out, that failure is stored as the
        /// `cause` in here.
        public var failure: Api.Failure.V1.Failure?

        /// The id of the `ACTIVITY_TASK_SCHEDULED` event this timeout corresponds to.
        public var scheduledEventID: Int

        /// The id of the `ACTIVITY_TASK_STARTED` event this timeout corresponds to.
        public var startedEventID: Int

        /// The retry state of the timed out activity task.
        public var retryState: RetryState

        /// Creates event attributes for when an activity task has timed out.
        public init(
            failure: Api.Failure.V1.Failure? = nil,
            scheduledEventID: Int,
            startedEventID: Int,
            retryState: RetryState
        ) {
            self.failure = failure
            self.scheduledEventID = scheduledEventID
            self.startedEventID = startedEventID
            self.retryState = retryState
        }
    }
}
