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

import Tracing

extension TemporalClientTracingInterceptor {
    /// Outbound client interceptor that instruments all client requests with distributed tracing.
    public struct Outbound: ClientOutboundInterceptor {
        private let traceRecording: TemporalTraceRecording

        /// Create the client outbound interceptor.
        ///
        /// - Parameters:
        ///    - tracer: The `Tracer` instance to use for creating spans.
        ///    - tracingHeaderKey: The name of the Temporal tracing header key.
        package init(tracer: any Tracer, tracingHeaderKey: String) {
            self.traceRecording = TemporalTraceRecording(
                tracer: tracer,
                tracingHeaderKey: tracingHeaderKey
            )
        }

        public func startWorkflow<each Input>(
            input: StartWorkflowInput<repeat each Input>,
            next: (StartWorkflowInput<repeat each Input>) async throws -> UntypedWorkflowHandle
        ) async throws -> UntypedWorkflowHandle {
            try await self.traceRecording.recordOutbound(
                spanName:
                    "\(Temporal_Api_Workflowservice_V1_WorkflowService.Method.StartWorkflowExecution.descriptor.fullyQualifiedMethod):\(input.name)",
                headers: input.headers,
                setRequestAttributes: { [input] span in
                    span.setStartWorkflowRequestSpanAttributes(input: input)
                },
                setResponseAttributes: { span, response in
                    span.setStartWorkflowResponseSpanAttributes(response: response)
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }

        // TODO: startUpdateWithStartWorkflow

        public func signalWorkflow<each Input>(
            input: SignalWorkflowInput<repeat each Input>,
            next: (SignalWorkflowInput<repeat each Input>) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    "\(Temporal_Api_Workflowservice_V1_WorkflowService.Method.SignalWorkflowExecution.descriptor.fullyQualifiedMethod):\(input.name)",
                headers: input.headers,
                setRequestAttributes: { [input] span in
                    span.setSignalWorkflowSpanAttributes(input: input)
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }

        public func queryWorkflow<each Input, each Result: Sendable>(
            input: QueryWorkflowInput<repeat each Input>,
            next: (QueryWorkflowInput<repeat each Input>) async throws -> (repeat each Result)
        ) async throws -> (repeat each Result) {
            try await self.traceRecording.recordOutbound(
                spanName:
                    "\(Temporal_Api_Workflowservice_V1_WorkflowService.Method.QueryWorkflow.descriptor.fullyQualifiedMethod):\(input.queryName)",
                headers: input.headers,
                setRequestAttributes: { [input] span in
                    span.setQueryWorkflowSpanAttributes(input: input)
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }

        public func startWorkflowUpdate<each Input>(
            input: StartWorkflowUpdateInput<repeat each Input>,
            next: (StartWorkflowUpdateInput<repeat each Input>) async throws -> UntypedWorkflowUpdateHandle
        ) async throws -> UntypedWorkflowUpdateHandle {
            try await self.traceRecording.recordOutbound(
                spanName:
                    "\(Temporal_Api_Workflowservice_V1_WorkflowService.Method.UpdateWorkflowExecution.descriptor.fullyQualifiedMethod):\(input.updateName)",
                headers: input.headers,
                setRequestAttributes: { [input] span in
                    span.setStartWorkflowUpdateRequestSpanAttributes(input: input)
                },
                setResponseAttributes: { span, response in
                    span.setStartWorkflowUpdateResponseSpanAttributes(response: response)
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }

        public func describeWorkflow(
            input: DescribeWorkflowInput,
            next: (DescribeWorkflowInput) async throws -> WorkflowExecutionDescription
        ) async throws -> WorkflowExecutionDescription {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.DescribeWorkflowExecution.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setDescribeWorkflowRequestSpanAttributes(input: input)
                },
                setResponseAttributes: { span, response in
                    span.setDescribeWorkflowResponseSpanAttributes(response: response)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func cancelWorkflow(
            input: CancelWorkflowInput,
            next: (CancelWorkflowInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.RequestCancelWorkflowExecution.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setCancelWorkflowSpanAttributes(input: input)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func terminateWorkflow<each Detail>(
            input: TerminateWorkflowInput<repeat each Detail>,
            next: (TerminateWorkflowInput<repeat each Detail>) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.TerminateWorkflowExecution.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setTerminateWorkflowSpanAttributes(input: input)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func fetchWorkflowHistoryEvents(
            input: FetchWorkflowHistoryEventsInput,
            next: (FetchWorkflowHistoryEventsInput) async throws -> [HistoryEvent]
        ) async throws -> [HistoryEvent] {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.GetWorkflowExecutionHistory.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setFetchWorkflowHistoryRequestSpanAttributes(input: input)
                },
                setResponseAttributes: { span, response in
                    span.setFetchWorkflowHistoryResponseSpanAttributes(count: response.count)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func listWorkflows<Sequence: AsyncSequence<WorkflowExecution, any Error> & Sendable>(
            input: ListWorkflowsInput,
            next: (ListWorkflowsInput) async throws -> Sequence
        ) async throws -> Sequence {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.ListWorkflowExecutions.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setListWorkflowsRequestSpanAttributes(query: input.query, limit: input.limit)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func countWorkflows(
            input: CountWorkflowsInput,
            next: (CountWorkflowsInput) async throws -> WorkflowExecutionCount
        ) async throws -> WorkflowExecutionCount {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.CountWorkflowExecutions.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setCountWorkflowsRequestSpanAttributes(query: input.query)
                },
                setResponseAttributes: { span, response in
                    span.setCountWorkflowsResponseSpanAttributes(count: response.count)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        // MARK: - Schedules

        public func createSchedule<Input>(
            input: CreateScheduleInput<Input>,
            next: (CreateScheduleInput<Input>) async throws -> UntypedScheduleHandle
        ) async throws -> UntypedScheduleHandle {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.CreateSchedule.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setCreateScheduleRequestSpanAttributes(input: input)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func listSchedules<Sequence: AsyncSequence<ScheduleListDescription, any Error> & Sendable>(
            input: ListSchedulesInput,
            next: (ListSchedulesInput) async throws -> Sequence
        ) async throws -> Sequence {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.ListSchedules.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setListSchedulesRequestSpanAttributes(query: input.query)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func backfillSchedule(
            input: BackfillScheduleInput,
            next: (BackfillScheduleInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.PatchSchedule.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setBackfillScheduleSpanAttributes(scheduleId: input.id, backfills: input.backfills)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func deleteSchedule(
            input: DeleteScheduleInput,
            next: (DeleteScheduleInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.DeleteSchedule.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setDeleteScheduleSpanAttributes(scheduleId: input.id)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func describeSchedule<Input>(
            input: DescribeScheduleInput,
            next: (DescribeScheduleInput) async throws -> ScheduleDescription<Input>
        ) async throws -> ScheduleDescription<Input> {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.DescribeSchedule.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setDescribeScheduleRequestSpanAttributes(scheduleId: input.id)
                },
                setResponseAttributes: { span, response in
                    span.setDescribeScheduleResponseSpanAttributes(response: response)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func pauseSchedule(
            input: PauseScheduleInput,
            next: (PauseScheduleInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.PatchSchedule.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setPauseScheduleSpanAttributes(scheduleId: input.id, note: input.note)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func triggerSchedule(
            input: TriggerScheduleInput,
            next: (TriggerScheduleInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.PatchSchedule.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setTriggerScheduleSpanAttributes(scheduleId: input.id, overlap: input.overlap)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func unpauseSchedule(
            input: UnpauseScheduleInput,
            next: (UnpauseScheduleInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.PatchSchedule.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setUnpauseScheduleSpanAttributes(scheduleId: input.id, note: input.note)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func updateSchedule<Input>(
            input: UpdateScheduleInput<Input>,
            next: (UpdateScheduleInput<Input>) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.UpdateSchedule.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setUpdateScheduleSpanAttributes(scheduleId: input.id)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        // MARK: Async Activities

        public func heartbeatAsyncActivity(
            input: HeartbeatAsyncActivityInput,
            next: (HeartbeatAsyncActivityInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.RecordActivityTaskHeartbeat.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setHeartbeatAsyncActivity(input: input)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func completeAsyncActivity<Result>(
            input: CompleteAsyncActivityInput<Result>,
            next: (CompleteAsyncActivityInput<Result>) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.RespondActivityTaskCompleted.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setCompleteAsyncActivity(input: input)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func failAsyncActivity(
            input: FailAsyncActivityInput,
            next: (FailAsyncActivityInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.RespondActivityTaskFailed.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setFailAsyncActivity(input: input)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func reportCancellationAsyncActivity(
            input: ReportCancellationAsyncActivityInput,
            next: (ReportCancellationAsyncActivityInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName:
                    Temporal_Api_Workflowservice_V1_WorkflowService.Method.RespondActivityTaskCanceled.descriptor.fullyQualifiedMethod,
                setRequestAttributes: { span in
                    span.setReportCancellationAsyncActivity(input: input)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }
    }
}
