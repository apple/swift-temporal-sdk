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

/// Protocol that intercepts and optionally modifies client operations before they are sent to the Temporal server.
public protocol ClientOutboundInterceptor: Sendable {

    // MARK: - Workflow Operations

    /// Intercepts workflow start operations.
    ///
    /// - Parameters:
    ///   - input: The workflow start input containing workflow type, ID, options, and parameters.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: An untyped workflow handle for the started workflow execution.
    /// - Throws: Any error encountered during workflow start processing or forwarding.
    func startWorkflow<each Input>(
        input: StartWorkflowInput<repeat each Input>,
        next: (StartWorkflowInput<repeat each Input>) async throws -> UntypedWorkflowHandle
    ) async throws -> UntypedWorkflowHandle

    // TODO: startUpdateWithStartWorkflow

    /// Intercepts workflow signal operations.
    ///
    /// - Parameters:
    ///   - input: The signal input containing workflow identification, signal name, and parameters.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during signal processing or forwarding.
    func signalWorkflow<each Input>(
        input: SignalWorkflowInput<repeat each Input>,
        next: (SignalWorkflowInput<repeat each Input>) async throws -> Void
    ) async throws

    /// Intercepts workflow query operations.
    ///
    /// - Parameters:
    ///   - input: The query input containing workflow identification, query name, and parameters.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: A tuple containing the query results in the order specified by the result types.
    /// - Throws: Any error encountered during query processing or forwarding.
    func queryWorkflow<each Input, each Result: Sendable>(
        input: QueryWorkflowInput<repeat each Input>,
        next: (QueryWorkflowInput<repeat each Input>) async throws -> (repeat each Result)
    ) async throws -> (repeat each Result)

    /// Intercepts workflow start update operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to start workflow updates.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: An untyped workflow update handle for the started workflow update.
    /// - Throws: Any error encountered during query processing or forwarding.
    func startWorkflowUpdate<each Input>(
        input: StartWorkflowUpdateInput<repeat each Input>,
        next: (StartWorkflowUpdateInput<repeat each Input>) async throws -> UntypedWorkflowUpdateHandle
    ) async throws -> UntypedWorkflowUpdateHandle

    /// Intercepts workflow describe operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to describe the workflow.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: The description of the workflow execution.
    /// - Throws: Any error encountered during query processing or forwarding.
    func describeWorkflow(
        input: DescribeWorkflowInput,
        next: (DescribeWorkflowInput) async throws -> (WorkflowExecutionDescription)
    ) async throws -> WorkflowExecutionDescription

    /// Intercepts workflow cancel operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to cancel the workflow.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during query processing or forwarding.
    func cancelWorkflow(
        input: CancelWorkflowInput,
        next: (CancelWorkflowInput) async throws -> Void
    ) async throws

    /// Intercepts workflow terminate operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to terminate the workflow.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during query processing or forwarding.
    func terminateWorkflow<each Detail>(
        input: TerminateWorkflowInput<repeat each Detail>,
        next: (TerminateWorkflowInput<repeat each Detail>) async throws -> Void
    ) async throws

    /// Intercepts workflow fetch event history operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to fetch workflow history event page calls.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: The fetched event history of the workflow.
    /// - Throws: Any error encountered during query processing or forwarding.
    func fetchWorkflowHistoryEvents(
        input: FetchWorkflowHistoryEventsInput,
        next: (FetchWorkflowHistoryEventsInput) async throws -> [HistoryEvent]
    ) async throws -> [HistoryEvent]

    /// Intercepts workflow list operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to list workflows.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: A sequence of all fetched workflows fitting the query.
    /// - Throws: Any error encountered during query processing or forwarding.
    func listWorkflows<Sequence: AsyncSequence<WorkflowExecution, any Error> & Sendable>(
        input: ListWorkflowsInput,
        next: (ListWorkflowsInput) async throws -> Sequence
    ) async throws -> Sequence

    /// Intercepts workflow count operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to count workflows.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: The execution count of workflows fitting the query.
    /// - Throws: Any error encountered during query processing or forwarding.
    func countWorkflows(
        input: CountWorkflowsInput,
        next: (CountWorkflowsInput) async throws -> WorkflowExecutionCount
    ) async throws -> WorkflowExecutionCount

    // MARK: - Schedules

