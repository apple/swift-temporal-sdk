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
    /// Event attributes for when workflow search attributes have been upserted.
    public struct UpsertWorkflowSearchAttributes: Hashable, Sendable {
        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// The search attributes to upsert.
        public var searchAttributes: SearchAttributeCollection

        /// Creates event attributes for when workflow search attributes have been upserted.
        public init(
            workflowTaskCompletedEventID: Int,
            searchAttributes: SearchAttributeCollection
        ) {
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.searchAttributes = searchAttributes
        }
    }
}
