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

extension TemporalClient.InterceptedService {
    // MARK: - Start Workflow

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
    ///   - input: The input parameters to pass to the workflow's execution method.
    /// - Returns: The unique run ID of the started workflow execution for tracking and operations.
    /// - Throws: ``WorkflowAlreadyStartedError`` if a workflow with the same ID is already
    /// running (depending on ID reuse policy), or an error for other startup failures.
    package func startWorkflow<each Input: Sendable>(
        name: String,
        options: WorkflowOptions,
        input: repeat each Input,
    ) async throws -> String {
        let untypedHandle = try await self.interceptor.startWorkflow(
            .init(
                name: name,
                options: options,
                headers: [:],
                input: repeat each input
            )
        )

        // This is safe as the `resultRunID` on the handle must be set when starting a workflow
        guard let runID = untypedHandle.resultRunID else {  // runID is not set
            fatalError("Internal consistency error: resultRunID not set for started workflow")
        }

        return runID
    }

    /// Starts a workflow execution with the specified name and configuration but no input.
    ///
    /// This convenience method starts a workflow that requires no input parameters. It provides the same
    /// functionality as ``startWorkflow(name:options:input:)`` but is specifically designed for workflows
    /// that have `Void` as their input type.
    ///
    /// - Parameters:
    ///   - name: The registered name of the workflow type to execute.
    ///   - options: Configuration options controlling workflow execution behavior, timeouts, and policies.
    /// - Returns: The unique run ID of the started workflow execution for tracking and operations.
    /// - Throws: ``WorkflowAlreadyStartedError`` if a workflow with the same ID is already
    /// running (depending on ID reuse policy), or an error for other startup failures.
    package func startWorkflow(
        name: String,
        options: WorkflowOptions
    ) async throws -> String {
        try await self.startWorkflow(
            name: name,
            options: options,
            input: ()
        )
    }

    /// Executes a workflow and waits for its completion, returning the result.
    ///
    /// This method provides a convenient way to start a workflow and wait for its completion in a single call.
    /// It combines the functionality of ``startWorkflow(name:options:input:)`` and ``workflowResult(id:runID:followRuns:resultTypes:callOptions:)``
    /// into one operation.
    ///
    /// The method suspends until the workflow completes successfully, fails, or is terminated. For long-running
    /// workflows, consider using ``startWorkflow(name:options:input:)`` instead to get immediate access to
    /// the workflow ID for monitoring and control operations.
    ///
    /// This approach is ideal for workflows that complete quickly or when you only need the final result
    /// without intermediate monitoring or control.
    ///
    /// - Parameters:
    ///   - name: The workflow name that defines the business logic to execute.
    ///   - options: Configuration options including workflow ID, task queue, and execution policies.
    ///   - input: The input data to pass to the workflow's run method.
    ///   - resultTypes: The expected return types from the workflow.
    /// - Returns: The output value produced by the completed workflow execution.
    /// - Throws: An error if the workflow fails to start, encounters an execution error, or is terminated.
    package func executeWorkflow<each Input: Sendable, each Result: Sendable>(
        name: String,
        options: WorkflowOptions,
        input: repeat each Input,
        resultTypes: repeat (each Result).Type,
    ) async throws -> (repeat each Result) {
        let runID = try await self.startWorkflow(
            name: name,
            options: options,
            input: repeat each input
        )

        return try await self.workflowResult(
            id: options.id,
            runID: runID,
            resultTypes: repeat each resultTypes
        )
    }

    // MARK: - Result

    /// Waits for and retrieves the final result of the workflow execution.
    ///
    /// This method implements long-polling to wait for the workflow to reach a terminal state
    /// and return its final result. It handles various completion scenarios including successful
    /// completion, failures, cancellations, and continue-as-new operations.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow whose history to retrieve.
    ///   - runID: The specific run ID to get history for. If nil, retrieves history for the latest run.
    ///   - followRuns: Whether to automatically follow continue-as-new and retry chains to get the final result.
    ///   - resultTypes: The expected return types from the workflow.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The final output of the workflow execution.
    /// - Throws: Various workflow-specific errors depending on the terminal state.
    package func workflowResult<each Result: Sendable>(
        id: String,
        runID: String? = nil,
        followRuns: Bool = true,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        try await self.interceptor.workflowService.result(
            historyRunID: runID,
            followRuns: followRuns
        ) { historyRunID in
            try await self.interceptor.fetchWorkflowHistoryEvents(  // Interceptor chain is performed here
                .init(
                    id: id,
                    runID: historyRunID,
                    waitNewEvent: true,
                    eventFilterType: .closeEvent,
                    skipArchival: true,
                    callOptions: callOptions
                )
            )
        }
    }

