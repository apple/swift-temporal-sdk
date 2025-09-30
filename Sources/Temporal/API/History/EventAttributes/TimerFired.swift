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
    /// Event attributes for when a timer has fired.
    public struct TimerFired: Hashable, Sendable {
        /// Will match the `timer_id` from `TIMER_STARTED` event for this timer.
        public var timerID: String

        /// The id of the `TIMER_STARTED` event itself.
        public var startedEventID: Int

        /// Creates event attributes for when a timer has fired.
        public init(
            timerID: String,
            startedEventID: Int
        ) {
            self.timerID = timerID
            self.startedEventID = startedEventID
        }
    }
}
