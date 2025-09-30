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
    /// Event attributes for when a Nexus operation cancel request has failed.
    public struct NexusOperationCancelRequestFailedEventAttributes: Hashable, Sendable {
        /// The ID of the `NEXUS_OPERATION_CANCEL_REQUESTED` event.
        public var requestedEventID: Int64

        /// The `WORKFLOW_TASK_COMPLETED` event that the corresponding RequestCancelNexusOperation command was reported
        /// with.
        public var workflowTaskCompletedEventID: Int64

        /// Failure details.
        ///
        /// A NexusOperationFailureInfo wrapping a CanceledFailureInfo.
        public var failure: TemporalFailure

        /// The id of the `NEXUS_OPERATION_SCHEDULED` event this cancel request corresponds to.
        public var scheduledEventID: Int64

        /// Creates event attributes for when a Nexus operation cancel request has failed.
        public init(
            requestedEventID: Int64,
            workflowTaskCompletedEventID: Int64,
            failure: TemporalFailure,
            scheduledEventID: Int64
        ) {
            self.requestedEventID = requestedEventID
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.failure = failure
            self.scheduledEventID = scheduledEventID
        }
    }
}
