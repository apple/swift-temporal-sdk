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
    /// Event attributes for when workflow properties have been modified.
    public struct WorkflowPropertiesModified: Hashable, Sendable {
        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// If set, update the workflow memo with the provided values.
        ///
        /// The values will be merged with the existing memo. If the user wants to delete values, a default/empty Payload should be used as the value for the key being deleted.
        public var upsertedMemo: [String: TemporalPayload]

        /// Creates event attributes for when workflow properties have been modified.
        public init(
            workflowTaskCompletedEventID: Int,
            upsertedMemo: [String: TemporalPayload]
        ) {
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.upsertedMemo = upsertedMemo
        }
    }
}
