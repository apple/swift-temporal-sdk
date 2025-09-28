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
    /// Workflow outbound interceptor that instruments all worker outbound workflow requests with distributed tracing.
    public struct WorkflowOutbound: WorkflowOutboundInterceptor {
        private let traceRecording: TemporalTraceRecording

        /// Create the worker workflow outbound interceptor.
        /// - Parameters:
        ///    - tracer: The `Tracer` instance to use for creating spans.
        ///    - tracingHeaderKey: The name of the Temporal tracing header key.
        package init(tracer: any Tracer, tracingHeaderKey: String) {
            self.traceRecording = TemporalTraceRecording(
                tracer: tracer,
                tracingHeaderKey: tracingHeaderKey
            )
        }

        public func handleSleep(
            input: HandleSleepInput,
            next: (HandleSleepInput) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName: "HandleSleep",
                setRequestAttributes: { span in
                    span.setWorkerHandleSleepSpanAttributes(sleepInput: input)
                },
                next: { _ in
                    try await next(input)
                }
            )
        }

        public func executeActivity<each Input, Output: Sendable>(
            input: ScheduleActivityInput<repeat each Input>,
            next: (ScheduleActivityInput<repeat each Input>) async throws -> Output
        ) async throws -> Output {
            try await self.traceRecording.recordOutbound(
                spanName: "StartActivity:\(input.name)",
                headers: input.headers,
                setRequestAttributes: { span in
                    span.setWorkerExecuteActivityRequestSpanAttributes(
                        workflowInfo: Workflow.info,
                        activityName: input.name,
                        activityOptions: input.options
                    )
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }

        public func executeLocalActivity<each Input, Output: Sendable>(
            input: ScheduleLocalActivityInput<repeat each Input>,
            next: (ScheduleLocalActivityInput<repeat each Input>) async throws -> Output
        ) async throws -> Output {
            try await self.traceRecording.recordOutbound(
                spanName: "StartLocalActivity:\(input.name)",
                headers: input.headers,
                setRequestAttributes: { span in
                    span.setWorkerExecuteLocalActivityRequestSpanAttributes(
                        workflowInfo: Workflow.info,
                        activityName: input.name,
                        activityOptions: input.options
                    )
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }

        public func makeContinueAsNewError<each Input>(
            input: MakeContinueAsNewErrorInput<repeat each Input>,
            next: (MakeContinueAsNewErrorInput<repeat each Input>) async throws -> ContinueAsNewError
        ) async throws -> ContinueAsNewError {
            try await self.traceRecording.recordOutbound(
                spanName: "CreateContinuedAsNewError:\(Workflow.info.workflowName)",
                headers: input.headers,
                setRequestAttributes: { span in
                    span.setWorkerContinueAsNewRequestSpanAttributes(
                        workflowInfo: Workflow.info,
                        options: input.options
                    )
                },
                setResponseAttributes: { span, response in
                    span.setWorkerContinueAsNewRespondSpanAttributes(
                        continueAsNewError: response
                    )
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }

        public func startChildWorkflow<each Input>(
            input: StartChildWorkflowInput<repeat each Input>,
            next: (StartChildWorkflowInput<repeat each Input>) async throws -> UntypedChildWorkflowHandle
        ) async throws -> UntypedChildWorkflowHandle {
            try await self.traceRecording.recordOutbound(
                spanName: "SignalChildWorkflow:\(input.name)",
                headers: input.headers,
                setRequestAttributes: { span in
                    span.setWorkerStartChildWorkflowRequestSpanAttributes(
                        workflowInfo: Workflow.info,
                        options: input.options
                    )
                },
                setResponseAttributes: { span, handle in
                    span.setWorkerStartChildWorkflowResponseSpanAttributes(
                        childHandle: handle
                    )
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }

        public func signalWorkflow<each Input>(
            input: SignalChildWorkflowInput<repeat each Input>,
            next: (SignalChildWorkflowInput<repeat each Input>) async throws -> Void
        ) async throws {
            try await self.traceRecording.recordOutbound(
                spanName: "SignalExternalWorkflow:\(input.name)",
                headers: input.headers,
                setRequestAttributes: { span in
                    span.setWorkerSignalWorkflowSpanAttributes(
                        workflowID: input.id,
                        signalName: input.name
                    )
                },
                next: { headers in
                    var input = input
                    input.headers = headers
                    return try await next(input)
                }
            )
        }
    }
}
