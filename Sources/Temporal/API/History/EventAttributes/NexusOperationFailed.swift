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
    /// Event attributes for when a Nexus operation has failed.
    public struct NexusOperationFailed: Hashable, Sendable {
        /// The ID of the `NEXUS_OPERATION_SCHEDULED` event.
        ///
        /// Uniquely identifies this operation.
        public var scheduledEventID: Int

        /// Failure details.
        ///
        /// A NexusOperationFailureInfo wrapping an ApplicationFailureInfo.
        public var failure: Api.Failure.V1.Failure

        /// The request ID allocated at schedule time.
        public var requestID: String

        /// Creates event attributes for when a Nexus operation has failed.
        public init(
            scheduledEventID: Int,
            failure: Api.Failure.V1.Failure,
            requestID: String
        ) {
            self.scheduledEventID = scheduledEventID
            self.failure = failure
            self.requestID = requestID
        }
    }
}
