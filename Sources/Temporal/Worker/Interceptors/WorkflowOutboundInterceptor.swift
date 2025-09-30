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

/// Protocol for intercepting and modifying workflow outbound requests sent from workflows to the Temporal server.
public protocol WorkflowOutboundInterceptor: Sendable {
    /// Intercepts workflow timer creation requests (sleep operations).
    ///
    /// - Parameters:
    ///   - input: The timer creation input containing duration and timing details.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Throws: Any error that occurs during timer creation or interception.
    func handleSleep(
        input: HandleSleepInput,
        next: (HandleSleepInput) async throws -> Void
    ) async throws

    /// Intercepts workflow activity scheduling requests.
    ///
    /// - Parameters:
    ///   - input: The activity scheduling input containing activity details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The result of the activity execution.
    /// - Throws: Any error that occurs during activity scheduling or execution.
    func executeActivity<each Input, Output: Sendable>(
        input: ScheduleActivityInput<repeat each Input>,
        next: (ScheduleActivityInput<repeat each Input>) async throws -> Output
    ) async throws -> Output

    /// Intercepts workflow local activity scheduling requests.
    ///
    /// - Parameters:
    ///   - input: The activity scheduling input containing activity details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The result of the activity execution.
    /// - Throws: Any error that occurs during activity scheduling or execution.
    func executeLocalActivity<each Input, Output: Sendable>(
        input: ScheduleLocalActivityInput<repeat each Input>,
        next: (ScheduleLocalActivityInput<repeat each Input>) async throws -> Output
    ) async throws -> Output

    /// Intercepts continue-as-new error creation requests.
    ///
    /// - Parameters:
    ///   - input: The continue-as-new error creation input containing workflow parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: A continue-as-new error configured for workflow restart.
    /// - Throws: Any error that occurs during continue-as-new error creation.
    func makeContinueAsNewError<each Input>(
        input: MakeContinueAsNewErrorInput<repeat each Input>,
        next: (MakeContinueAsNewErrorInput<repeat each Input>) async throws -> ContinueAsNewError
    ) async throws -> ContinueAsNewError

    /// Intercepts child workflow startup requests.
    ///
    /// - Parameters:
    ///   - input: The child workflow startup input containing workflow details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: An untyped handle for interacting with the started child workflow.
    /// - Throws: Any error that occurs during child workflow startup.
    func startChildWorkflow<each Input>(
        input: StartChildWorkflowInput<repeat each Input>,
        next: (StartChildWorkflowInput<repeat each Input>) async throws -> UntypedChildWorkflowHandle
    ) async throws -> UntypedChildWorkflowHandle

    /// Intercepts child workflow signaling requests.
    ///
    /// - Parameters:
    ///   - input: The child workflow signaling input containing signal details and payload.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Throws: Any error that occurs during signal delivery.
    func signalWorkflow<each Input>(
        input: SignalChildWorkflowInput<repeat each Input>,
        next: (SignalChildWorkflowInput<repeat each Input>) async throws -> Void
    ) async throws
}

extension WorkflowOutboundInterceptor {
    /// Default implementation that forwards timer creation to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The timer creation input containing duration and timing details.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Throws: Any error that occurs during timer creation or interception.
    public func handleSleep(
        input: HandleSleepInput,
        next: (HandleSleepInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    /// Default implementation that forwards activity scheduling to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The activity scheduling input containing activity details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The result of the activity execution.
    /// - Throws: Any error that occurs during activity scheduling or execution.
    public func executeActivity<each Input, Output: Sendable>(
        input: ScheduleActivityInput<repeat each Input>,
        next: (ScheduleActivityInput<repeat each Input>) async throws -> Output
    ) async throws -> Output {
        try await next(input)
    }

    /// Default implementation that forwards local activity scheduling to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The activity scheduling input containing activity details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The result of the activity execution.
    /// - Throws: Any error that occurs during activity scheduling or execution.
    public func executeLocalActivity<each Input, Output: Sendable>(
        input: ScheduleLocalActivityInput<repeat each Input>,
        next: (ScheduleLocalActivityInput<repeat each Input>) async throws -> Output
    ) async throws -> Output {
        try await next(input)
    }

    /// Default implementation that forwards continue-as-new error creation to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The continue-as-new error creation input containing workflow parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: A continue-as-new error configured for workflow restart.
    /// - Throws: Any error that occurs during continue-as-new error creation.
    public func makeContinueAsNewError<each Input>(
        input: MakeContinueAsNewErrorInput<repeat each Input>,
        next: (MakeContinueAsNewErrorInput<repeat each Input>) async throws -> ContinueAsNewError
    ) async throws -> ContinueAsNewError {
        try await next(input)
    }

    /// Default implementation that forwards child workflow startup to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The child workflow startup input containing workflow details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: An untyped handle for interacting with the started child workflow.
    /// - Throws: Any error that occurs during child workflow startup.
    public func startChildWorkflow<each Input>(
        input: StartChildWorkflowInput<repeat each Input>,
        next: (StartChildWorkflowInput<repeat each Input>) async throws -> UntypedChildWorkflowHandle
    ) async throws -> UntypedChildWorkflowHandle {
        try await next(input)
    }

    /// Default implementation that forwards child workflow signaling to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The child workflow signaling input containing signal details and payload.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Throws: Any error that occurs during signal delivery.
    public func signalWorkflow<each Input>(
        input: SignalChildWorkflowInput<repeat each Input>,
        next: (SignalChildWorkflowInput<repeat each Input>) async throws -> Void
    ) async throws {
        try await next(input)
    }
}
