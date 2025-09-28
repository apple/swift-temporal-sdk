//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
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

extension WorkflowHandle {
    // MARK: Result

    /// Waits for and retrieves the final result of the workflow execution.
    ///
    /// This method implements long-polling to wait for the workflow to reach a terminal state
    /// and return its final result. It handles various completion scenarios including successful
    /// completion, failures, cancellations, and continue-as-new operations.
    ///
    /// - Parameters:
    ///   - followRuns: Whether to automatically follow continue-as-new and retry chains to get the final result.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The final output of the workflow execution.
    /// - Throws: Various workflow-specific errors depending on the terminal state.
    public func result(followRuns: Bool = true, callOptions: CallOptions? = nil) async throws -> Workflow.Output {
        try await self.untypedHandle.result(
            followRuns: followRuns,
            resultTypes: Workflow.Output.self,
            callOptions: callOptions
        )
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
        try await self.untypedHandle.fetchHistoryEvents(
            waitNewEvent: waitNewEvent,
            eventFilterType: eventFilterType,
            skipArchival: skipArchival,
            callOptions: callOptions
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
    ///   - signalType: The signal type.
    ///   - input: The input data to send with the signal.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the signal cannot be delivered or the workflow execution doesn't exist.
    public func signal<Signal: WorkflowSignalDefinition>(
        signalType: Signal.Type = Signal.self,
        input: Signal.Input,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.untypedHandle.signal(
            signalName: signalType.name,
            input: input,
            callOptions: callOptions
        )
    }

    /// Sends a signal to the workflow execution without input data.
    ///
    /// This is a convenience method for signals that don't require any input parameters.
    /// It's equivalent to calling the ``signal(signalType:input:callOptions:)`` method with `Void` input but provides a
    /// cleaner API for parameterless signals.
    ///
    /// - Parameters:
    ///    - signalType: The signal type.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the signal cannot be delivered or the workflow execution doesn't exist.
    public func signal<Signal: WorkflowSignalDefinition>(
        signalType: Signal.Type = Signal.self,
        callOptions: CallOptions? = nil
    ) async throws where Signal.Input == Void {
        try await self.signal(
            signalType: signalType,
            input: (),
            callOptions: callOptions
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
    ///   - queryType: The query type.
    ///   - rejectionCondition: Optional condition for rejecting the query based on workflow state.
    ///   - input: The input data for the query.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The query result.
    /// - Throws: An error if the query fails, is rejected, or the workflow doesn't exist.
    public func query<Query: WorkflowQueryDefinition>(
        queryType: Query.Type = Query.self,
        rejectionCondition: QueryRejectionCondition? = nil,
        input: Query.Input,
        callOptions: CallOptions? = nil
    ) async throws -> Query.Output {
        try await self.untypedHandle.query(
            queryName: queryType.name,
            rejectionCondition: rejectionCondition,
            input: input,
            resultTypes: Query.Output.self,
            callOptions: callOptions
        )
    }

    /// Executes a query against the workflow execution without input parameters.
    ///
    /// This is a convenience method for queries that don't require input parameters.
    /// It provides a cleaner API for simple state retrieval queries.
    ///
    /// - Parameters:
    ///   - queryType: The query type.
    ///   - rejectionCondition: Optional condition for rejecting the query based on workflow state.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The query result.
    /// - Throws: An error if the query fails, is rejected, or the workflow doesn't exist.
    public func query<Query: WorkflowQueryDefinition>(
        queryType: Query.Type = Query.self,
        rejectionCondition: QueryRejectionCondition? = nil,
        callOptions: CallOptions? = nil
    ) async throws -> Query.Output where Query.Input == Void {
        try await self.query(
            queryType: queryType,
            rejectionCondition: rejectionCondition,
            input: (),
            callOptions: callOptions
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
        try await self.untypedHandle.describe(callOptions: callOptions)
    }

    // MARK: Updates

    /// Initiates a workflow update operation and returns a handle for managing it.
    ///
    /// Workflow updates provide a way to modify the state of a running workflow while maintaining
    /// strong consistency guarantees. Unlike signals, updates are synchronous operations that can
    /// return results and are processed as part of the workflow's decision execution.
    ///
    /// - Parameters:
    ///   - updateType: The update type.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - input: The input data.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A handle for managing the update and retrieving its result.
    /// - Throws: An error if the update cannot be started or the workflow doesn't exist.
    public func startUpdate<WorkflowUpdate: WorkflowUpdateDefinition>(
        updateType: WorkflowUpdate.Type = WorkflowUpdate.self,
        updateID: String = UUID().uuidString,
        input: WorkflowUpdate.Input,
        callOptions: CallOptions? = nil
    ) async throws -> WorkflowUpdateHandle<WorkflowUpdate> {
        let untypedHandle = try await self.untypedHandle.startUpdate(
            updateName: updateType.name,
            updateID: updateID,
            input: input,
            callOptions: callOptions
        )

        return WorkflowUpdateHandle(untypedHandle: untypedHandle)
    }

    /// Executes a workflow update and waits for its completion in a single operation.
    ///
    /// This is a convenience method that combines starting an update with waiting for its result.
    /// It internally calls ``startUpdate(updateType:updateID:input:callOptions:)`` followed by waiting for
    /// the result, providing a simpler API for synchronous update operations.
    ///
    /// - Parameters:
    ///   - updateType: The update type.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - input: The input data.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The result of the update operation.
    /// - Throws: An error if the update fails, is rejected, or cannot be executed.
    public func executeUpdate<Update: WorkflowUpdateDefinition>(
        updateType: Update.Type = Update.self,
        updateID: String = UUID().uuidString,
        input: Update.Input,
        callOptions: CallOptions? = nil
    ) async throws -> Update.Output {
        try await self.untypedHandle.executeUpdate(
            updateName: updateType.name,
            updateID: updateID,
            input: input,
            resultTypes: Update.Output.self,
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
        try await self.untypedHandle.cancel(callOptions: callOptions)
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
        try await self.untypedHandle.terminate(
            reason: reason,
            details: repeat each details,
            callOptions: callOptions
        )
    }
}
