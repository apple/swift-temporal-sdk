//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

/// A single page of workflow execution results from a paginated list operation.
///
/// Use this type with ``TemporalClient/listWorkflowsPage(query:pageSize:nextPageToken:callOptions:)``
/// when you need manual control over pagination, such as implementing custom pagination UIs
/// or processing results page by page.
public struct WorkflowListPage: Sendable {
    /// The workflow executions in this page.
    public let executions: [WorkflowExecution]

    /// The token to retrieve the next page of results.
    ///
    /// Pass this value to the next call to
    /// ``TemporalClient/listWorkflowsPage(query:pageSize:nextPageToken:callOptions:)``
    /// to retrieve the next page. When empty, there are no more results.
    public let nextPageToken: Data

    /// Creates a new workflow list page.
    ///
    /// - Parameters:
    ///   - executions: The workflow executions in this page.
    ///   - nextPageToken: The token to retrieve the next page of results.
    package init(executions: [WorkflowExecution], nextPageToken: Data) {
        self.executions = executions
        self.nextPageToken = nextPageToken
    }
}
