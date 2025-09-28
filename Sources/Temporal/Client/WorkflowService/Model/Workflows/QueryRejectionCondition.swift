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

/// Describes conditions under which workflow queries should be rejected based on execution state.
public struct QueryRejectionCondition: Hashable, Sendable {
    enum Backing {
        case none
        case notOpen
        case notCompletedCleanly
    }

    let backing: Backing

    /// Allows queries to be processed regardless of workflow execution state.
    ///
    /// This condition permits queries in any workflow state, whether the workflow is running,
    /// completed, failed, or terminated. Use this when you always want to allow query access
    /// to workflow data regardless of execution status.
    public static let none = Self(backing: .none)

    /// Rejects queries when the workflow is not in an open (running) state.
    ///
    /// This condition only allows queries on workflows that are currently running and actively
    /// processing tasks. Queries will be rejected for completed, failed, cancelled, or terminated
    /// workflows. Use this when you only want to query active workflow executions.
    public static let notOpen = Self(backing: .notOpen)

    /// Rejects queries when the workflow did not complete successfully.
    ///
    /// This condition allows queries on running workflows and those that completed successfully,
    /// but rejects queries on workflows that failed, were cancelled, or were terminated.
    /// Use this when you want to avoid querying workflows that ended in an abnormal state.
    public static let notCompletedCleanly = Self(backing: .notCompletedCleanly)

    /// A string representation of the rejection condition for debugging and logging purposes.
    public var description: String {
        switch backing {
        case .none:
            return "none"
        case .notOpen:
            return "notOpen"
        case .notCompletedCleanly:
            return "notCompletedCleanly"
        }
    }
}
