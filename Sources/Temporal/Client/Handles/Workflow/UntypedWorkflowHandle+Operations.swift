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

public import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

extension UntypedWorkflowHandle {
    // MARK: Result

    /// Waits for and retrieves the final result of the workflow execution.
    ///
    /// This method implements long-polling to wait for the workflow to reach a terminal state
    /// and return its final result. It handles various completion scenarios including successful
    /// completion, failures, cancellations, and continue-as-new operations.
    ///
    /// - Parameters:
    ///   - followRuns: Whether to automatically follow continue-as-new and retry chains to get the final result.
    ///   - resultTypes: The expected return types.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The final output of the workflow execution.
    /// - Throws: Various workflow-specific errors depending on the terminal state.
    public func result<each Result: Sendable>(
        followRuns: Bool = true,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        try await self.interceptor.workflowService.result(
            historyRunID: self.resultRunID,
            followRuns: followRuns
        ) { historyRunID in
            try await self.interceptor.fetchWorkflowHistoryEvents(
                .init(
                    id: self.id,
                    runID: historyRunID,
                    waitNewEvent: true,
                    eventFilterType: .closeEvent,
                    skipArchival: true,
                    callOptions: callOptions
                )
            )
        }
    }

    // MARK: History Events

    /// Retrieves the workflow execution history events with optional filtering and polling.
    ///
    /// This method fetches the history events for the workflow execution, which provide a complete
    /// audit trail of all operations that have occurred during the workflow's lifecycle. The history
    /// includes decisions, activity executions, signals, queries, and other significant events.
    ///
    /// - Parameters:
    ///   - waitNewEvent: Whether to wait for new events if none are immediately available.
    ///   - eventFilterType: The type of events to include in the response.
    ///   - skipArchival: Whether to skip archived history events for performance.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: An array of history events representing the workflow's execution timeline.
    /// - Throws: An error if the history cannot be retrieved or the workflow doesn't exist.
    public func fetchHistoryEvents(
        waitNewEvent: Bool = false,
        eventFilterType: HistoryEventFilterType = .allEvent,
        skipArchival: Bool = false,
        callOptions: CallOptions? = nil
    ) async throws -> [HistoryEvent] {
        try await self.interceptor.fetchWorkflowHistoryEvents(
            .init(
                id: self.id,
                runID: self.runID,
                waitNewEvent: waitNewEvent,
                eventFilterType: eventFilterType,
                skipArchival: skipArchival,
                callOptions: callOptions
            )
        )
    }

    // MARK: Signals

    /// Sends a signal to the workflow execution with typed input data.
    ///
    /// Signals provide a way to send data to a running workflow execution from external systems.
    /// They are asynchronous and non-blocking operations that can be used to trigger workflow
    /// logic, update workflow state, or provide external inputs during execution.
    ///
    /// - Parameters:
    ///   - signalName: The signal name.
    ///   - input: The input data to send with the signal.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the signal cannot be delivered or the workflow execution doesn't exist.
    public func signal<each Input: Sendable>(
        signalName: String,
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.signalWorkflow(
            .init(
                id: self.id,
                runID: self.runID,
                name: signalName,
                headers: [:],
                input: repeat each input,
                callOptions: callOptions
            )
        )
    }

    // MARK: Query

    /// Executes a query against the workflow execution to retrieve current state information.
    ///
    /// Queries provide a way to retrieve information from a running workflow without affecting
    /// its execution or causing side effects. They are synchronous read-only operations that
    /// can access the current workflow state and return computed results.
    ///
    /// - Parameters:
    ///   - queryName: The query name.
    ///   - rejectionCondition: Optional condition for rejecting the query based on workflow state.
    ///   - input: The input data for the query.
    ///   - resultTypes: The expected return types from the query operation.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The query result.
    /// - Throws: An error if the query fails, is rejected, or the workflow doesn't exist.
    public func query<each Input: Sendable, each Result: Sendable>(
        queryName: String,
        rejectionCondition: QueryRejectionCondition? = nil,
        input: repeat each Input,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        try await self.interceptor.queryWorkflow(
            .init(
                id: self.id,
                runID: self.runID,
                queryName: queryName,
                rejectionCondition: rejectionCondition,
                headers: [:],
                input: repeat each input,
                callOptions: callOptions
            )
        )
    }

