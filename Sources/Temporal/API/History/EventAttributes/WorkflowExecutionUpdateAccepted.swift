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
    /// Event attributes for when a workflow execution update has been accepted.
    public struct WorkflowExecutionUpdateAccepted: Hashable, Sendable {
        /// The instance ID of the update protocol that generated this event.
        public var protocolInstanceID: String

        /// The message ID of the original request message that initiated this update.
        ///
        /// Needed so that the worker can recreate and deliver that same message as part of replay.
        public var acceptedRequestMessageID: String

        /// The event ID used to sequence the original request message.
        public var acceptedRequestSequencingEventID: Int

        /// The message payload of the original request message that initiated this
        /// update.
        public var acceptedRequest: UpdateRequest

        /// Creates event attributes for when a workflow execution update has been accepted.
        public init(
            protocolInstanceID: String,
            acceptedRequestMessageID: String,
            acceptedRequestSequencingEventID: Int,
            acceptedRequest: UpdateRequest
        ) {
            self.protocolInstanceID = protocolInstanceID
            self.acceptedRequestMessageID = acceptedRequestMessageID
            self.acceptedRequestSequencingEventID = acceptedRequestSequencingEventID
            self.acceptedRequest = acceptedRequest
        }
    }
}
