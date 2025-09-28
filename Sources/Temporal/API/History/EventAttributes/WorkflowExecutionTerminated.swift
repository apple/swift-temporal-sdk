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
    public struct WorkflowExecutionTerminated: Hashable, Sendable {
        /// User/client provided reason for termination.
        public var reason: String?

        public var details: [TemporalPayload]

        /// ID of the client who requested termination.
        public var identity: String?

        public init(
            reason: String? = nil,
            details: [TemporalPayload] = [],
            identity: String? = nil
        ) {
            self.reason = reason
            self.details = details
            self.identity = identity
        }
    }
}
