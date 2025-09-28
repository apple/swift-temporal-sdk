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
    /// Event marking an asynchronous operation was started by the responding Nexus handler.
    ///
    /// If the operation completes synchronously, this event is not generated.
    /// In rare situations, such as request timeouts, the service may fail to record the actual start time and will fabricate this event upon receiving the operation completion via callback.
    public struct NexusOperationStarted: Hashable, Sendable {
        /// The ID of the `NEXUS_OPERATION_SCHEDULED` event this task corresponds to.
        public var scheduledEventID: Int

        /// The operation ID returned by the Nexus handler in the response to the StartOperation request.
        ///
        /// This ID is used when canceling the operation.
        /// - Note: Deprecated - Use `operationToken` instead.
        public var operationID: String

        /// The request ID allocated at schedule time.
        public var requestID: String

        /// The operation token returned by the Nexus handler in the response to the StartOperation request.
        ///
        /// This token is used when canceling the operation.
        public var operationToken: String

        /// Creates event attributes for when a Nexus operation has started.
        public init(
            scheduledEventID: Int,
            operationID: String,
            requestID: String,
            operationToken: String
        ) {
            self.scheduledEventID = scheduledEventID
            self.operationID = operationID
            self.requestID = requestID
            self.operationToken = operationToken
        }
    }
}
