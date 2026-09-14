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

import Foundation
import Logging
import SwiftProtobuf
import Synchronization
import Temporal
import Testing
import Tracing

@Suite(.tags(.instrumentationTests))
struct TemporalWorkerOutboundTracingInterceptorTests {
    @Workflow
    struct VoidWorkflow {
        mutating func run(context: WorkflowContext<Self>, input: Void) async {}
    }

    struct TemporalTraceID: Decodable {
        let traceparent: UUID  // matches default Temporal tracing payload key
    }

    /// The full context the interceptor writes onto the Temporal headers.
    struct PropagatedContext: Decodable {
        let traceparent: String
        let spanid: String
    }

    // Test attributes
    private static let activityInfo = ActivityExecutionInfo(name: "test123")
    private static let scheduleToCloseTimeout: Duration = .seconds(3)
    private static let disableEagerActivityExecution: Bool = true
    private static let cancellationType: ActivityOptions.CancellationType = .abandon
    private static let versioningIntent: VersioningIntent = .compatible

    private static let attempt = 3
    private static let startTime: Date = .now
    private static let workflowName = "TestWorkflow"
    private static let workflowID = UUID().uuidString
    private static let workflowType = "TestWorkflowType"
    private static let runID = UUID().uuidString
    private static let taskQueue = "TestTaskQueue"
    private static let namespace = "TestNamespace"
    private static let testWorkflowInfo = WorkflowInfo(
        attempt: Self.attempt,
        startTime: Self.startTime,
        workflowName: Self.workflowName,
        workflowID: Self.workflowID,
        workflowType: Self.workflowType,
        runID: Self.runID,
        taskQueue: Self.taskQueue,
        namespace: Self.namespace,
        headers: [:]
    )

    // Attributes of the workflows targeted by the outbound operations, deliberately distinct from the
    // calling workflow's attributes above.
    private static let childWorkflowName = "TestChildWorkflow"
    private static let childWorkflowID = UUID().uuidString
    private static let childTaskQueue = "TestChildTaskQueue"
    private static let externalWorkflowID = UUID().uuidString
    private static let externalRunID = UUID().uuidString
    private static let signalName = "TestSignal"

    // the trace recording plumbing is shared across the outbound interceptors, so assert it in depth on one
    // of them only; the per-operation span names and attributes are covered by the tests further below
    @Test
    func outboundTracingWorkflowWorker() async throws {
        let tracer = TestTracer()
        var serviceContext = ServiceContext.topLevel
        let traceIDString = UUID().uuidString
        serviceContext.traceID = traceIDString

        try await ServiceContext.withValue(serviceContext) {
            let interceptor = try #require(
                TemporalWorkerTracingInterceptor(
                    tracer: tracer
                ).workflowOutboundInterceptor
            )

            let input = ScheduleActivityInput<Void>(
                info: Self.testWorkflowInfo,
                name: Self.activityInfo.name,
                options: ActivityOptions(
                    scheduleToCloseTimeout: Self.scheduleToCloseTimeout,
                    disableEagerActivityExecution: Self.disableEagerActivityExecution,
                    cancellationType: Self.cancellationType,
                    versioningIntent: Self.versioningIntent
                ),
                headers: [:],
                input: ()
            )

            _ = try await interceptor.executeActivity(
                input: input,
                next: { input in
                    // Assert that headers contain the injected traceID
                    let traceHeaderPayload = try #require(
                        input.headers.first(where: { key, value in
                            key == "_tracer-data"  // default Temporal tracing header key
                        })?.1 as? Api.Common.V1.Payload
                    )

                    let traceHeader: TemporalTraceID = try DataConverter.default.payloadConverter.convertPayloadHandlingVoid(
                        traceHeaderPayload
                    )
                    #expect(traceHeader.traceparent.uuidString == traceIDString)

                    return ()
                }
            )

