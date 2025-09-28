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
    /// Event attributes for when a workflow execution update has completed.
    public struct WorkflowExecutionUpdateCompleted: Hashable, Sendable {
        /// The metadata about this update.
        public var meta: UpdateMeta

        /// The event ID indicating the acceptance of this update.
        public var acceptedEventID: Int

        /// The outcome of executing the workflow update function.
        public var outcome: UpdateOutcome

        /// Creates event attributes for when a workflow execution update has completed.
        public init(
            meta: UpdateMeta,
            acceptedEventID: Int,
            outcome: UpdateOutcome
        ) {
            self.meta = meta
            self.acceptedEventID = acceptedEventID
            self.outcome = outcome
        }
    }
}
