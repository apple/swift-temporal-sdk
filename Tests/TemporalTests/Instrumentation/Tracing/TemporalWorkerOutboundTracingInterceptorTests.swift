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
import Temporal
import Testing
import Tracing

#if !(os(Linux) && swift(>=6.2))  // TODO: reenable once Swift 6.2 compiler crash / Swift 6.1 runtime crash on Linux (in RELEASE only) is fixed
@Suite(.tags(.instrumentationTests))
struct TemporalWorkerOutboundTracingInterceptorTests {
    @Workflow
    final class VoidWorkflow {
        func run(input: Void) async {}
    }

    struct TemporalTraceID: Decodable {
        let traceparent: UUID  // matches default Temporal tracing payload key
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
    private static let workflowContext = WorkflowContext.makeTestContext(
        info: .init(
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
    )

    // only test one outbound workflow worker interceptor, as logic is the same (except for the setting of span attributes)
    @Test
    func outboundTracingWorkflowWorker() async throws {
        let tracer = TestTracer()
        var serviceContext = ServiceContext.topLevel
        let traceIDString = UUID().uuidString
        serviceContext.traceID = traceIDString

        try await Workflow.$context.withValue(Self.workflowContext) {
            try await ServiceContext.withValue(serviceContext) {
                let interceptor = try #require(
                    TemporalWorkerTracingInterceptor(
                        tracer: tracer
                    ).makeWorkflowOutboundInterceptor()
                )

                _ = try await interceptor.executeActivity(
                    input: ScheduleActivityInput(
                        name: Self.activityInfo.name,
                        options: ActivityOptions(
                            scheduleToCloseTimeout: Self.scheduleToCloseTimeout,
                            disableEagerActivityExecution: Self.disableEagerActivityExecution,
                            cancellationType: Self.cancellationType,
                            versioningIntent: Self.versioningIntent
                        ),
                        headers: [:],
                        input: ()
                    ),
                    next: { input in
                        // Assert that headers contain the injected traceID
                        let traceHeaderPayload = try #require(
                            input.headers.first(where: { key, value in
                                key == "_tracer-data"  // default Temporal tracing header key
                            })?.1 as? TemporalPayload
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
    }

    @Test
    func outboundTracingWorkflowWorkerFailure() async throws {
        let tracer = TestTracer()
        var serviceContext = ServiceContext.topLevel
        let traceIDString = UUID().uuidString
        serviceContext.traceID = traceIDString

        try await Workflow.$context.withValue(Self.workflowContext) {
            try await ServiceContext.withValue(serviceContext) {
                let interceptor = try #require(
                    TemporalWorkerTracingInterceptor(
                        tracer: tracer
                    ).makeWorkflowOutboundInterceptor()
                )

                do {
                    _ = try await interceptor.executeActivity(
                        input: ScheduleActivityInput(
                            name: Self.activityInfo.name,
                            options: ActivityOptions(
                                scheduleToCloseTimeout: Self.scheduleToCloseTimeout,
                                disableEagerActivityExecution: Self.disableEagerActivityExecution,
                                cancellationType: Self.cancellationType,
                                versioningIntent: Self.versioningIntent
                            ),
                            headers: [:],
                            input: ()
                        ),
                        next: { input in
                            // Assert that headers contain the injected traceID
                            let traceHeaderPayload = try #require(
                                input.headers.first(where: { key, value in
                                    key == "_tracer-data"  // default Temporal tracing header key
                                })?.1 as? TemporalPayload
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
    }
}
#endif
