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

import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowHeaderTests {
        final class Interceptor: WorkerInterceptor, ClientInterceptor {
            struct Result: Codable, Hashable {
                var key1 = ""
                var key2 = 0
                var signal1 = ""
                var signal2 = 0
                var query1 = ""
                var query2 = 0
            }
            let result = Mutex<Result>(.init())

            struct Outbound: ClientOutboundInterceptor {
                func startWorkflow<each Input>(
                    input: StartWorkflowInput<repeat each Input>,
                    next: (StartWorkflowInput<repeat each Input>) async throws -> UntypedWorkflowHandle
                ) async throws -> UntypedWorkflowHandle {
                    var input = input
                    input.headers = [
                        "key1": try DataConverter.default.payloadConverter.convertValueHandlingVoid("value1"),
                        "key2": try DataConverter.default.payloadConverter.convertValueHandlingVoid(4852),
                    ]
                    return try await next(input)
                }

                func signalWorkflow<each Input>(
                    input: SignalWorkflowInput<repeat each Input>,
                    next: (SignalWorkflowInput<repeat each Input>) async throws -> Void
                ) async throws {
                    var input = input
                    input.headers = [
                        "signal1": try DataConverter.default.payloadConverter.convertValueHandlingVoid("signalValue1"),
                        "signal2": try DataConverter.default.payloadConverter.convertValueHandlingVoid(400),
                    ]
                    return try await next(input)
                }

                func queryWorkflow<each Input, each Result>(
                    input: QueryWorkflowInput<repeat each Input>,
                    next: (QueryWorkflowInput<repeat each Input>) async throws -> (repeat each Result)
                ) async throws -> (repeat each Result) {
                    var input = input
                    input.headers = [
                        "query1": try DataConverter.default.payloadConverter.convertValueHandlingVoid("queryValue1"),
                        "query2": try DataConverter.default.payloadConverter.convertValueHandlingVoid(-45),
                    ]
                    return try await next(input)
                }
            }

            struct Inbound: WorkflowInboundInterceptor {
                let interceptor: Interceptor
                let payloadConverter = DataConverter.default.payloadConverter

                func executeWorkflow<Input, Output>(
                    input: ExecuteWorkflowInput<Input>,
                    next: (ExecuteWorkflowInput<Input>) async throws -> Output
                ) async throws -> Output {
                    let headers = input.headers
                    guard let rawValue1 = headers["key1"], let rawValue2 = headers["key2"] else { throw TestError() }

                    let value1 = try self.payloadConverter.convertPayload(rawValue1, as: String.self)
                    self.interceptor.result.withLock { $0.key1 = value1 }

                    let value2 = try self.payloadConverter.convertPayload(rawValue2, as: Int.self)
                    self.interceptor.result.withLock { $0.key2 = value2 }

                    return try await next(input)
                }

                func handleSignal<Signal>(
                    input: HandleSignalInput<Signal>,
                    next: (HandleSignalInput<Signal>) async throws -> Void
                ) async throws {
                    let headers = input.headers
                    guard let rawValue1 = headers["signal1"], let rawValue2 = headers["signal2"] else { throw TestError() }

                    let value1 = try self.payloadConverter.convertPayload(rawValue1, as: String.self)
                    self.interceptor.result.withLock { $0.signal1 = value1 }

                    let value2 = try self.payloadConverter.convertPayload(rawValue2, as: Int.self)
                    self.interceptor.result.withLock { $0.signal2 = value2 }

                    try await next(input)
                }

                func handleQuery<Query>(
                    input: HandleQueryInput<Query>,
                    next: (HandleQueryInput<Query>) throws -> Query.Output
                ) throws -> Query.Output {
                    let headers = input.headers
                    guard let rawValue1 = headers["query1"], let rawValue2 = headers["query2"] else { throw TestError() }

                    let value1 = try self.payloadConverter.convertPayload(rawValue1, as: String.self)
                    self.interceptor.result.withLock { $0.query1 = value1 }

                    let value2 = try self.payloadConverter.convertPayload(rawValue2, as: Int.self)
                    self.interceptor.result.withLock { $0.query2 = value2 }

                    return try next(input)
                }
            }

            func makeWorkflowInboundInterceptor() -> Inbound? {
                Inbound(interceptor: self)
            }

            func makeClientOutboundInterceptor() -> Outbound? {
                Outbound()
            }
        }

        @Workflow
        final class HeaderWorkflow {
            var proceed = false

            func run(input: Void) async throws -> Bool {
                try await Workflow.condition { self.proceed }
                return true
            }

            @WorkflowSignal
            func signal(input: Void) throws {
                proceed = true
            }

            @WorkflowQuery
            func query(input: Void) throws -> Bool {
                true
            }
        }

        @Test
        func workflow() async throws {
            let interceptor = Interceptor()

            try await workflowHandle(
                for: HeaderWorkflow.self,
                input: (),
                interceptors: [interceptor],
                clientInterceptors: [interceptor]
            ) { handle in
                let query = try await handle.query(
                    queryType: HeaderWorkflow.Query.self
                )
                #expect(query)

                try await handle.signal(
                    signalType: HeaderWorkflow.Signal.self
                )

                let result = try await handle.result()
                #expect(result)

                let expectedOutput = Interceptor.Result(
                    key1: "value1",
                    key2: 4852,
                    signal1: "signalValue1",
                    signal2: 400,
                    query1: "queryValue1",
                    query2: -45
                )

                let output = interceptor.result.withLock { $0 }
                #expect(output == expectedOutput)
            }
        }
    }
}
