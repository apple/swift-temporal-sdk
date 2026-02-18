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

import SwiftProtobuf

public import struct GRPCCore.CallOptions

extension TemporalClient.WorkflowService {
    /// Returns an async sequence of workflow executions matching the specified query.
    ///
    /// This method provides access to workflow execution data through Temporal's
    /// visibility store. It uses automatic pagination to handle large result sets and
    /// returns results as an async sequence for memory-efficient processing of potentially
    /// thousands of workflow executions.
    ///
    /// - Parameters:
    ///   - query: The visibility query to match workflow executions using Temporal's query syntax.
    ///   - limit: The maximum number of results to return. If nil, returns all matching executions.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: An async sequence of ``WorkflowExecution`` objects matching the query.
    /// - Throws: An error if the operation fails.
    public func listWorkflowExecutions(
        query: String,
        limit: Int? = nil,
        callOptions: CallOptions? = nil
    ) async throws -> some AsyncSequence<WorkflowExecution, any Error> & Sendable {
        withFlattenedPagination { pageToken in
            let response: Api.Workflowservice.V1.ListWorkflowExecutionsResponse = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.ListWorkflowExecutions.descriptor,
                request: Api.Workflowservice.V1.ListWorkflowExecutionsRequest.with {
                    $0.namespace = configuration.namespace
                    $0.query = query
                    $0.nextPageToken = pageToken
                },
                callOptions: callOptions
            )

            return (elements: response.executions, pageToken: response.nextPageToken)
        }
        .map { executionInfo in
            try WorkflowExecution(executionInfo, dataConverter: self.configuration.dataConverter)
        }
        .prefix(limit ?? .max)
    }

    /// Counts the number of workflow executions matching the specified query.
    ///
    /// This method efficiently counts workflow executions without transferring the actual
    /// execution data, making it ideal for analytics, pagination calculations, and
    /// dashboard metrics. The count operation is optimized for performance and uses
    /// the same query syntax as workflow listing operations.
    ///
    /// - Parameters:
    ///    - input: A ``CountWorkflowsInput`` containing the query parameters.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A ``WorkflowExecutionCount`` containing the total number of matching executions.
    /// - Throws: An error if the operation fails.
    public func countWorkflowExecutions(
        input: CountWorkflowsInput,
        callOptions: CallOptions? = nil
    ) async throws -> WorkflowExecutionCount {
        let rawValue: Api.Workflowservice.V1.CountWorkflowExecutionsResponse = try await self.client.unary(
            method: Api.Workflowservice.V1.WorkflowService.Method.CountWorkflowExecutions.descriptor,
            request: Api.Workflowservice.V1.CountWorkflowExecutionsRequest.with {
                $0.namespace = self.configuration.namespace
                $0.query = input.query
            },
            callOptions: callOptions
        )
        return .init(rawValue)
    }
}