    /// Retrieves the workflow execution history events with optional filtering and polling.
    ///
    /// This method fetches the history events for the workflow execution, which provide a complete
    /// audit trail of all operations that have occurred during the workflow's lifecycle. The history
    /// includes decisions, activity executions, signals, queries, and other significant events.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow whose history to retrieve.
    ///   - runID: The specific run ID to get history for. If nil, retrieves history for the latest run.
    ///   - waitNewEvent: Whether to wait for new events if none are immediately available.
    ///   - eventFilterType: The type of events to include in the response.
    ///   - skipArchival: Whether to skip archived history events for performance.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: An array of history events representing the workflow's execution timeline.
    /// - Throws: An error if the history cannot be retrieved or the workflow doesn't exist.
    package func fetchWorkflowHistoryEvents(
        id: String,
        runID: String? = nil,
        waitNewEvent: Bool = false,
        eventFilterType: HistoryEventFilterType = .allEvent,
        skipArchival: Bool = false,
        callOptions: CallOptions? = nil
    ) async throws -> [HistoryEvent] {
        try await self.interceptor.fetchWorkflowHistoryEvents(
            .init(
                id: id,
                runID: runID,
                waitNewEvent: waitNewEvent,
                eventFilterType: .closeEvent,
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
    ///   - id: The unique identifier of the target workflow.
    ///   - runID: The specific run ID to signal. If nil, signals the latest run.
    ///   - signalName: The signal name.
    ///   - input: The input data to send with the signal.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the signal cannot be delivered or the workflow execution doesn't exist.
    package func signalWorkflow<each Input: Sendable>(
        id: String,
        runID: String? = nil,
        signalName: String,
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.signalWorkflow(
            .init(
                id: id,
                runID: runID,
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
    ///   - id: The unique identifier of the target workflow.
    ///   - runID:  The specific run ID to query. If nil, queries the latest run.
    ///   - queryName: The query name.
    ///   - rejectionCondition: Optional condition for rejecting the query based on workflow state.
    ///   - input: The input data for the query.
    ///   - resultTypes: The expected return types from the query.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The query result.
    /// - Throws: An error if the query fails, is rejected, or the workflow doesn't exist.
    package func queryWorkflow<each Input: Sendable, each Result: Sendable>(
        id: String,
        runID: String? = nil,
        queryName: String,
        rejectionCondition: QueryRejectionCondition? = nil,
        input: repeat each Input,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        try await self.interceptor.queryWorkflow(
            .init(
                id: id,
                runID: runID,
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
    /// - Parameters:
    ///    - id: The unique identifier of the workflow to describe.
    ///    - runID: The specific run ID to describe. If nil, describes the latest run.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A description of the workflow execution.
    /// - Throws: An error if the workflow information cannot be retrieved or doesn't exist.
    package func describeWorkflow(
        id: String,
        runID: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws -> WorkflowExecutionDescription {
        try await self.interceptor.describeWorkflow(
            .init(
                id: id,
                runID: runID,
                callOptions: callOptions
            )
        )
    }

    // MARK: Updates

    /// Initiates a workflow update operation and returns an update ID for managing it.
    ///
    /// Workflow updates provide a way to modify the state of a running workflow while maintaining
    /// strong consistency guarantees. Unlike signals, updates are synchronous operations that can
    /// return results and are processed as part of the workflow's decision execution.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to update.
    ///   - runID: The specific run ID to update. If nil, targets the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - updateName: The name of the update handler defined in the workflow.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - input: The input parameters to pass to the update handler.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The unique update ID that can be used to retrieve results later.
    /// - Throws: An error if the update cannot be started or the workflow doesn't exist.
    package func startWorkflowUpdate<each Input: Sendable>(
        id: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        updateName: String,
        updateID: String = UUID().uuidString,
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) async throws -> String {
        let untypedHandle = try await self.interceptor.startWorkflowUpdate(
            .init(
                id: id,
                runID: runID,
                updateID: updateID,
                updateName: updateName,
                firstExecutionRunID: firstExecutionRunID,
                headers: [:],
                input: repeat each input,
                callOptions: callOptions
            )
        )

        return untypedHandle.id
    }

    /// Executes a workflow update and waits for its completion in a single operation.
    ///
    /// This is a convenience method that combines starting an update with waiting for its result.
    /// It internally calls ``startWorkflowUpdate(id:runID:firstExecutionRunID:updateName:updateID:input:callOptions:)`` followed by waiting for
    /// the result via ``workflowUpdateResult(id:runID:updateID:resultTypes:callOptions:)``, providing a simpler API for synchronous update operations.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to update.
    ///   - runID: The specific run ID to update. If nil, targets the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - updateName: The update name.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - input: The input parameters to pass to the update handler.
    ///   - resultTypes: The expected return types from the update operation.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The result of the update operation.
    /// - Throws: An error if the update fails, is rejected, or cannot be executed.
    package func executeWorkflowUpdate<each Input: Sendable, each Result: Sendable>(
        id: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        updateName: String,
        updateID: String = UUID().uuidString,
        input: repeat each Input,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        let updateID = try await self.startWorkflowUpdate(
            id: id,
            runID: runID,
            firstExecutionRunID: firstExecutionRunID,
            updateName: updateName,
            updateID: updateID,
            input: repeat each input,
            callOptions: callOptions
        )

        return try await self.workflowUpdateResult(
            id: id,
            runID: runID,
            updateID: updateID,
            resultTypes: (repeat each Result).self,
            callOptions: callOptions
        )
    }

    /// Retrieves the result of a previously started workflow update using long polling.
    ///
    /// This method waits for a workflow update to complete and returns its results.
    /// It uses long polling to efficiently wait until the update finishes processing,
    /// automatically handling retries and connection timeouts. Use this method after
    /// starting an update with ``startWorkflowUpdate(id:runID:firstExecutionRunID:updateName:updateID:input:callOptions:)``.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the target workflow.
    ///   - runID: The specific run ID that was updated. If nil, uses the latest run.
    ///   - updateID: The unique identifier of the update to retrieve results for.
    ///   - resultTypes: The expected return types from the update operation.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A tuple containing the update results in the order specified by `resultTypes`.
    /// - Throws: ``WorkflowUpdateFailedError`` if the update execution failed, or an error for other retrieval failures including timeouts.
    package func workflowUpdateResult<each Result: Sendable>(
        id: String,
        runID: String? = nil,
        updateID: String,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        try await self.interceptor.workflowService.workflowUpdateResult(  // Other SDKs also don't go through interceptor
            workflowID: id,
            runID: runID,
            updateID: updateID,
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
    /// - Parameters:
    ///    - id: The unique identifier of the workflow to cancel.
    ///    - runID: The specific run ID to cancel. If nil, cancels the latest run.
    ///    - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the cancellation request cannot be sent.
    package func cancelWorkflow(
        id: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.cancelWorkflow(
            .init(
                id: id,
                runID: runID,
                firstExecutionRunID: firstExecutionRunID,
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
    ///   - id: The unique identifier of the workflow to terminate.
    ///   - runID: The specific run ID to cancel. If nil, terminates the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - reason: An optional human-readable reason for the termination.
    ///   - details: Optional additional details about the termination (variadic parameters).
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the termination request cannot be sent.
    package func terminateWorkflow<each Detail: Sendable>(
        id: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        reason: String? = nil,
        details: repeat each Detail,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.terminateWorkflow(
            .init(
                id: id,
                runID: runID,
                firstExecutionRunID: firstExecutionRunID,
                reason: reason,
                details: (repeat each details),
                callOptions: callOptions
            )
        )
    }

    // TODO: Possibly support `StartUpdateWithStartWorkflow`
    // Start an update using its name, possibly starting the workflow at the same time.
    // Also add interceptors.
}
