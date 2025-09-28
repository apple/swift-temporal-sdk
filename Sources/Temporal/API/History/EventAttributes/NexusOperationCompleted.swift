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
    /// Event attributes for when a Nexus operation has completed successfully.
    public struct NexusOperationCompleted: Hashable, Sendable {
        /// The ID of the `NEXUS_OPERATION_SCHEDULED` event.
        ///
        /// Uniquely identifies this operation.
        public var scheduledEventID: Int

        /// Serialized result of the Nexus operation.
        ///
        /// The response of the Nexus handler. Delivered either via a completion callback or as a response to a synchronous operation.
        public var result: TemporalPayload

        /// The request ID allocated at schedule time.
        public var requestID: String

        /// Creates event attributes for when a Nexus operation has completed successfully.
        public init(
            scheduledEventID: Int,
            result: TemporalPayload,
            requestID: String
        ) {
            self.scheduledEventID = scheduledEventID
            self.result = result
            self.requestID = requestID
        }
    }
}
