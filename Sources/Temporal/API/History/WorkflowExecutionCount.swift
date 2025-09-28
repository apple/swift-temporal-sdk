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

/// A description of the count of workflow executions matching a query.
public struct WorkflowExecutionCount: Sendable {
    /// The approximate number of workflow executions matching the query.
    public let count: Int

    /// The groups if the query had a group-by clause.
    public let groups: [AggregationGroup]

    /// An aggregation group for queries with a group-by clause.
    public struct AggregationGroup: Sendable {
        /// The approximate number of workflow executions matching the original query for this group.
        public let count: Int

        /// The search attribute values for this group.
        public let values: [any Sendable]

        public init(count: Int, values: [any Sendable]) {
            self.count = count
            self.values = values
        }
    }

    public init(count: Int, groups: [AggregationGroup]) {
        self.count = count
        self.groups = groups
    }
}
