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
    /// Returns information about a specific workflow execution.
    ///
    /// This method retrieves detailed information about a workflow execution including
    /// its current status, execution history, pending activities, and metadata. The
    /// description provides a complete snapshot of the workflow's current state and
    /// execution context, making it essential for monitoring, debugging, and auditing.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the workflow to describe.
    ///   - runID: The specific run ID to describe. If nil, describes the latest run.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A ``WorkflowExecutionDescription`` containing workflow execution information.
    /// - Throws: An error if the operation fails.
    public func describeWorkflow(
        workflowID: String,
        runID: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws -> WorkflowExecutionDescription {
        let response: Api.Workflowservice.V1.DescribeWorkflowExecutionResponse = try await self.client.unary(
            method: Api.Workflowservice.V1.WorkflowService.Method.DescribeWorkflowExecution.descriptor,
            request: Api.Workflowservice.V1.DescribeWorkflowExecutionRequest.with {
                $0.namespace = configuration.namespace
                $0.execution.workflowID = workflowID
                if let runID {
                    $0.execution.runID = runID
                }
            },
            callOptions: callOptions
        )

        return try .init(response, dataConverter: configuration.dataConverter)
    }
}
