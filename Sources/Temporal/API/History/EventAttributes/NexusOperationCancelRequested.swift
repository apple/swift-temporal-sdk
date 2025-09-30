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
    /// Event attributes for when a Nexus operation cancellation has been requested.
    public struct NexusOperationCancelRequested: Hashable, Sendable {
        /// The id of the `NEXUS_OPERATION_SCHEDULED` event this cancel request corresponds to.
        public var scheduledEventID: Int

        /// The `WORKFLOW_TASK_COMPLETED` event that the corresponding RequestCancelNexusOperation command was reported
        /// with.
        public var workflowTaskCompletedEventID: Int

        /// Creates event attributes for when a Nexus operation cancellation has been requested.
        public init(
            scheduledEventID: Int,
            workflowTaskCompletedEventID: Int
        ) {
            self.scheduledEventID = scheduledEventID
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
        }
    }
}
