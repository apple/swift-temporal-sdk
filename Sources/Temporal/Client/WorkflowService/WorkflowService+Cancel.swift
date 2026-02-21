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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.WorkflowService {
    /// Cancels a running workflow execution with optional run chain validation.
    ///
    /// Workflow cancellation sends a cancellation request to the workflow, allowing it
    /// to perform cleanup operations before terminating gracefully. Unlike termination,
    /// cancellation gives the workflow an opportunity to handle the cancellation signal
    /// and complete any necessary cleanup tasks before stopping execution.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to cancel.
    ///   - runID: The specific run ID to cancel. If nil, cancels the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - callOptions: Optional call options to use when invoking the RPC.
    /// - Throws: An error if the operation fails.
    public func cancelWorkflow(
        id: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.client.unary(
            method: Api.Workflowservice.V1.WorkflowService.Method.RequestCancelWorkflowExecution.descriptor,
            request: Api.Workflowservice.V1.RequestCancelWorkflowExecutionRequest.with {
                $0.namespace = self.configuration.namespace
                $0.workflowExecution.workflowID = id
                if let runID {
                    $0.workflowExecution.runID = runID
                }
                if let firstExecutionRunID {
                    $0.firstExecutionRunID = firstExecutionRunID
                }
                $0.identity = self.configuration.identity
                $0.requestID = UUID().uuidString
            },
            callOptions: callOptions
        )
    }

    /// Terminates a workflow execution immediately without allowing cleanup.
    ///
    /// Workflow termination forcibly stops a workflow execution without giving it an
    /// opportunity to perform cleanup operations. This is a more aggressive action than
    /// cancellation and should be used when immediate shutdown is required or when a
    /// workflow is not responding to cancellation requests.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to terminate.
    ///   - runID: The specific run ID to terminate. If nil, terminates the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - reason: Human-readable reason for termination (appears in workflow history).
    ///   - details: Additional structured data providing context for the termination.
    ///   - callOptions: Optional call options to use when invoking the RPC.
    /// - Throws: An error if the operation fails.
    public func terminateWorkflow<each Detail>(
        id: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        reason: String? = nil,
        details: repeat each Detail,
        callOptions: CallOptions? = nil
    ) async throws {
        let detailPayloads = try await self.configuration.dataConverter.convertValues(repeat each details)

        try await self.client.unary(
            method: Api.Workflowservice.V1.WorkflowService.Method.TerminateWorkflowExecution.descriptor,
            request: Api.Workflowservice.V1.TerminateWorkflowExecutionRequest.with {
                $0.namespace = self.configuration.namespace
                $0.workflowExecution.workflowID = id
                if let runID {
                    $0.workflowExecution.runID = runID
                }
                if let reason {
                    $0.reason = reason
                }
                if let firstExecutionRunID {
                    $0.firstExecutionRunID = firstExecutionRunID
                }
                $0.identity = self.configuration.identity
                $0.details.payloads = detailPayloads
            },
            callOptions: callOptions
        )
    }
}