    // MARK: Describe

    /// Retrieves information about the workflow execution status and configuration.
    ///
    /// This method returns information about the workflow execution including
    /// its current status, configuration, timing information, and execution metadata.
    /// The description provides a snapshot of the workflow's current state.
    ///
    /// - Parameter callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A description of the workflow execution.
    /// - Throws: An error if the workflow information cannot be retrieved or doesn't exist.
    public func describe(callOptions: CallOptions? = nil) async throws -> WorkflowExecutionDescription {
        try await self.interceptor.describeWorkflow(
            .init(
                id: self.id,
                runID: self.runID,
                callOptions: callOptions
            )
        )
    }

    // MARK: Updates

    /// Initiates a workflow update operation and returns a handle for managing it.
    ///
    /// Workflow updates provide a way to modify the state of a running workflow while maintaining
    /// strong consistency guarantees. Unlike signals, updates are synchronous operations that can
    /// return results and are processed as part of the workflow's decision execution.
    ///
    /// - Parameters:
    ///   - updateName: The update name.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - input: The input data.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A handle for managing the update and retrieving its result.
    /// - Throws: An error if the update cannot be started or the workflow doesn't exist.
    public func startUpdate<each Input: Sendable>(
        updateName: String,
        updateID: String = UUID().uuidString,
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) async throws -> UntypedWorkflowUpdateHandle {
        try await self.interceptor.startWorkflowUpdate(
            .init(
                id: self.id,
                runID: self.runID,
                updateID: updateID,
                updateName: updateName,
                firstExecutionRunID: firstExecutionRunID,
                headers: [:],
                input: repeat each input,
                callOptions: callOptions
            )
        )
    }

    /// Executes a workflow update and waits for its completion in a single operation.
    ///
    /// This is a convenience method that combines starting an update with waiting for its result.
    /// It internally calls ``startUpdate(updateName:updateID:input:callOptions:)`` followed by waiting for
    /// the result, providing a simpler API for synchronous update operations.
    ///
    /// - Parameters:
    ///   - updateName: The update name.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - input: The input data.
    ///   - resultTypes: The expected return types from the update operation.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The result of the update operation.
    /// - Throws: An error if the update fails, is rejected, or cannot be executed.
    public func executeUpdate<each Input: Sendable, each Result: Sendable>(
        updateName: String,
        updateID: String = UUID().uuidString,
        input: repeat each Input,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        let updateHandle = try await self.startUpdate(
            updateName: updateName,
            updateID: updateID,
            input: repeat each input,
            callOptions: callOptions
        )

        return try await updateHandle.result(
            resultTypes: repeat each resultTypes,
            callOptions: callOptions
        )
    }

    // MARK: Cancel

    /// Requests cancellation of the workflow execution.
    ///
    /// Cancellation is a cooperative mechanism that requests the workflow to stop its execution
    /// gracefully. The workflow can handle the cancellation request through cancellation handlers
    /// and perform cleanup operations before terminating.
    ///
    ///- Parameter callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the cancellation request cannot be sent.
    public func cancel(callOptions: CallOptions? = nil) async throws {
        try await self.interceptor.cancelWorkflow(
            .init(
                id: self.id,
                runID: self.runID,
                firstExecutionRunID: self.firstExecutionRunID,
                callOptions: callOptions
            )
        )
    }

    // MARK: Terminate

    /// Forcibly terminates the workflow execution without allowing cleanup.
    ///
    /// Termination immediately stops the workflow execution without giving it a chance to
    /// perform cleanup operations or handle the termination gracefully. This is a forceful
    /// operation that should be used when cancellation is not sufficient or appropriate.
    ///
    /// - Parameters:
    ///   - reason: An optional human-readable reason for the termination.
    ///   - details: Optional additional details about the termination (variadic parameters).
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the termination request cannot be sent.
    public func terminate<each Detail: Sendable>(
        reason: String? = nil,
        details: repeat each Detail,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.terminateWorkflow(
            .init(
                id: self.id,
                runID: self.runID,
                firstExecutionRunID: self.firstExecutionRunID,
                reason: reason,
                details: (repeat each details),
                callOptions: callOptions
            )
        )
    }
}

