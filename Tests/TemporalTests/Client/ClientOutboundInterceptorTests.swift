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

import protocol GRPCCore.ClientTransport

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct ClientOutboundInterceptorTests {
        struct Event: Equatable {
            enum Kind {
                case startWorkflow
                case signalWorkflow
                case queryWorkflow
                case countWorkflows
            }

            let tick: Int
            let kind: Kind

            init(_ tick: Int, kind: Kind) {
                self.tick = tick
                self.kind = kind
            }
        }

        @Workflow
        final class SimpleWorkflow {
            var signal = 0
            func run(input: Void) async throws {
                try await Workflow.sleep(for: .seconds(1))
            }

            @WorkflowSignal
            func signal(input: Int) async throws {
                signal = input
            }

            @WorkflowQuery
            func query(input: Int) throws -> Int {
                input + 10
            }
        }

        actor Ticker {
            private var value = 0
            func next() -> Int {
                value += 1
                return value
            }
        }

        final class CountingInterceptor: EventRecordingInterceptor {
            let ticker: Ticker
            let events: Mutex<[Event]> = .init([])
            init(ticker: Ticker) {
                self.ticker = ticker
            }

            struct Outbound: ClientOutboundInterceptor {
                let ticker: Ticker
                let interceptor: CountingInterceptor

                func startWorkflow<each Input>(
                    input: StartWorkflowInput<repeat each Input>,
                    next: (StartWorkflowInput<repeat each Input>) async throws -> UntypedWorkflowHandle
                ) async throws -> UntypedWorkflowHandle {
                    #expect(input.name == "\(SimpleWorkflow.self)")
                    await interceptor.record(.startWorkflow)
                    return try await next(input)
                }

                func signalWorkflow<each Input>(
                    input: SignalWorkflowInput<repeat each Input>,
                    next: (SignalWorkflowInput<repeat each Input>) async throws -> Void
                ) async throws {
                    await interceptor.record(.signalWorkflow)
                    return try await next(input)
                }

                func queryWorkflow<each Input, each Result>(
                    input: QueryWorkflowInput<repeat each Input>,
                    next: (QueryWorkflowInput<repeat each Input>) async throws -> (repeat each Result)
                ) async throws -> (repeat each Result) {
                    await interceptor.record(.queryWorkflow)
                    return try await next(input)
                }

                func countWorkflows(
                    input: CountWorkflowsInput,
                    next: (CountWorkflowsInput) async throws -> WorkflowExecutionCount
                ) async throws -> WorkflowExecutionCount {
                    await interceptor.record(.countWorkflows)
                    return try await next(input)
                }
            }

            func makeClientOutboundInterceptor() -> Outbound? {
                Outbound(ticker: ticker, interceptor: self)
            }
        }

        @Test
        func interceptsWorkflowExecution() async throws {
            let ticker = Ticker()
            let interceptor = CountingInterceptor(ticker: ticker)

            try await executeWorkflow(
                SimpleWorkflow.self,
                input: (),
                clientInterceptors: [interceptor]
            )
            #expect(interceptor.events.withLock { $0 } == [.init(1, kind: .startWorkflow)])

            try await executeWorkflow(
                SimpleWorkflow.self,
                input: (),
                clientInterceptors: [interceptor]
            )
            #expect(interceptor.events.withLock { $0 } == [.init(1, kind: .startWorkflow), .init(2, kind: .startWorkflow)])
        }

        @Test
        func multipleInterceptorsInterceptWorkflowExecution() async throws {
            final class SecondInterceptor: EventRecordingInterceptor {
                let ticker: Ticker
                let events: Mutex<[Event]> = .init([])
                let otherInterceptor: CountingInterceptor
                init(ticker: Ticker, otherInterceptor: CountingInterceptor) {
                    self.ticker = ticker
                    self.otherInterceptor = otherInterceptor
                }

                struct Outbound: ClientOutboundInterceptor {
                    let interceptor: SecondInterceptor
                    let otherInterceptor: CountingInterceptor

                    init(interceptor: SecondInterceptor, otherInterceptor: CountingInterceptor) {
                        self.interceptor = interceptor
                        self.otherInterceptor = otherInterceptor
                    }

                    func startWorkflow<each Input>(
                        input: StartWorkflowInput<repeat each Input>,
                        next: (StartWorkflowInput<repeat each Input>) async throws -> UntypedWorkflowHandle
                    ) async throws -> UntypedWorkflowHandle {
                        await interceptor.record(.startWorkflow)
                        return try await next(input)
                    }
                }

                func makeClientOutboundInterceptor() -> Outbound? {
                    Outbound(interceptor: self, otherInterceptor: otherInterceptor)
                }
            }

            let ticker = Ticker()
            let firstInterceptor = CountingInterceptor(ticker: ticker)
            let secondInterceptor = SecondInterceptor(ticker: ticker, otherInterceptor: firstInterceptor)

            try await executeWorkflow(
                SimpleWorkflow.self,
                input: (),
                clientInterceptors: [firstInterceptor, secondInterceptor]
            )
            #expect(firstInterceptor.events.withLock { $0 } == [.init(1, kind: .startWorkflow)])
            #expect(secondInterceptor.events.withLock { $0 } == [.init(2, kind: .startWorkflow)])
        }

        @Test
        func catchAll() async throws {
            let ticker = Ticker()
            let interceptor = CountingInterceptor(ticker: ticker)

            try await workflowHandle(
                for: SimpleWorkflow.self,
                input: (),
                clientInterceptors: [interceptor]
            ) { handle in
                try await handle.signal(signalType: SimpleWorkflow.Signal.self, input: 42)

                let queryResult = try await handle.query(queryType: SimpleWorkflow.Query.self, input: 1)
                #expect(queryResult == 11)

                let workflowCount = try await handle.untypedHandle.interceptor.countWorkflows(.init(query: ""))
                #expect(workflowCount.count > 0)
            }
            #expect(
                interceptor.events.withLock { $0 } == [
                    .init(1, kind: .startWorkflow),
                    .init(2, kind: .signalWorkflow),
                    .init(3, kind: .queryWorkflow),
                    .init(4, kind: .countWorkflows),
                ]
            )
        }
    }
}

protocol EventRecordingInterceptor: ClientInterceptor {
    var ticker: TestServerDependentTests.ClientOutboundInterceptorTests.Ticker { get }
    var events: Mutex<[TestServerDependentTests.ClientOutboundInterceptorTests.Event]> { get }
}
extension EventRecordingInterceptor {
    func record(_ kind: TestServerDependentTests.ClientOutboundInterceptorTests.Event.Kind) async {
        let tick = await ticker.next()
        events.withLock { $0.append(.init(tick, kind: kind)) }
    }
}
