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
    /// Event attributes for when a Nexus operation has timed out.
    public struct NexusOperationTimedOut: Hashable, Sendable {
        /// The ID of the `NEXUS_OPERATION_SCHEDULED` event.
        ///
        /// Uniquely identifies this operation.
        public var scheduledEventID: Int

        /// Failure details.
        ///
        /// A NexusOperationFailureInfo wrapping a CanceledFailureInfo.
        public var failure: TemporalFailure

        /// The request ID allocated at schedule time.
        public var requestID: String

        /// Creates event attributes for when a Nexus operation has timed out.
        public init(
            scheduledEventID: Int,
            failure: TemporalFailure,
            requestID: String
        ) {
            self.scheduledEventID = scheduledEventID
            self.failure = failure
            self.requestID = requestID
        }
    }
}