extension TemporalClient.Interceptor {
    func signalWorkflow<each Input>(
        _ input: SignalWorkflowInput<repeat each Input>
    ) async throws {
        try await self.intercept((any ClientOutboundInterceptor).signalWorkflow, input: input) { input in
            try await self.workflowService.signalWorkflow(
                workflowID: input.id,
                runID: input.runID,
                signalName: input.name,
                headers: input.headers,
                input: input.input,
                callOptions: input.callOptions
            )
        }
    }

    func queryWorkflow<each Input, each Result: Sendable>(
        _ input: QueryWorkflowInput<repeat each Input>
    ) async throws -> (repeat each Result) {
        try await self.intercept((any ClientOutboundInterceptor).queryWorkflow, input: input) { input in
            try await self.workflowService.queryWorkflow(
                workflowID: input.id,
                runID: input.runID,
                queryName: input.queryName,
                rejectionCondition: input.rejectionCondition,
                headers: input.headers,
                input: input.input,
                resultTypes: repeat (each Result).self,
                callOptions: input.callOptions
            )
        }
    }

    func startWorkflowUpdate<each Input>(
        _ input: StartWorkflowUpdateInput<repeat each Input>
    ) async throws -> UntypedWorkflowUpdateHandle {
        try await self.intercept((any ClientOutboundInterceptor).startWorkflowUpdate, input: input) { input in
            let updateID = try await self.workflowService.startWorkflowUpdate(
                workflowID: input.id,
                runID: input.runID,
                firstExecutionRunID: input.firstExecutionRunID,
                updateID: input.updateID,
                updateName: input.updateName,
                headers: input.headers,
                input: input.input,
                callOptions: input.callOptions
            )

            return UntypedWorkflowUpdateHandle(
                interceptor: self,
                id: updateID,
                workflowID: input.id,
                workflowRunID: input.runID  // Starting update does not create a new runID
            )
        }
    }

    func describeWorkflow(
        _ input: DescribeWorkflowInput
    ) async throws -> WorkflowExecutionDescription {
        try await self.intercept((any ClientOutboundInterceptor).describeWorkflow, input: input) { input in
            try await self.workflowService.describeWorkflow(
                workflowID: input.id,
                runID: input.runID,
                callOptions: input.callOptions
            )
        }
    }

    func cancelWorkflow(
        _ input: CancelWorkflowInput
    ) async throws {
        try await self.intercept((any ClientOutboundInterceptor).cancelWorkflow, input: input) { input in
            try await self.workflowService.cancelWorkflow(
                id: input.id,
                runID: input.runID,
                firstExecutionRunID: input.firstExecutionRunID,
                callOptions: input.callOptions
            )
        }
    }

    func terminateWorkflow<each Detail>(
        _ input: TerminateWorkflowInput<repeat each Detail>
    ) async throws {
        try await self.intercept((any ClientOutboundInterceptor).terminateWorkflow, input: input) { input in
            try await self.workflowService.terminateWorkflow(
                id: input.id,
                runID: input.runID,
                firstExecutionRunID: input.firstExecutionRunID,
                reason: input.reason,
                details: repeat each input.details,
                callOptions: input.callOptions
            )
        }
    }

    func fetchWorkflowHistoryEvents(
        _ input: FetchWorkflowHistoryEventsInput
    ) async throws -> [HistoryEvent] {
        try await self.intercept((any ClientOutboundInterceptor).fetchWorkflowHistoryEvents, input: input) { input in
            try await self.workflowService.fetchWorkflowHistoryEvents(
                id: input.id,
                runID: input.runID,
                waitNewEvent: input.waitNewEvent,
                eventFilterType: input.eventFilterType,
                skipArchival: input.skipArchival,
                callOptions: input.callOptions
            )
        }
    }
}