    /// Intercepts schedule create operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to create schedules.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: An untyped schedule handle for the created schedule.
    /// - Throws: Any error encountered during query processing or forwarding.
    func createSchedule<Input>(
        input: CreateScheduleInput<Input>,
        next: (CreateScheduleInput<Input>) async throws -> UntypedScheduleHandle
    ) async throws -> UntypedScheduleHandle

    /// Intercepts schedule list operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to list schedules.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: A sequence of all fetched schedules fitting the query.
    /// - Throws: Any error encountered during query processing or forwarding.
    func listSchedules<Sequence: AsyncSequence<ScheduleListDescription, any Error> & Sendable>(
        input: ListSchedulesInput,
        next: (ListSchedulesInput) async throws -> Sequence
    ) async throws -> Sequence

    /// Intercepts schedule backfill operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to backfill a schedule.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during query processing or forwarding.
    func backfillSchedule(
        input: BackfillScheduleInput,
        next: (BackfillScheduleInput) async throws -> Void
    ) async throws

    /// Intercepts schedule delete operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to delete a schedule.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during query processing or forwarding.
    func deleteSchedule(
        input: DeleteScheduleInput,
        next: (DeleteScheduleInput) async throws -> Void
    ) async throws

    /// Intercept calls to describe a schedule.
    ///
    /// - Parameters:
    ///   - input: The input passed to describe a schedule.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Returns: The description of the schedule.
    /// - Throws: Any error encountered during query processing or forwarding.
    func describeSchedule<Input>(
        input: DescribeScheduleInput,
        next: (DescribeScheduleInput) async throws -> ScheduleDescription<Input>
    ) async throws -> ScheduleDescription<Input>

    /// Intercepts schedule pause operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to pause a schedule.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during query processing or forwarding.
    func pauseSchedule(
        input: PauseScheduleInput,
        next: (PauseScheduleInput) async throws -> Void
    ) async throws

    /// Intercepts schedule trigger operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to trigger a schedule.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during query processing or forwarding.
    func triggerSchedule(
        input: TriggerScheduleInput,
        next: (TriggerScheduleInput) async throws -> Void
    ) async throws

    /// Intercepts schedule unpause operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to unpause a schedule.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during query processing or forwarding.
    func unpauseSchedule(
        input: UnpauseScheduleInput,
        next: (UnpauseScheduleInput) async throws -> Void
    ) async throws

    /// Intercepts schedule update operations.
    ///
    /// - Parameters:
    ///   - input: The input passed to update a schedule.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during query processing or forwarding.
    func updateSchedule<Input>(
        input: UpdateScheduleInput<Input>,
        next: (UpdateScheduleInput<Input>) async throws -> Void
    ) async throws

    // MARK: - Async Activities

    /// Intercepts asynchronous activity heartbeat calls.
    ///
    /// - Parameters:
    ///   - input: The input for the heartbeat operation.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during processing or forwarding.
    func heartbeatAsyncActivity(
        input: HeartbeatAsyncActivityInput,
        next: (HeartbeatAsyncActivityInput) async throws -> Void
    ) async throws

    /// Intercepts asynchronous activity complete calls.
    ///
    /// - Parameters:
    ///   - input: The input for the complete operation.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during processing or forwarding.
    func completeAsyncActivity<Result>(
        input: CompleteAsyncActivityInput<Result>,
        next: (CompleteAsyncActivityInput<Result>) async throws -> Void
    ) async throws

    /// Intercepts asynchronous activity fail calls.
    ///
    /// - Parameters:
    ///   - input: The input for the fail operation.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during processing or forwarding.
    func failAsyncActivity(
        input: FailAsyncActivityInput,
        next: (FailAsyncActivityInput) async throws -> Void
    ) async throws

    /// Intercepts asynchronous activity report cancellation calls.
    ///
    /// - Parameters:
    ///   - input: The input for the report cancellation operation.
    ///   - next: A closure that forwards the operation to the next interceptor.
    /// - Throws: Any error encountered during processing or forwarding.
    func reportCancellationAsyncActivity(
        input: ReportCancellationAsyncActivityInput,
        next: (ReportCancellationAsyncActivityInput) async throws -> Void
    ) async throws

    // MARK: - Task Queue

    // TODO: updateWorkerBuildIDCompatibility

    // TODO: getWorkerBuildIDCompatibility

    // TODO: getWorkerTaskReachability
}

// MARK: - Default

extension ClientOutboundInterceptor {

    // MARK: - Workflow

