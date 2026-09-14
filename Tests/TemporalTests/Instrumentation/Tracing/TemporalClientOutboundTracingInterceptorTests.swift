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
import GRPCCore
import GRPCNIOTransportHTTP2Posix
import Logging
import SwiftProtobuf
import Temporal
import TemporalTestKit
import Testing
import Tracing

@Suite(.tags(.instrumentationTests))
struct TemporalClientOutboundTracingInterceptorTests {
    @Workflow
    struct VoidWorkflow {
        mutating func run(context: WorkflowContext<Self>, input: Void) async {}
    }

    struct TemporalTraceID: Decodable {
        let traceparent: UUID  // matches default Temporal tracing payload key
    }

    // Test attributes
    private static let workflowId = UUID().uuidString
    private static let runId = UUID().uuidString
    private static let queryName = "TestQueryName"
    private static let queryWorkflowInput = QueryWorkflowInput<VoidWorkflow.Input>(
        id: Self.workflowId,
        runID: Self.runId,
        queryName: Self.queryName,
        rejectionCondition: .notOpen,
        headers: [:],
        input: ()
    )
    private static let listQuery = "WorkflowType = 'VoidWorkflow'"
    private static let listLimit = 5

    // the trace recording plumbing is shared across the client interceptor methods, so assert it in depth on
    // one of them only; per-method span attributes are covered separately
    @Test
    func tracingInterceptorTemporalClient() async throws {
        let tracer = TestTracer()
        var serviceContext = ServiceContext.topLevel
        let traceIDString = UUID().uuidString
        serviceContext.traceID = traceIDString

        try await ServiceContext.withValue(serviceContext) {
            let interceptor = try #require(
                TemporalClientTracingInterceptor(
                    tracer: tracer
                ).clientOutboundInterceptor
            )

            _ = try await interceptor.queryWorkflow(
                input: Self.queryWorkflowInput,
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
                forSpan:
                    "\(Api.Workflowservice.V1.WorkflowService.Method.QueryWorkflow.descriptor.fullyQualifiedMethod):\(Self.queryName)",
                tracer: tracer
            ) { events in
                // No events are recorded
                #expect(events.isEmpty)
            } assertAttributes: { attributes in
                #expect(attributes[TemporalTracingKeys.workflowId]?.toSpanAttribute() == .string(Self.workflowId))
                #expect(attributes[TemporalTracingKeys.workflowRunId]?.toSpanAttribute() == .string(Self.runId))
                #expect(attributes[TemporalTracingKeys.workflowQueryName]?.toSpanAttribute() == .string(Self.queryName))
                #expect(
                    attributes[TemporalTracingKeys.workflowQueryRejectCondition]?.toSpanAttribute()
                        == "\(Api.Enums.V1.QueryRejectCondition.notOpen)"
                )
            } assertStatus: { status in
                #expect(status == nil)
            } assertErrors: { errors in
                #expect(errors == [])
            }
        }
    }

    @Test
    func tracingInterceptorTemporalClientFailure() async throws {
        let tracer = TestTracer()
        var serviceContext = ServiceContext.topLevel
        let traceIDString = UUID().uuidString
        serviceContext.traceID = traceIDString

        try await ServiceContext.withValue(serviceContext) {
            let interceptor = try #require(
                TemporalClientTracingInterceptor(
                    tracer: tracer
                ).clientOutboundInterceptor
            )

            do {
                _ = try await interceptor.queryWorkflow(
                    input: Self.queryWorkflowInput,
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
                print("threw")
                assertTestSpanComponents(
                    forSpan:
                        "\(Api.Workflowservice.V1.WorkflowService.Method.QueryWorkflow.descriptor.fullyQualifiedMethod):\(Self.queryName)",
                    tracer: tracer
                ) { events in
                    // No events are recorded
                    #expect(events.isEmpty)
                } assertAttributes: { attributes in
                    #expect(attributes[TemporalTracingKeys.workflowId]?.toSpanAttribute() == .string(Self.workflowId))
                    #expect(attributes[TemporalTracingKeys.workflowRunId]?.toSpanAttribute() == .string(Self.runId))
                    #expect(attributes[TemporalTracingKeys.workflowQueryName]?.toSpanAttribute() == .string(Self.queryName))
                    #expect(
                        attributes[TemporalTracingKeys.workflowQueryRejectCondition]?.toSpanAttribute()
                            == "\(Api.Enums.V1.QueryRejectCondition.notOpen)"
                    )
                } assertStatus: { status in
                    #expect(status == .some(.init(code: .error)))
                } assertErrors: { errors in
                    #expect(errors == [.testError])
                }
            }
        }
    }

    /// The workflow list query belongs under the workflow key; the schedule key is reserved for
    /// ``listSchedules``. `next` throws so the test does not have to stand up a result sequence.
    @Test
    func listWorkflowsRecordsQueryUnderWorkflowKey() async throws {
        let tracer = TestTracer()
        let interceptor = try #require(
            TemporalClientTracingInterceptor(
                tracer: tracer
            ).clientOutboundInterceptor
        )

        do {
            _ = try await interceptor.listWorkflows(
                input: ListWorkflowsInput(query: Self.listQuery, limit: Self.listLimit),
                next: { _ -> AsyncThrowingStream<WorkflowExecution, any Error> in
                    throw TracingInterceptorTestError.testError
                }
            )

            Issue.record("Should have thrown")
        } catch {
            assertTestSpanComponents(
                forSpan:
                    Api.Workflowservice.V1.WorkflowService.Method.ListWorkflowExecutions.descriptor.fullyQualifiedMethod,
                tracer: tracer
            ) { events in
                #expect(events.isEmpty)
            } assertAttributes: { attributes in
                #expect(attributes[TemporalTracingKeys.workflowListQuery]?.toSpanAttribute() == .string(Self.listQuery))
                #expect(attributes[TemporalTracingKeys.scheduleListQuery] == nil)
                #expect(attributes[TemporalTracingKeys.workflowListLimit]?.toSpanAttribute() == .int64(Int64(Self.listLimit)))
            } assertStatus: { status in
                #expect(status == .some(.init(code: .error)))
            } assertErrors: { errors in
                #expect(errors == [.testError])
            }
        }
    }
}
