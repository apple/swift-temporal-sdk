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
/// child workflows. It provides access to child workflow results and enables signaling operations.
///
/// - Note: For type-safe workflow interaction, prefer using ``ChildWorkflowHandle`` when the
///   child workflow type is known at compile time.
public struct UntypedChildWorkflowHandle: Sendable {
    // TODO: This should be protected by something that guards mutations are only done by the workflow
    // TODO: executor or the workflow's instance executors.
    /// The current state of the untyped child workflow handle managing resolution status and results.
    ///
    /// This internal state management class tracks whether the child workflow has completed
    /// and stores the final result when available. The state is protected by the workflow
    /// executor to ensure thread-safe access patterns.
    final class State: @unchecked Sendable {
        /// Represents the resolution state of a child workflow execution tracking completion status and results.
        enum ResolutionState: Sendable {
            /// The child workflow is still executing and has not yet completed.
            ///
            /// - Parameter sequenceNumber: The unique sequence number identifying this child workflow
            ///   operation within the parent workflow's execution history.
            case unresolved(sequenceNumber: UInt32)

            /// The child workflow has completed with a final result.
            ///
            /// - Parameter result: The final result of the child workflow execution, which may represent
            ///   successful completion, failure, or cancellation.
            case resolved(result: Coresdk.ChildWorkflow.ChildWorkflowResult)

            /// A boolean value that indicates whether the child workflow has completed execution.
            var isResolved: Bool {
                switch self {
                case .unresolved:
                    return false
                case .resolved:
                    return true
                }
            }
        }

        /// The current resolution state of the child workflow.
        var resolutionState: ResolutionState

        /// Creates a new state instance with the specified resolution state.
        ///
        /// - Parameter resolutionState: The initial resolution state for the child workflow handle.
        init(resolutionState: ResolutionState) {
            self.resolutionState = resolutionState
        }
    }
    /// The unique identifier of the child workflow execution.
    ///
    /// This identifier uniquely identifies the child workflow within its namespace and can be used
    /// for workflow queries, external signaling, and debugging operations. The ID remains constant
    /// throughout the child workflow's entire lifecycle.
    public let id: String

    /// The run ID of the initial execution run for the child workflow.
    ///
    /// This identifier uniquely identifies the first execution run of the child workflow.
    /// If the child workflow uses continue-as-new, subsequent runs will have different run IDs,
    /// but this property always returns the ID from the initial run.
    public let firstExecutionRunID: String

    /// The workflow state machine storage that coordinates child workflow operations.
    private let stateMachine: WorkflowStateMachineStorage

    /// The internal state of the child workflow handle.
    private let state: State

    /// The payload converter used for serializing and deserializing workflow data.
    private let payloadConverter: any PayloadConverter

    /// The failure converter used for handling workflow errors and exceptions.
    private let failureConverter: any FailureConverter

    /// The workflow task executor managing concurrent operations.
    private let executor: WorkflowTaskExecutor

    /// The outbound interceptors for workflow operations.
    private let interceptors: [any WorkflowOutboundInterceptor]

    /// The internal implementation handling interceptor chains and operations.
    private let implementation: Implementation