    public func startWorkflow<each Input>(
        input: StartWorkflowInput<repeat each Input>,
        next: (StartWorkflowInput<repeat each Input>) async throws -> UntypedWorkflowHandle
    ) async throws -> UntypedWorkflowHandle {
        try await next(input)
    }

    public func signalWorkflow<each Input>(
        input: SignalWorkflowInput<repeat each Input>,
        next: (SignalWorkflowInput<repeat each Input>) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func queryWorkflow<each Input, each Result: Sendable>(
        input: QueryWorkflowInput<repeat each Input>,
        next: (QueryWorkflowInput<repeat each Input>) async throws -> (repeat each Result)
    ) async throws -> (repeat each Result) {
        try await next(input)
    }

    public func startWorkflowUpdate<each Input>(
        input: StartWorkflowUpdateInput<repeat each Input>,
        next: (StartWorkflowUpdateInput<repeat each Input>) async throws -> UntypedWorkflowUpdateHandle
    ) async throws -> UntypedWorkflowUpdateHandle {
        try await next(input)
    }

    public func describeWorkflow(
        input: DescribeWorkflowInput,
        next: (DescribeWorkflowInput) async throws -> (WorkflowExecutionDescription)
    ) async throws -> WorkflowExecutionDescription {
        try await next(input)
    }

    public func cancelWorkflow(
        input: CancelWorkflowInput,
        next: (CancelWorkflowInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func terminateWorkflow<each Detail>(
        input: TerminateWorkflowInput<repeat each Detail>,
        next: (TerminateWorkflowInput<repeat each Detail>) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func fetchWorkflowHistoryEvents(
        input: FetchWorkflowHistoryEventsInput,
        next: (FetchWorkflowHistoryEventsInput) async throws -> [HistoryEvent]
    ) async throws -> [HistoryEvent] {
        try await next(input)
    }

    public func listWorkflows<Sequence: AsyncSequence<WorkflowExecution, any Error> & Sendable>(
        input: ListWorkflowsInput,
        next: (ListWorkflowsInput) async throws -> Sequence
    ) async throws -> Sequence {
        try await next(input)
    }

    public func countWorkflows(
        input: CountWorkflowsInput,
        next: (CountWorkflowsInput) async throws -> WorkflowExecutionCount
    ) async throws -> WorkflowExecutionCount {
        try await next(input)
    }

    // MARK: - Schedules

    public func createSchedule<Input>(
        input: CreateScheduleInput<Input>,
        next: (CreateScheduleInput<Input>) async throws -> UntypedScheduleHandle
    ) async throws -> UntypedScheduleHandle {
        try await next(input)
    }

    public func listSchedules<Sequence: AsyncSequence<ScheduleListDescription, any Error> & Sendable>(
        input: ListSchedulesInput,
        next: (ListSchedulesInput) async throws -> Sequence
    ) async throws -> Sequence {
        try await next(input)
    }

    public func backfillSchedule(
        input: BackfillScheduleInput,
        next: (BackfillScheduleInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func deleteSchedule(
        input: DeleteScheduleInput,
        next: (DeleteScheduleInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func describeSchedule<Input>(
        input: DescribeScheduleInput,
        next: (DescribeScheduleInput) async throws -> ScheduleDescription<Input>
    ) async throws -> ScheduleDescription<Input> {
        try await next(input)
    }

    public func pauseSchedule(
        input: PauseScheduleInput,
        next: (PauseScheduleInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func triggerSchedule(
        input: TriggerScheduleInput,
        next: (TriggerScheduleInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func unpauseSchedule(
        input: UnpauseScheduleInput,
        next: (UnpauseScheduleInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func updateSchedule<Input>(
        input: UpdateScheduleInput<Input>,
        next: (UpdateScheduleInput<Input>) async throws -> Void
    ) async throws {
        try await next(input)
    }

    // MARK: - Async Activities

    public func heartbeatAsyncActivity(
        input: HeartbeatAsyncActivityInput,
        next: (HeartbeatAsyncActivityInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func completeAsyncActivity<Result>(
        input: CompleteAsyncActivityInput<Result>,
        next: (CompleteAsyncActivityInput<Result>) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func failAsyncActivity(
        input: FailAsyncActivityInput,
        next: (FailAsyncActivityInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    public func reportCancellationAsyncActivity(
        input: ReportCancellationAsyncActivityInput,
        next: (ReportCancellationAsyncActivityInput) async throws -> Void
    ) async throws {
        try await next(input)
    }

    // MARK: - Task Queue: TODO...
}
