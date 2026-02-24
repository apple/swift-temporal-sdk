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
import Temporal
import Testing
import Tracing

@Suite(.tags(.instrumentationTests))
struct TemporalWorkerInboundTracingInterceptorTests {
    @Workflow
    final class VoidWorkflow {
        func run(input: Void) async {}
    }

    struct TemporalTraceID: Encodable {
        let traceparent: UUID  // matches default Temporal tracing payload key
    }

    // Test attributes
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

    // only test one inbound workflow worker interceptor, as logic is the same (except for the setting of span attributes)
    @Test
    func inboundTracingWorkflowWorker() async throws {
        let tracer = TestTracer()
        let traceID = UUID()

        let interceptor = try #require(
            TemporalWorkerTracingInterceptor(
                tracer: tracer
            ).makeWorkflowInboundInterceptor()
        )

        let mockIncomingHeaders: [String: Api.Common.V1.Payload] = await [
            // reflects structure of the default Temporal tracing header
            "_tracer-data": try DataConverter.default.convertValue(
                TemporalTraceID(traceparent: traceID)
            )
        ]
        try await Workflow.$context.withValue(Self.workflowContext) {
            _ = try await interceptor.executeWorkflow(
                input: ExecuteWorkflowInput<VoidWorkflow>(
                    headers: mockIncomingHeaders,
                    input: ()
                )
            ) { input in
                // Make sure we get the metadata injected into our service context
                #expect(ServiceContext.current?.traceID == traceID.uuidString)
            }
        }

        assertTestSpanComponents(
            forSpan: "RunWorkflow:\(Self.workflowName)",
            tracer: tracer
        ) { events in
            // No events are recorded
            #expect(events.isEmpty)
        } assertAttributes: { attributes in
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

    @Test
    func inboundTracingWorkflowWorkerFailure() async throws {
        let tracer = TestTracer()
        let traceID = UUID()

        let interceptor = try #require(
            TemporalWorkerTracingInterceptor(
                tracer: tracer
            ).makeWorkflowInboundInterceptor()
        )

        let mockIncomingHeaders: [String: Api.Common.V1.Payload] = await [
            // reflects structure of the default Temporal tracing header
            "_tracer-data": try DataConverter.default.convertValue(
                TemporalTraceID(traceparent: traceID)
            )
        ]

        do {
            try await Workflow.$context.withValue(Self.workflowContext) {
                _ = try await interceptor.executeWorkflow(
                    input: ExecuteWorkflowInput<VoidWorkflow>(
                        headers: mockIncomingHeaders,
                        input: ()
                    )
                ) { input in
                    // Make sure we get the metadata injected into our service context
                    #expect(ServiceContext.current?.traceID == traceID.uuidString)

                    // Simulates an error within the RPC
                    throw TracingInterceptorTestError.testError
                }
            }

            Issue.record("Should have thrown")
        } catch {
            assertTestSpanComponents(
                forSpan: "RunWorkflow:\(Self.workflowName)",
                tracer: tracer
            ) { events in
                // No events are recorded
                #expect(events.isEmpty)
            } assertAttributes: { attributes in
                // Don't retest attributes from above
            } assertStatus: { status in
                #expect(status == .some(.init(code: .error)))
            } assertErrors: { errors in
                #expect(errors == [.testError])
            }
        }
    }

    private struct TestActivityName: ActivityDefinition {
        func run(input: Void) async throws {}
    }

    @Test
    func inboundTracingActivityWorker() async throws {
        let tracer = TestTracer()
        let traceID = UUID()

        let interceptor = try #require(
            TemporalWorkerTracingInterceptor(
                tracer: tracer
            ).makeActivityInboundInterceptor()
        )

        let mockIncomingHeaders: [String: Api.Common.V1.Payload] = await [
            // reflects structure of the default Temporal tracing header
            "_tracer-data": try DataConverter.default.convertValue(
                TemporalTraceID(traceparent: traceID)
            )
        ]

        _ = try await interceptor.executeActivity(
            input: ExecuteActivityInput(
                definition: TestActivityName(),
                headers: mockIncomingHeaders,
                input: ()
            )
        ) { input in
            // Make sure we get the metadata injected into our service context
            #expect(ServiceContext.current?.traceID == traceID.uuidString)

            return ()
        }

        assertTestSpanComponents(
            forSpan: "RunActivity:\(TestActivityName.name)",
            tracer: tracer
        ) { events in
            // No events are recorded
            #expect(events.isEmpty)
        } assertAttributes: { attributes in
            #expect(attributes[TemporalTracingKeys.activityName]?.toSpanAttribute() == .string(TestActivityName.name))
        } assertStatus: { status in
            #expect(status == nil)
        } assertErrors: { errors in
            #expect(errors == [])
        }
    }

    @Test
    func inboundTracingActivityWorkerFailure() async throws {
        let tracer = TestTracer()
        let traceID = UUID()

        let interceptor = try #require(
            TemporalWorkerTracingInterceptor(
                tracer: tracer
            ).makeActivityInboundInterceptor()
        )

        let mockIncomingHeaders: [String: Api.Common.V1.Payload] = await [
            // reflects structure of the default Temporal tracing header
            "_tracer-data": try DataConverter.default.convertValue(
                TemporalTraceID(traceparent: traceID)
            )
        ]

        do {
            _ = try await interceptor.executeActivity(
                input: ExecuteActivityInput(
                    definition: TestActivityName(),
                    headers: mockIncomingHeaders,
                    input: ()
                )
            ) { input in
                // Make sure we get the metadata injected into our service context
                #expect(ServiceContext.current?.traceID == traceID.uuidString)

                // Simulates an error within the RPC
                throw TracingInterceptorTestError.testError
            }

            Issue.record("Should have thrown")
        } catch {
            assertTestSpanComponents(
                forSpan: "RunActivity:\(TestActivityName.name)",
                tracer: tracer
            ) { events in
                // No events are recorded
                #expect(events.isEmpty)
            } assertAttributes: { attributes in
                // Don't retest attributes from above
            } assertStatus: { status in
                #expect(status == .some(.init(code: .error)))
            } assertErrors: { errors in
                #expect(errors == [.testError])
            }
        }
    }
}

extension WorkflowContext {
    static func makeTestContext(info: WorkflowInfo) -> WorkflowContext {
        .init(
            stateMachine: .init(
                executor: .init(),
                payloadConverter: DefaultPayloadConverter(),
                failureConverter: DefaultFailureConverter()
            ),
            workflowInfo: info,
            payloadConverter: DefaultPayloadConverter(),
            outboundInterceptors: [],
            logger: .init(label: "TestWorkflowContext")
        )
    }
}
