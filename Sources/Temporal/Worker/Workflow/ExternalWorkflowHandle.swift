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

/// A handle for interacting with an external workflow providing type-safe signaling and cancellation capabilities.
///
/// `ExternalWorkflowHandle` provides a type-safe interface for communicating with external workflows.
///
/// - Note: ``UntypedExternalWorkflowHandle`` provides the same functionality as ``ExternalWorkflowHandle``
/// without binding to a specific ``WorkflowDefinition``, simplifying interoperability with
/// Temporal workflows not implemented in Swift and/or do not share the ``WorkflowDefinition``.
///
/// ## Usage
///
/// ```swift
/// // Get a typed handle to an external workflow
/// let handle = Workflow.getExternalWorkflowHandle(
///     ExternalTargetWorkflow.self,
///     id: "other-workflow-id"
/// )
///
/// // Signal the external workflow with type safety
/// try await handle.signal(
///     signalType: ExternalTargetWorkflow.MySignal.self,
///     input: signalData
/// )
///
/// // Cancel the external workflow
/// try await handle.cancel()
/// ```
public struct ExternalWorkflowHandle<Workflow: WorkflowDefinition>: Sendable {
    /// The unique identifier of the external workflow execution.
    ///
    /// This identifier uniquely identifies the external workflow within its namespace
    /// and is used for signaling and cancellation operations.
    public var id: String { self.untypedHandle.id }

    /// The run ID of the external workflow execution.
    ///
    /// If `nil`, operations target the latest run of the workflow with the given ID.
    public var runId: String? { self.untypedHandle.runId }

    /// The underlying untyped handle that provides the actual implementation.
    private let untypedHandle: UntypedExternalWorkflowHandle

    init(untypedHandle: UntypedExternalWorkflowHandle) {
        self.untypedHandle = untypedHandle
    }

    /// Sends a signal to the external workflow.
    ///
    /// Signals provide a mechanism for workflows to communicate with external workflows.
    /// The signal is delivered asynchronously and processed by the external workflow's signal handler.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// try await handle.signal(
    ///     signalType: UpdateConfigSignal.self,
    ///     input: newConfiguration
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - signalType: The type of signal to send.
    ///   - input: The input data for the signal.
    /// - Throws: Signal delivery errors or serialization errors.
    public func signal<Signal: WorkflowSignalDefinition>(
        signalType: Signal.Type,
        input: Signal.Input
    ) async throws {
        try await self.untypedHandle.signal(
            signalName: Signal.name,
            input: input
        )
    }

    /// Sends a signal to the external workflow.
    ///
    /// This convenience method is used for signals that don't require input data, where the
    /// signal itself conveys all necessary information.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// try await handle.signal(signalType: CancelOperationSignal.self)
    /// ```
    ///
    /// - Parameter signalType: The type of signal to send.
    /// - Throws: Signal delivery errors or serialization errors.
    public func signal<Signal: WorkflowSignalDefinition>(
        signalType: Signal.Type
    ) async throws where Signal.Input == Void {
        try await self.signal(
            signalType: signalType,
            input: ()
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
        try await self.untypedHandle.cancel()
    }
}
