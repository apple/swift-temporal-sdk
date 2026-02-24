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
    /// Sends a signal to a running workflow to modify its behavior or provide external input.
    ///
    /// Workflow signals provide a mechanism to send data and commands to running workflows
    /// from external systems. Unlike queries, signals can modify workflow state and trigger
    /// workflow logic changes. Signals are durable, reliable, and maintain workflow execution
    /// consistency by being processed as part of the workflow's event history.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID to signal. If nil, signals the latest run.
    ///   - signalName: The name of the signal handler defined in the workflow.
    ///   - headers: Custom headers for tracing, authentication, or signal context.
    ///   - input: The input parameters to pass to the signal handler.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails.
    public func signalWorkflow<each Input: Sendable>(
        workflowID: String,
        runID: String? = nil,
        signalName: String,
        headers: [String: Api.Common.V1.Payload] = [:],
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) async throws {
        let dataConverter = self.configuration.dataConverter
        let inputPayloads = try await dataConverter.convertValues(repeat each input)

        var request = Api.Workflowservice.V1.SignalWorkflowExecutionRequest.with {
            $0.namespace = self.configuration.namespace
            $0.workflowExecution.workflowID = workflowID
            $0.identity = self.configuration.identity
            $0.signalName = signalName
            $0.requestID = UUID().uuidString
            $0.input = .with {
                $0.payloads = inputPayloads
            }

            if let runID {
                $0.workflowExecution.runID = runID
            }
        }

        if !headers.isEmpty {
            request.header = try await .init(headers, with: dataConverter.payloadCodec)
        }

        // The response is an empty struct so we can ignore it.
        try await self.client.unary(
            method: Api.Workflowservice.V1.WorkflowService.Method.SignalWorkflowExecution.descriptor,
            request: request,
            callOptions: callOptions
        )
    }

    /// Sends a strongly-typed signal to a running workflow using a signal definition.
    ///
    /// This convenience method provides type-safe workflow signaling using a
    /// ``WorkflowSignalDefinition`` that encapsulates the signal name and input type.
    /// This approach ensures compile-time type safety and reduces the possibility
    /// of runtime type conversion errors.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID to signal. If nil, signals the latest run.
    ///   - signalType: The ``WorkflowSignalDefinition`` type that defines the signal contract.
    ///   - headers: Custom headers for tracing, authentication, or signal context.
    ///   - input: The input parameter matching the signal definition's `Input` type.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails.
    public func signalWorkflow<Signal: WorkflowSignalDefinition>(
        workflowID: String,
        runID: String? = nil,
        signalType: Signal.Type = Signal.self,
        headers: [String: Api.Common.V1.Payload] = [:],
        input: Signal.Input,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.signalWorkflow(
            workflowID: workflowID,
            runID: runID,
            signalName: Signal.name,
            headers: headers,
            input: input,
            callOptions: callOptions
        )
    }

    /// Sends a strongly-typed signal to a running workflow that requires no input parameters.
    ///
    /// This convenience method is specifically designed for signals that don't require
    /// input parameters, such as simple commands or trigger signals. It provides the
    /// same type safety benefits as the parameterized signal method while eliminating
    /// the need to pass void input values.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID to signal. If nil, signals the latest run.
    ///   - signalType: The ``WorkflowSignalDefinition`` type with `Input` constrained to `Void`.
    ///   - headers: Custom headers for tracing, authentication, or signal context.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails.
    public func signalWorkflow<Signal: WorkflowSignalDefinition>(
        workflowID: String,
        runID: String? = nil,
        signalType: Signal.Type = Signal.self,
        headers: [String: Api.Common.V1.Payload] = [:],
        callOptions: CallOptions? = nil
    ) async throws where Signal.Input == Void {
        try await self.signalWorkflow(
            workflowID: workflowID,
            runID: runID,
            signalName: Signal.name,
            headers: headers,
            input: (),
            callOptions: callOptions
        )
    }
}
