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
    /// Event attributes for when activity properties have been modified externally.
    public struct ActivityPropertiesModifiedExternally: Hashable, Sendable {
        /// The id of the `ACTIVITY_TASK_SCHEDULED` event this modification corresponds to.
        public var scheduledEventID: Int

        /// If set, update the retry policy of the activity, replacing it with the specified one.
        ///
        /// The number of attempts at the activity is preserved.
        public var newRetryPolicy: RetryPolicy

        /// Creates event attributes for when activity properties have been modified externally.
        public init(
            scheduledEventID: Int,
            newRetryPolicy: RetryPolicy
        ) {
            self.scheduledEventID = scheduledEventID
            self.newRetryPolicy = newRetryPolicy
        }
    }
}
