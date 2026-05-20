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

/// Input structure containing parameters and context for workflow query handling in interceptor chains.
public struct HandleQueryInput<Query: WorkflowQueryDefinition>: Sendable {
    /// Information about the current workflow execution.
    public var info: WorkflowInfo

    /// The unique identifier for this specific query request.
    ///
    /// The query ID provides a unique identifier for individual query requests,
    /// enabling request tracking, correlation, and debugging. Each query request
    /// receives a distinct ID regardless of query type or content.
    public var id: String

    /// The name identifying the type of query being executed.
    public var name: String

    /// The query definition containing type information and execution metadata.
    public var definition: Query

    /// Headers containing metadata and context information for query execution.
    public var headers: [String: Api.Common.V1.Payload]

    /// The input parameters to be passed to the query handler for execution.
    public var input: Query.Input

    /// Creates a new handle query input.
    ///
    /// - Parameters:
    ///   - info: Information about the current workflow execution.
    ///   - id: The unique identifier for this specific query request.
    ///   - name: The name identifying the type of query being executed.
    ///   - definition: The query definition containing type information and execution metadata.
    ///   - headers: Headers containing metadata and context information for query execution.
    ///   - input: The input parameters to be passed to the query handler for execution.
    public init(
        info: WorkflowInfo,
        id: String,
        name: String,
        definition: Query,
        headers: [String: Api.Common.V1.Payload],
        input: Query.Input
    ) {
        self.info = info
        self.id = id
        self.name = name
        self.definition = definition
        self.headers = headers
        self.input = input
    }
}
