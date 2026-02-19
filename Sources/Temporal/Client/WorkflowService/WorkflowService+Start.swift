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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.WorkflowService {
    /// Starts a new workflow execution with the specified name and configuration.
    ///
    /// This method initiates a new workflow execution by creating a workflow instance
    /// with the provided parameters and options. The workflow will be queued for
    /// execution on the specified task queue and will begin processing according
    /// to its implementation logic.
    ///
    /// - Parameters:
    ///   - name: The registered name of the workflow type to execute.
    ///   - options: Configuration options controlling workflow execution behavior, timeouts, and policies.
    ///   - headers: Custom headers for tracing, authentication, or workflow context.
    ///   - input: The input parameters to pass to the workflow's execution method.
    /// - Returns: The unique run ID of the started workflow execution for tracking and operations.
    /// - Throws: ``WorkflowAlreadyStartedError`` if a workflow with the same ID is already
    /// running (depending on ID reuse policy), or an error for other startup failures.
    public func startWorkflow<each Input: Sendable>(
        name: String,
        options: WorkflowOptions,
        headers: [String: TemporalPayload] = [:],
        input: repeat each Input
    ) async throws -> String {
        let response: Api.Workflowservice.V1.StartWorkflowExecutionResponse = try await self.client.unary(
            method: Api.Workflowservice.V1.WorkflowService.Method.StartWorkflowExecution.descriptor,
            request: Api.Workflowservice.V1.StartWorkflowExecutionRequest(
                namespace: self.configuration.namespace,
                identity: self.configuration.identity,
                requestID: UUID().uuidString,
                workflowTypeName: name,
                workflowOptions: options,
                dataConverter: self.configuration.dataConverter,
                headers: headers,
                inputs: self.configuration.dataConverter.convertValues(repeat each input)
            ),
            callOptions: options.callOptions
        )

        return response.runID
    }

    /// Starts a new strongly-typed workflow execution using a workflow definition.
    ///
    /// This convenience method provides type-safe workflow starting using a
    /// ``WorkflowDefinition`` that encapsulates the workflow name and input type.
    /// This approach ensures compile-time type safety and reduces the possibility
    /// of runtime type conversion errors while providing automatic workflow
    /// name resolution.
    ///
    /// - Parameters:
    ///   - type: The ``WorkflowDefinition`` type that defines the workflow contract and input type.
    ///   - options: Configuration options controlling workflow execution behavior, timeouts, and policies.
    ///   - headers: Custom headers for tracing, authentication, or workflow context.
    ///   - input: The input parameter matching the workflow definition's `Input` type.
    /// - Returns: The unique run ID of the started workflow execution for tracking and operations.
    /// - Throws: ``WorkflowAlreadyStartedError`` if a workflow with the same ID is already
    /// running (depending on ID reuse policy), or an error for other startup failures.
    public func startWorkflow<Workflow: WorkflowDefinition>(
        type: Workflow.Type = Workflow.self,
        options: WorkflowOptions,
        headers: [String: TemporalPayload] = [:],
        input: Workflow.Input
    ) async throws -> String {
        try await self.startWorkflow(
            name: type.name,
            options: options,
            headers: headers,
            input: input
        )
    }

    /// Starts a new strongly-typed workflow execution that requires no input parameters.
    ///
    /// This convenience method is specifically designed for workflows that don't require
    /// input parameters. It provides the same type safety benefits as the parameterized
    /// workflow method while eliminating the need to pass void input values.
    ///
    /// - Parameters:
    ///   - type: The ``WorkflowDefinition`` type with `Input` constrained to `Void`.
    ///   - options: Configuration options controlling workflow execution behavior, timeouts, and policies.
    ///   - headers: Custom headers for tracing, authentication, or workflow context.
    /// - Returns: The unique run ID of the started workflow execution for tracking and operations.
    /// - Throws: ``WorkflowAlreadyStartedError`` if a workflow with the same ID is already running (depending on ID reuse policy), or an error for other startup failures.
    public func startWorkflow<Workflow: WorkflowDefinition>(
        type: Workflow.Type = Workflow.self,
        options: WorkflowOptions,
        headers: [String: TemporalPayload] = [:]
    ) async throws -> String where Workflow.Input == Void {
        try await self.startWorkflow(
            name: type.name,
            options: options,
            headers: headers
        )
    }
}