            assertTestSpanComponents(
                forSpan: "StartActivity:\(Self.activityInfo.name)",
                tracer: tracer
            ) { events in
                // No events are recorded
                #expect(events.isEmpty)
            } assertAttributes: { attributes in
                #expect(attributes[TemporalTracingKeys.activityName]?.toSpanAttribute() == .string(Self.activityInfo.name))
                #expect(attributes[TemporalTracingKeys.activityCancellationType]?.toSpanAttribute() == .string(Self.cancellationType.description))
                #expect(
                    attributes[TemporalTracingKeys.activityScheduleToCloseTimeout]?.toSpanAttribute()
                        == .string(Self.scheduleToCloseTimeout.description)
                )
                #expect(
                    attributes[TemporalTracingKeys.activityDisableEagerExecution]?.toSpanAttribute()
                        == .string(Self.disableEagerActivityExecution.description)
                )
                #expect(attributes[TemporalTracingKeys.activityVersioningIntent]?.toSpanAttribute() == .string(Self.versioningIntent.description))

                #expect(attributes[TemporalTracingKeys.workflowType]?.toSpanAttribute() == .string(Self.workflowType))
                #expect(attributes[TemporalTracingKeys.workflowRunId]?.toSpanAttribute() == .string(Self.runID))
                #expect(attributes[TemporalTracingKeys.workflowId]?.toSpanAttribute() == .string(Self.workflowID))
                #expect(attributes[TemporalTracingKeys.workflowStartTime]?.toSpanAttribute() == .string(Self.startTime.description))
                #expect(attributes[TemporalTracingKeys.workflowName]?.toSpanAttribute() == .string(Self.workflowName))
                #expect(attributes[TemporalTracingKeys.workflowTaskQueue]?.toSpanAttribute() == .string(Self.taskQueue))
                #expect(attributes[TemporalTracingKeys.workflowNamespace]?.toSpanAttribute() == .string(Self.namespace))
                #expect(attributes[TemporalTracingKeys.workflowAttempt]?.toSpanAttribute() == .int64(Int64(Self.attempt)))
            } assertStatus: { status in
                #expect(status == nil)
            } assertErrors: { errors in
                #expect(errors == [])
            }
        }
    }

    @Test
    func outboundTracingWorkflowWorkerFailure() async throws {
        let tracer = TestTracer()
        var serviceContext = ServiceContext.topLevel
        let traceIDString = UUID().uuidString
        serviceContext.traceID = traceIDString

        try await ServiceContext.withValue(serviceContext) {
            let interceptor = try #require(
                TemporalWorkerTracingInterceptor(
                    tracer: tracer
                ).workflowOutboundInterceptor
            )

            do {
                let input = ScheduleActivityInput<Void>(
                    info: Self.testWorkflowInfo,
                    name: Self.activityInfo.name,
                    options: ActivityOptions(
                        scheduleToCloseTimeout: Self.scheduleToCloseTimeout,
                        disableEagerActivityExecution: Self.disableEagerActivityExecution,
                        cancellationType: Self.cancellationType,
                        versioningIntent: Self.versioningIntent
                    ),
                    headers: [:],
                    input: ()
                )

                _ = try await interceptor.executeActivity(
                    input: input,
                    next: { input in
                        // Assert that headers contain the injected traceID
                        let traceHeaderPayload = try #require(
                            input.headers.first(where: { key, value in
                                key == "_tracer-data"  // default Temporal tracing header key
                            })?.1 as? Api.Common.V1.Payload
                        )

                        let traceHeader: TemporalTraceID = try DataConverter.default.payloadConverter.convertPayloadHandlingVoid(
                            traceHeaderPayload
                        )
                        #expect(traceHeader.traceparent.uuidString == traceIDString)

                        // Simulates an error within the RPC
                        throw TracingInterceptorTestError.testError
                    }
                )
                Issue.record("Should have thrown")
            } catch {
                assertTestSpanComponents(
                    forSpan: "StartActivity:\(Self.activityInfo.name)",
                    tracer: tracer
                ) { events in
                    // No events are recorded
                    #expect(events.isEmpty)
                } assertAttributes: { _ in
                    // don't recheck attributes from test above
                } assertStatus: { status in
                    #expect(status == .some(.init(code: .error)))
                } assertErrors: { errors in
                    #expect(errors == [.testError])
                }
            }
        }
    }

    /// The trace recording plumbing is shared, but the span name is written out per operation, so a name
    /// copied from a neighbouring method is only caught by asserting each one individually.
    @Test
    func outboundSpanNames() async throws {
        let tracer = TestTracer()
        let interceptor = try #require(
            TemporalWorkerTracingInterceptor(
                tracer: tracer
            ).workflowOutboundInterceptor
        )

        try await interceptor.handleSleep(
            input: HandleSleepInput(info: Self.testWorkflowInfo, duration: .seconds(1)),
            next: { _ in }
        )

        try await interceptor.executeLocalActivity(
            input: ScheduleLocalActivityInput<Void>(
                info: Self.testWorkflowInfo,
                name: Self.activityInfo.name,
                options: LocalActivityOptions(scheduleToCloseTimeout: Self.scheduleToCloseTimeout),
                headers: [:],
                input: ()
            ),
            next: { _ -> Void in }
        )

        try await interceptor.signalWorkflow(
            input: SignalChildWorkflowInput<Void>(
                id: Self.childWorkflowID,
                name: Self.signalName,
                headers: [:],
                input: ()
            ),
            next: { _ in }
        )

        try await interceptor.signalExternalWorkflow(
            input: SignalExternalWorkflowInput<Void>(
                info: Self.testWorkflowInfo,
                id: Self.externalWorkflowID,
                runId: Self.externalRunID,
                name: Self.signalName,
                headers: [:],
                input: ()
            ),
            next: { _ in }
        )

        #expect(tracer.getSpan(ofOperation: "StartTimer") != nil)
        #expect(tracer.getSpan(ofOperation: "StartLocalActivity:\(Self.activityInfo.name)") != nil)
        // A child signal and an external signal must remain distinguishable, as they are in the other SDKs.
        #expect(tracer.getSpan(ofOperation: "SignalChildWorkflow:\(Self.signalName)") != nil)
        #expect(tracer.getSpan(ofOperation: "SignalExternalWorkflow:\(Self.signalName)") != nil)
    }

    /// The child workflow, not the parent, is the subject of the `StartChildWorkflow` span. `next` throws so
    /// that the response attributes do not mask what the request side recorded.
    @Test
    func outboundStartChildWorkflowRecordsChildIdentity() async throws {
        let tracer = TestTracer()
        let interceptor = try #require(
            TemporalWorkerTracingInterceptor(
                tracer: tracer
            ).workflowOutboundInterceptor
        )

        do {
            _ = try await interceptor.startChildWorkflow(
                input: StartChildWorkflowInput<Void>(
                    info: Self.testWorkflowInfo,
                    name: Self.childWorkflowName,
                    options: ChildWorkflowOptions(
                        id: Self.childWorkflowID,
                        taskQueue: Self.childTaskQueue
                    ),
                    headers: [:],
                    input: ()
                ),
                next: { _ in
                    throw TracingInterceptorTestError.testError
                }
            )
            Issue.record("Should have thrown")
        } catch {
            assertTestSpanComponents(
                forSpan: "StartChildWorkflow:\(Self.childWorkflowName)",
                tracer: tracer
            ) { events in
                #expect(events.isEmpty)
            } assertAttributes: { attributes in
                #expect(attributes[TemporalTracingKeys.workflowId]?.toSpanAttribute() == .string(Self.childWorkflowID))
                #expect(attributes[TemporalTracingKeys.workflowTaskQueue]?.toSpanAttribute() == .string(Self.childTaskQueue))
                // The calling workflow is still recorded for context.
                #expect(attributes[TemporalTracingKeys.workflowName]?.toSpanAttribute() == .string(Self.workflowName))
                #expect(attributes[TemporalTracingKeys.workflowRunId]?.toSpanAttribute() == .string(Self.runID))
            } assertStatus: { status in
                #expect(status == .some(.init(code: .error)))
            } assertErrors: { errors in
                #expect(errors == [.testError])
            }
        }
    }

    /// Without the trace context on the headers, the signalled workflow's `HandleSignal` span has no link
    /// back to the signalling workflow.
    @Test
    func outboundSignalExternalWorkflowPropagatesTraceContext() async throws {
        let tracer = TestTracer()
        var serviceContext = ServiceContext.topLevel
        let traceIDString = UUID().uuidString
        serviceContext.traceID = traceIDString

        try await ServiceContext.withValue(serviceContext) {
            let interceptor = try #require(
                TemporalWorkerTracingInterceptor(
                    tracer: tracer
                ).workflowOutboundInterceptor
            )

            try await interceptor.signalExternalWorkflow(
                input: SignalExternalWorkflowInput<Void>(
                    info: Self.testWorkflowInfo,
                    id: Self.externalWorkflowID,
                    runId: Self.externalRunID,
                    name: Self.signalName,
                    headers: [:],
                    input: ()
                ),
                next: { input in
                    let traceHeaderPayload = try #require(
                        input.headers.first(where: { key, _ in
                            key == "_tracer-data"  // default Temporal tracing header key
                        })?.1 as? Api.Common.V1.Payload
                    )

                    let traceHeader: TemporalTraceID = try DataConverter.default.payloadConverter.convertPayloadHandlingVoid(
                        traceHeaderPayload
                    )
                    #expect(traceHeader.traceparent.uuidString == traceIDString)
                }
            )

            assertTestSpanComponents(
                forSpan: "SignalExternalWorkflow:\(Self.signalName)",
                tracer: tracer
            ) { events in
                #expect(events.isEmpty)
            } assertAttributes: { attributes in
                // The signalled workflow's identifiers take precedence over the signalling workflow's.
                #expect(attributes[TemporalTracingKeys.workflowId]?.toSpanAttribute() == .string(Self.externalWorkflowID))
                #expect(attributes[TemporalTracingKeys.workflowRunId]?.toSpanAttribute() == .string(Self.externalRunID))
                #expect(attributes[TemporalTracingKeys.workflowSignalName]?.toSpanAttribute() == .string(Self.signalName))
                #expect(attributes[TemporalTracingKeys.workflowName]?.toSpanAttribute() == .string(Self.workflowName))
            } assertStatus: { status in
                #expect(status == nil)
            } assertErrors: { errors in
                #expect(errors == [])
            }
        }
    }

    /// The propagated context must identify the span this interceptor just started, not whatever span was
    /// current when the operation was invoked — otherwise the receiving side parents onto the caller's
    /// caller and the outbound span is missing from the hierarchy.
    @Test
    func outboundPropagatesItsOwnSpanContext() async throws {
        let tracer = TestTracer()
        var serviceContext = ServiceContext.topLevel
        serviceContext.traceID = UUID().uuidString
        serviceContext.spanID = UUID().uuidString
        let callerSpanID = try #require(serviceContext.spanID)

        try await ServiceContext.withValue(serviceContext) {
            let interceptor = try #require(
                TemporalWorkerTracingInterceptor(
                    tracer: tracer
                ).workflowOutboundInterceptor
            )

            let propagated: Mutex<PropagatedContext?> = .init(nil)

            try await interceptor.signalExternalWorkflow(
                input: SignalExternalWorkflowInput<Void>(
                    info: Self.testWorkflowInfo,
                    id: Self.externalWorkflowID,
                    name: Self.signalName,
                    headers: [:],
                    input: ()
                ),
                next: { input in
                    let payload = try #require(input.headers["_tracer-data"])
                    propagated.withLock {
                        $0 = try? DataConverter.default.payloadConverter.convertPayloadHandlingVoid(payload)
                    }
                }
            )

            let span = try #require(tracer.getSpan(ofOperation: "SignalExternalWorkflow:\(Self.signalName)"))
            let propagatedContext = try #require(propagated.withLock { $0 })

            #expect(propagatedContext.spanid == span.context.spanID)
            #expect(propagatedContext.spanid != callerSpanID)
            // The trace is continued either way.
            #expect(propagatedContext.traceparent == serviceContext.traceID)
        }
    }
}
