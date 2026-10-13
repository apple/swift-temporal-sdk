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

import GRPCProtobuf
import SwiftProtobuf

import struct GRPCCore.CallOptions
import struct GRPCCore.RPCError

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
    /// running (depending on the ID conflict policy) or has already finished (depending on the
    /// ID reuse policy), or an error for other startup failures.
    public func startWorkflow<each Input: Sendable>(
        name: String,
        options: WorkflowOptions,
        headers: [String: Api.Common.V1.Payload] = [:],
        input: repeat each Input
    ) async throws -> String {
        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: self.configuration.namespace,
            identity: self.configuration.identity,
            requestID: UUID().uuidString,
            workflowTypeName: name,
            workflowOptions: options,
            dataConverter: self.configuration.dataConverter,
            headers: headers,
            inputs: self.configuration.dataConverter.convertValues(repeat each input)
        )

        let response: Api.Workflowservice.V1.StartWorkflowExecutionResponse
        do {
            response = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.StartWorkflowExecution.descriptor,
                request: request,
                callOptions: options.callOptions
            )
        } catch let error as RPCError {
            if let alreadyStartedError = WorkflowAlreadyStartedError(error, workflowID: options.id, workflowName: name) {
                throw alreadyStartedError
            }
            throw error
        }

        return response.runID
    }

    /// Starts a new workflow execution or signals an existing one atomically.
    ///
    /// This method uses the `SignalWithStartWorkflowExecution` RPC to atomically start a workflow
    /// (if not already running) and send a signal to it. If the workflow is already running,
    /// only the signal is delivered.
    ///
    /// - Parameters:
    ///   - name: The registered name of the workflow type to execute.
    ///   - options: Configuration options controlling workflow execution behavior, timeouts, and policies.
    ///   - headers: Custom headers for tracing, authentication, or workflow context.
    ///   - signalName: The name of the signal to send.
    ///   - signalInput: The input data to send with the signal.
    ///   - input: The input parameters to pass to the workflow's execution method.
    /// - Returns: The unique run ID of the workflow execution.
    /// - Throws: ``WorkflowAlreadyStartedError`` if a workflow with the same ID has already
    /// finished and the ID reuse policy rejects the start, or an error for other failures.
    func signalWithStartWorkflow<each Input: Sendable>(
        name: String,
        options: WorkflowOptions,
        headers: [String: Api.Common.V1.Payload] = [:],
        signalName: String,
        signalInput: [any Sendable],
        input: repeat each Input
    ) async throws -> String {
        let dataConverter = self.configuration.dataConverter

        var signalPayloads = [Api.Common.V1.Payload]()
        signalPayloads.reserveCapacity(signalInput.count)
        for input in signalInput {
            try await signalPayloads.append(dataConverter.convertValue(input))
        }

        let request = try await Api.Workflowservice.V1.SignalWithStartWorkflowExecutionRequest(
            namespace: self.configuration.namespace,
            identity: self.configuration.identity,
            requestID: UUID().uuidString,
            workflowTypeName: name,
            workflowOptions: options,
            dataConverter: dataConverter,
            headers: headers,
            inputs: dataConverter.convertValues(repeat each input),
            signalName: signalName,
            signalInput: signalPayloads
        )

        let response: Api.Workflowservice.V1.SignalWithStartWorkflowExecutionResponse
        do {
            response = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.SignalWithStartWorkflowExecution.descriptor,
                request: request,
                callOptions: options.callOptions
            )
        } catch let error as RPCError {
            if let alreadyStartedError = WorkflowAlreadyStartedError(error, workflowID: options.id, workflowName: name) {
                throw alreadyStartedError
            }
            throw error
        }

        return response.runID
    }

    /// Starts a new workflow execution or signals an existing one atomically,
    /// using already-serialized signal payloads.
    ///
    /// This variant is used by the interceptor chain where signal arguments have already been
    /// converted to payloads before entering the chain.
    ///
    /// - Parameters:
    ///   - name: The registered name of the workflow type to execute.
    ///   - options: Configuration options controlling workflow execution behavior, timeouts, and policies.
    ///   - headers: Custom headers for tracing, authentication, or workflow context.
    ///   - signalName: The name of the signal to send.
    ///   - signalPayloads: The already-serialized signal input data.
    ///   - input: The input parameters to pass to the workflow's execution method.
    /// - Returns: The unique run ID of the workflow execution.
    /// - Throws: ``WorkflowAlreadyStartedError`` if a workflow with the same ID has already
    /// finished and the ID reuse policy rejects the start, or an error for other failures.
    func signalWithStartWorkflow<each Input: Sendable>(
        name: String,
        options: WorkflowOptions,
        headers: [String: Api.Common.V1.Payload] = [:],
        signalName: String,
        signalPayloads: [Api.Common.V1.Payload],
        input: repeat each Input
    ) async throws -> String {
        let dataConverter = self.configuration.dataConverter

        let request = try await Api.Workflowservice.V1.SignalWithStartWorkflowExecutionRequest(
            namespace: self.configuration.namespace,
            identity: self.configuration.identity,
            requestID: UUID().uuidString,
            workflowTypeName: name,
            workflowOptions: options,
            dataConverter: dataConverter,
            headers: headers,
            inputs: dataConverter.convertValues(repeat each input),
            signalName: signalName,
            signalInput: signalPayloads
        )

        let response: Api.Workflowservice.V1.SignalWithStartWorkflowExecutionResponse
        do {
            response = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.SignalWithStartWorkflowExecution.descriptor,
                request: request,
                callOptions: options.callOptions
            )
        } catch let error as RPCError {
            if let alreadyStartedError = WorkflowAlreadyStartedError(error, workflowID: options.id, workflowName: name) {
                throw alreadyStartedError
            }
            throw error
        }

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
    /// running (depending on the ID conflict policy) or has already finished (depending on the
    /// ID reuse policy), or an error for other startup failures.
    public func startWorkflow<Workflow: WorkflowDefinition>(
        type: Workflow.Type = Workflow.self,
        options: WorkflowOptions,
        headers: [String: Api.Common.V1.Payload] = [:],
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
    /// - Throws: ``WorkflowAlreadyStartedError`` if a workflow with the same ID is already
    /// running (depending on the ID conflict policy) or has already finished (depending on the
    /// ID reuse policy), or an error for other startup failures.
    public func startWorkflow<Workflow: WorkflowDefinition>(
        type: Workflow.Type = Workflow.self,
        options: WorkflowOptions,
        headers: [String: Api.Common.V1.Payload] = [:]
    ) async throws -> String where Workflow.Input == Void {
        try await self.startWorkflow(
            name: type.name,
            options: options,
            headers: headers
        )
    }
}

extension WorkflowAlreadyStartedError {
    /// Creates a workflow-already-started error from an RPC error returned by the server.
    ///
    /// The server reports a rejected workflow start with an `ALREADY_EXISTS` status carrying a
    /// `WorkflowExecutionAlreadyStartedFailure` detail. This is the case both when a workflow with
    /// the same ID is still running and when it has already finished but the ID reuse policy
    /// rejects the start.
    ///
    /// - Returns: `nil` if the RPC error isn't a workflow-already-started failure.
    init?(_ error: RPCError, workflowID: String, workflowName: String) {
        guard error.code == .alreadyExists,
            let status = try? error.unpackGoogleRPCStatus(),
            let failure = status.details.lazy.compactMap({ detail in
                detail.any.flatMap { try? Api.Errordetails.V1.WorkflowExecutionAlreadyStartedFailure(unpackingAny: $0) }
            }).first
        else {
            return nil
        }

        self.init(
            cause: error,
            workflowID: workflowID,
            runID: failure.runID.isEmpty ? nil : failure.runID,
            workflowName: workflowName
        )
        self.message = error.message
    }
}
