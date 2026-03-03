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

/// A handle for interacting with an external workflow providing signaling and cancellation capabilities.
///
/// The external workflow handle allows a workflow to send signals to and cancel
/// arbitrary workflows by ID, regardless of whether they are child workflows.
///
/// - Note: For type-safe workflow interaction, prefer using ``ExternalWorkflowHandle`` when the
///   external workflow type is known at compile time.
///
/// ## Usage
///
/// ```swift
/// // Get a handle to an external workflow
/// let handle = Workflow.getExternalWorkflowHandle(id: "other-workflow-id")
///
/// // Signal the external workflow
/// try await handle.signal(
///     signalName: "mySignal",
///     input: signalData
/// )
///
/// // Cancel the external workflow
/// try await handle.cancel()
/// ```
public struct UntypedExternalWorkflowHandle: Sendable {
    /// The unique identifier of the external workflow execution.
    ///
    /// This identifier uniquely identifies the external workflow within its namespace
    /// and is used for signaling and cancellation operations.
    public let id: String

    /// The run ID of the external workflow execution.
    ///
    /// If `nil`, operations target the latest run of the workflow with the given ID.
    public let runId: String?

    /// The internal implementation handling interceptor chains and operations.
    private let implementation: Implementation

    package init(
        id: String,
        runId: String?,
        stateMachine: WorkflowStateMachineStorage,
        interceptors: [any WorkflowOutboundInterceptor],
        payloadConverter: any PayloadConverter
    ) {
        self.id = id
        self.runId = runId
        self.implementation = .init(
            interceptors: interceptors,
            stateMachine: stateMachine,
            payloadConverter: payloadConverter
        )
    }

    /// Sends a signal to the external workflow by signal name.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// try await handle.signal(
    ///     signalName: "updateConfig",
    ///     input: newConfiguration
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - signalName: The name of the signal to send to the external workflow.
    ///   - input: The input data for the signal.
    /// - Throws: Signal delivery errors or serialization errors.
    public func signal<each Input: Sendable>(
        signalName: String,
        input: repeat each Input
    ) async throws {
        try await implementation.signalExternalWorkflow(
            input: SignalExternalWorkflowInput<repeat each Input>(
                id: self.id,
                runId: self.runId,
                name: signalName,
                headers: [:],
                input: (repeat each input)
            )
        )
    }

    /// Cancels the external workflow.
    ///
    /// Sends a cancellation request to the external workflow. The workflow will receive
    /// a cancellation notification and can handle it gracefully.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// try await handle.cancel()
    /// ```
    ///
    /// - Throws: Cancellation delivery errors.
    public func cancel() async throws {
        try await implementation.cancelExternalWorkflow(
            input: CancelExternalWorkflowInput(
                id: self.id,
                runId: self.runId
            )
        )
    }
}

extension UntypedExternalWorkflowHandle {
    struct Implementation: InterceptorImplementation {
        let interceptors: [any WorkflowOutboundInterceptor]
        let stateMachine: WorkflowStateMachineStorage
        let payloadConverter: any PayloadConverter
    }
}

extension UntypedExternalWorkflowHandle.Implementation {
    func signalExternalWorkflow<each Input>(
        input: SignalExternalWorkflowInput<repeat each Input>
    ) async throws {
        try await intercept((any WorkflowOutboundInterceptor).signalExternalWorkflow, input: input) { input in
            let payloads = try self.payloadConverter.convertValues(repeat each input.input)

            try await self.stateMachine.signalExternalWorkflow(
                namespace: Workflow.info.namespace,
                workflowID: input.id,
                runID: input.runId,
                signalName: input.name,
                headers: input.headers,
                inputs: payloads
            )
        }
    }

    func cancelExternalWorkflow(
        input: CancelExternalWorkflowInput
    ) async throws {
        try await intercept((any WorkflowOutboundInterceptor).cancelExternalWorkflow, input: input) { input in
            try await self.stateMachine.cancelExternalWorkflow(
                namespace: Workflow.info.namespace,
                workflowID: input.id,
                runID: input.runId
            )
        }
    }
}