    /// Creates a new untyped child workflow handle with the specified configuration.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the child workflow.
    ///   - firstExecutionRunID: The run ID of the initial execution run.
    ///   - state: The internal state management for the handle.
    ///   - stateMachine: The workflow state machine storage.
    ///   - executor: The workflow task executor.
    ///   - interceptors: The outbound interceptors for workflow operations.
    ///   - payloadConverter: The payload converter for data serialization.
    ///   - failureConverter: The failure converter for error handling.
    init(
        id: String,
        firstExecutionRunID: String,
        state: State,
        stateMachine: WorkflowStateMachineStorage,
        executor: WorkflowTaskExecutor,
        interceptors: [any WorkflowOutboundInterceptor],
        payloadConverter: any PayloadConverter,
        failureConverter: any FailureConverter
    ) {
        self.id = id
        self.firstExecutionRunID = firstExecutionRunID
        self.state = state
        self.stateMachine = stateMachine
        self.executor = executor
        self.payloadConverter = payloadConverter
        self.failureConverter = failureConverter
        self.interceptors = interceptors
        self.implementation = .init(
            interceptors: interceptors,
            stateMachine: stateMachine,
            payloadConverter: payloadConverter
        )
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
    ///     let result = try await handle.result(resultType: MyWorkflowOutput.self)
    ///     // Process successful result
    /// } catch {
    ///     // Handle child workflow failure, cancellation, or timeout
    /// }
    /// ```
    ///
    /// - Parameter resultType: The expected result type for the child workflow output.
    /// - Returns: The child workflow's output value.
    /// - Throws: Errors from child workflow execution, including business logic errors,
    ///   system failures, timeouts, and cancellation errors.
    public func result<Result: Sendable>(
        resultType: Result.Type = Result.self
    ) async throws -> Result {
        await withTaskCancellationHandler {
            // We need to shield for cancellation here to avoid
            // the condition from automatically cancelling itself
            await self.stateMachine.uncancellableCondition { self.state.resolutionState.isResolved }
        } onCancel: {
            switch self.state.resolutionState {
            case .resolved:
                // That's okay. We might get an activation that resolves the child workflow
                // and then cancels the waiting on the child workflow.
                break
            case .unresolved(let sequenceNumber):
                self.stateMachine.cancelChildWorkflow(sequenceNumber: sequenceNumber)
            }
        }

        // At this point we must have the resolution state since our condition just succeeded
        // TODO: Might be worth having a condition method that can return an optional
        guard case .resolved(let result) = self.state.resolutionState else {
            fatalError("Internal inconsistency: workflow result should be resolved")
        }

        switch result.status {
        case .completed(let completed):
            return try payloadConverter.convertPayloadHandlingVoid(
                completed.result,
                as: Result.self
            )
        case .failed(let failure):
            throw self.failureConverter.convertTemporalFailure(
                .init(temporalAPIFailure: failure.failure),
                payloadConverter: self.payloadConverter
            )
        case .cancelled(let cancelled):
            throw self.failureConverter.convertTemporalFailure(
                .init(temporalAPIFailure: cancelled.failure),
                payloadConverter: self.payloadConverter
            )
        case .none:
            throw UnknownError(message: "Unknown child workflow result", stackTrace: "")
        }
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
    /// // Signal with single input
    /// try await handle.signalWorkflow(
    ///     signalName: "updateConfig",
    ///     input: newConfiguration
    /// )
    ///
    /// // Signal with multiple inputs
    /// try await handle.signalWorkflow(
    ///     signalName: "processData",
    ///     input: dataValue, timestampValue, metadataValue
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - signalName: The name of the signal to send to the child workflow.
    ///   - input: The input data for the signal.
    /// - Throws: Signal delivery errors or serialization errors.
    public func signalWorkflow<each Input: Sendable>(
        signalName: String,
        input: repeat each Input
    ) async throws {
        try await implementation.signalWorkflow(
            input: SignalChildWorkflowInput<repeat each Input>(
                id: self.id,
                name: signalName,
                headers: [:],
                input: (repeat each input)
            )
        )
    }
}

extension UntypedChildWorkflowHandle {
    /// Internal implementation handling the interceptor chain and workflow state coordination.
    struct Implementation: InterceptorImplementation {
        /// The outbound interceptors for workflow operations.
        let interceptors: [any WorkflowOutboundInterceptor]

        /// The workflow state machine storage coordinating execution state.
        let stateMachine: WorkflowStateMachineStorage

        /// The payload converter for data serialization.
        let payloadConverter: any PayloadConverter
    }
}

extension UntypedChildWorkflowHandle.Implementation {
    /// Sends a signal to a child workflow through the interceptor chain with payload conversion.
    func signalWorkflow<each Input>(
        input: SignalChildWorkflowInput<repeat each Input>
    ) async throws {
        try await intercept((any WorkflowOutboundInterceptor).signalWorkflow, input: input) { input in
            let payloads = try self.payloadConverter.convertValues(repeat each input.input)

            try await self.stateMachine.signalChildWorkflow(
                childWorkflowID: input.id,
                signalName: input.name,
                headers: input.headers,
                inputs: payloads
            )
        }
    }
}
