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
    /// Event attributes for when a workflow execution update has been admitted.
    public struct WorkflowExecutionUpdateAdmitted: Hashable, Sendable {
        /// The update request associated with this event.
        public var request: UpdateRequest

        /// An explanation of why this event was written to history.
        public var origin: UpdateAdmittedEventOrigin

        /// Creates event attributes for when a workflow execution update has been admitted.
        public init(
            request: UpdateRequest,
            origin: UpdateAdmittedEventOrigin = .unspecified
        ) {
            self.request = request
            self.origin = origin
        }
    }
}
