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

import Tracing

extension TemporalWorkerTracingInterceptor {
    /// Workflow inbound interceptor that instruments all worker inbound workflow requests with distributed tracing.
    public struct WorkflowInbound: WorkflowInboundInterceptor {
        private let traceRecording: TemporalTraceRecording

        /// Create the worker workflow inbound interceptor.
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

        public func executeWorkflow<Workflow>(
            input: ExecuteWorkflowInput<Workflow>,
            next: (ExecuteWorkflowInput<Workflow>) async throws -> Workflow.Output
        ) async throws -> Workflow.Output {
            try await self.traceRecording.recordInbound(
                spanName: "RunWorkflow:\(Temporal.Workflow.info.workflowName)",
                headers: input.headers,
                setSpanAttributes: { span in
                    span.setWorkerExecuteWorkflowSpanAttributes(info: Temporal.Workflow.info)
                },
                next: {
                    try await next(input)
                }
            )
        }

        public func handleSignal<Signal>(
            input: HandleSignalInput<Signal>,
            next: (HandleSignalInput<Signal>) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordInbound(
                spanName: "HandleSignal:\(input.name)",
                headers: input.headers,
                setSpanAttributes: { span in
                    span.setWorkerHandleSignalSpanAttributes(signalName: input.name, workflowInfo: Workflow.info)
                },
                next: {
                    try await next(input)
                }
            )
        }

        public func handleQuery<Query>(
            input: HandleQueryInput<Query>,
            next: (HandleQueryInput<Query>) throws -> Query.Output
        ) throws -> Query.Output {
            try self.traceRecording.recordInbound(
                spanName: "HandleQuery:\(input.name)",
                headers: input.headers,
                setSpanAttributes: { span in
                    span.setWorkerHandleQuerySpanAttributes(queryId: input.id, queryName: input.name, workflowInfo: Workflow.info)
                },
                next: {
                    try next(input)
                }
            )
        }

        public func handleUpdate<Update>(
            input: HandleUpdateInput<Update>,
            next: (HandleUpdateInput<Update>) async throws -> Update.Output
        ) async throws -> Update.Output {
            try await self.traceRecording.recordInbound(
                spanName: "HandleUpdate:\(input.name)",
                headers: input.headers,
                setSpanAttributes: { span in
                    span.setWorkerHandleUpdateSpanAttributes(updateId: input.id, updateName: input.name, workflowInfo: Workflow.info)
                },
                next: {
                    try await next(input)
                }
            )
        }

        public func validateUpdate<Update>(
            input: HandleUpdateInput<Update>,
            next: (HandleUpdateInput<Update>) throws -> Void
        ) throws {
            try self.traceRecording.recordInbound(
                spanName: "ValidateUpdate:\(input.name)",
                headers: input.headers,
                setSpanAttributes: { span in
                    span.setWorkerHandleUpdateSpanAttributes(updateId: input.id, updateName: input.name, workflowInfo: Workflow.info)
                },
                next: {
                    try next(input)
                }
            )
        }
    }
}
