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

/// A handle for interacting with a started child workflow providing result retrieval and signaling capabilities.
///
/// The child workflow handle serves as the primary interface for parent workflows to interact with their
/// child workflows. It provides access to child workflow results and enables signaling operations
/// while maintaining the hierarchical relationship between parent and child executions.
///
/// ## Usage
///
/// ```swift
/// // Start and wait for child workflow result
/// let childHandle = try await workflowContext.startChildWorkflow(
///     MyChildWorkflow.self,
///     input: childInput,
///     options: childOptions
/// )
/// let result = try await childHandle.result()
///
/// // Signal the child workflow
/// try await childHandle.signalWorkflow(
///     signalType: MySignal.self,
///     input: signalData
/// )
/// ```
public struct ChildWorkflowHandle<Workflow: WorkflowDefinition>: Sendable {
    /// The unique identifier of the child workflow execution.
    ///
    /// This identifier uniquely identifies the child workflow within its namespace and can be used
    /// for workflow queries, external signaling, and debugging operations. The ID remains constant
    /// throughout the child workflow's entire lifecycle.
    public var id: String {
        self.untypedWorkflowHandle.id
    }

    /// The run ID of the initial execution run for the child workflow.
    ///
    /// This identifier uniquely identifies the first execution run of the child workflow.
    /// If the child workflow uses continue-as-new, subsequent runs will have different run IDs,
    /// but this property always returns the ID from the initial run.
    public var firstExecutionRunID: String {
        self.untypedWorkflowHandle.firstExecutionRunID
    }

    /// The underlying untyped workflow handle that provides the actual implementation.
    private let untypedWorkflowHandle: UntypedChildWorkflowHandle

    /// Creates a new typed child workflow handle wrapping an untyped handle.
    ///
    /// - Parameter untypedWorkflowHandle: The untyped handle providing the actual workflow operations.
    init(untypedWorkflowHandle: UntypedChildWorkflowHandle) {
        self.untypedWorkflowHandle = untypedWorkflowHandle
    }

    /// Waits for the child workflow to complete and returns its result.
    ///
    /// This method waits until the child workflow completes successfully, fails, or is cancelled.
    /// The result is automatically deserialized to the expected output type defined by the workflow definition.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// do {
    ///     let result = try await childHandle.result()
    ///     // Process successful result
    /// } catch {
    ///     // Handle child workflow failure
    /// }
    /// ```
    ///
    /// - Returns: The child workflow's output value.
    /// - Throws: Errors from child workflow execution, including business logic errors,
    ///   system failures, timeouts, and cancellation errors.
    public func result() async throws -> Workflow.Output {
        try await self.untypedWorkflowHandle.result(resultType: Workflow.Output.self)
    }

    /// Sends a signal to the child workflow.
    ///
    /// Signals provide a mechanism for parent workflows to communicate with running child workflows.
    /// The signal is delivered asynchronously and processed by the child workflow's signal handler.
    /// This method ensures type safety by validating that the signal type is compatible with the
    /// child workflow's signal definitions.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// try await childHandle.signalWorkflow(
    ///     signalType: UpdateConfigSignal.self,
    ///     input: newConfiguration
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - signalType: The type of signal to send.
    ///   - input: The input data for the signal.
    /// - Throws: Signal delivery errors or serialization errors.
    public func signalWorkflow<Signal: WorkflowSignalDefinition>(
        signalType: Signal.Type,
        input: Signal.Input
    ) async throws {
        try await self.untypedWorkflowHandle.signalWorkflow(
            signalName: Signal.name,
            input: input
        )
    }

    /// Sends a signal to the child workflow.
    ///
    /// This convenience method is used for signals that don't require input data, where the
    /// signal itself conveys all necessary information. It's equivalent to calling the main
    /// signaling method ``signalWorkflow(signalType:input:)`` with `Void` input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// try await childHandle.signalWorkflow(signalType: CancelOperationSignal.self)
    /// ```
    ///
    /// - Parameter signalType: The type of signal to send.
    /// - Throws: Signal delivery errors or serialization errors.
    public func signalWorkflow<Signal: WorkflowSignalDefinition>(
        signalType: Signal.Type
    ) async throws where Signal.Input == Void {
        try await self.signalWorkflow(
            signalType: signalType,
            input: ()
        )
    }
}
