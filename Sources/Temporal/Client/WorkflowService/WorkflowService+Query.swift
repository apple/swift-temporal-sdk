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

public import GRPCCore
import SwiftProtobuf

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.WorkflowService {
    /// Queries a running workflow for information without affecting its execution state.
    ///
    /// Workflow queries provide a way to retrieve information from a running workflow
    /// without interrupting its execution or altering its state. Queries are read-only
    /// operations that can access workflow state, variables, and computed values at
    /// the current point in execution.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the workflow to query.
    ///   - runID: The specific run ID to query. If nil, queries the latest run.
    ///   - queryName: The name of the query handler defined in the workflow.
    ///   - rejectionCondition: The condition specifying when to reject queries based on workflow state. If nil, allows queries in any state.
    ///   - headers: Custom headers to include with the query request for tracing or context.
    ///   - input: The input parameters to pass to the query handler.
    ///   - resultTypes: The expected return types from the query operation.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A tuple containing the query results in the order specified by `resultTypes`.
    /// - Throws: ``WorkflowQueryRejectedError`` if the query is rejected due to workflow state, ``WorkflowQueryFailedError`` if the query execution fails, or an error for other failures.
    public func queryWorkflow<each Input: Sendable, each Result: Sendable>(
        workflowID: String,
        runID: String? = nil,
        queryName: String,
        rejectionCondition: QueryRejectionCondition? = nil,
        headers: [String: TemporalPayload] = [:],
        input: repeat each Input,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        let dataConverter = self.configuration.dataConverter
        let inputPayloads = try await dataConverter.convertValues(repeat each input)
        var request = Api.Workflowservice.V1.QueryWorkflowRequest.with {
            $0.namespace = self.configuration.namespace
            $0.execution.workflowID = workflowID
            $0.query = .with {
                $0.queryType = queryName
                $0.queryArgs = .with {
                    $0.payloads = inputPayloads.map { .init(temporalPayload: $0) }
                }
            }

            if let runID {
                $0.execution.runID = runID
            }
            if let rejectionCondition {
                $0.queryRejectCondition = .init(queryRejectionCondition: rejectionCondition)
            }
        }

        if !headers.isEmpty {
            request.query.header = try await .init(headers, with: dataConverter.payloadCodec)
        }

        let response: Api.Workflowservice.V1.QueryWorkflowResponse
        do {
            response = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.QueryWorkflow.descriptor,
                request: request,
                callOptions: callOptions
            )
        } catch let error as RPCError {
            if error.code == .invalidArgument {
                // If the status is invalidArgument we can assume it's a query failed error.
                throw WorkflowQueryFailedError(message: error.message, cause: error)
            }
            throw error
        }

        switch response.queryRejected.status {
        case .unspecified:
            let payloads = response.queryResult.payloads.map {
                TemporalPayload(temporalAPIPayload: $0)
            }
            return try await self.configuration.dataConverter.convertPayloads(
                payloads,
                as: repeat each resultTypes
            )
        case .running, .completed, .failed, .canceled, .terminated, .continuedAsNew, .timedOut, .paused, .UNRECOGNIZED:
            throw WorkflowQueryRejectedError(
                workflowExecutionStatus: .init(temporalAPIWorkflowExecutionStatus: response.queryRejected.status)
            )
        }
    }

    /// Queries a running workflow using a strongly-typed query definition.
    ///
    /// This convenience method provides type-safe workflow querying using a
    /// ``WorkflowQueryDefinition`` that encapsulates the query name, input type,
    /// and output type. This approach ensures compile-time type safety and
    /// reduces the possibility of runtime type conversion errors.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the workflow to query.
    ///   - runID: The specific run ID to query. If nil, queries the latest run.
    ///   - queryType: The ``WorkflowQueryDefinition`` type that defines the query contract.
    ///   - rejectionCondition: The condition specifying when to reject queries based on workflow state. If nil, allows queries in any state.
    ///   - headers: Custom headers to include with the query request for tracing or context.
    ///   - input: The input parameter matching the query definition's `Input` type.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The query result matching the query definition's `Output` type.
    /// - Throws: ``WorkflowQueryRejectedError`` if the query is rejected due to workflow state, ``WorkflowQueryFailedError`` if the query execution fails, or an error for other failures.
    public func queryWorkflow<Query: WorkflowQueryDefinition>(
        workflowID: String,
        runID: String? = nil,
        queryType: Query.Type = Query.self,
        rejectionCondition: QueryRejectionCondition? = nil,
        headers: [String: TemporalPayload] = [:],
        input: Query.Input,
        callOptions: CallOptions? = nil
    ) async throws -> Query.Output {
        try await self.queryWorkflow(
            workflowID: workflowID,
            runID: runID,
            queryName: Query.name,
            rejectionCondition: rejectionCondition,
            headers: headers,
            input: input,
            resultTypes: Query.Output.self,
            callOptions: callOptions
        )
    }

    /// Queries a running workflow using a strongly-typed query definition that requires no input.
    ///
    /// This convenience method is specifically designed for queries that don't require
    /// input parameters. It provides the same type safety benefits as the parameterized
    /// query method while eliminating the need to pass void input values.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the workflow to query.
    ///   - runID: The specific run ID to query. If nil, queries the latest run.
    ///   - queryType: The ``WorkflowQueryDefinition`` type with `Input` constrained to `Void`.
    ///   - rejectionCondition: The condition specifying when to reject queries based on workflow state. If nil, allows queries in any state.
    ///   - headers: Custom headers to include with the query request for tracing or context.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The query result matching the query definition's `Output` type.
    /// - Throws: ``WorkflowQueryRejectedError`` if the query is rejected due to workflow state, ``WorkflowQueryFailedError`` if the query execution fails, or an error for other failures.
    public func queryWorkflow<Query: WorkflowQueryDefinition>(
        workflowID: String,
        runID: String? = nil,
        queryType: Query.Type = Query.self,
        rejectionCondition: QueryRejectionCondition? = nil,
        headers: [String: TemporalPayload] = [:],
        callOptions: CallOptions? = nil
    ) async throws -> Query.Output where Query.Input == Void {
        try await self.queryWorkflow(
            workflowID: workflowID,
            runID: runID,
            queryName: Query.name,
            rejectionCondition: rejectionCondition,
            headers: headers,
            input: (),
            resultTypes: Query.Output.self,
            callOptions: callOptions
        )
    }
}
