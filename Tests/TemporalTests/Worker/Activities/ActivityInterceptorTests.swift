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

import Synchronization
import Temporal
import Testing

#if !(os(Linux) && swift(>=6.2))  // TODO: reenable once Swift 6.2 compiler crash on Linux is fixed
extension TestServerDependentTests {
    @Suite
    struct ActivityInterceptorTests {
        @ActivityContainer
        struct Tests {
            @Activity
            static func constant() -> Int { return 42 }

            @Activity
            static func heartbeat() {
                ActivityExecutionContext.current?.heartbeat(details: "Foo")
            }
        }

        @Workflow
        final class VoidWorkflow {
            func run(input: Void) async -> Int {
                try! await Workflow.executeActivity(
                    Tests.Activities.Constant.self,
                    options: .init(scheduleToCloseTimeout: .seconds(5)),
                    input: ()
                )
            }
        }

        @Workflow
        final class HeartbeatingWorkflow {
            func run(input: Void) async {
                try! await Workflow.executeActivity(
                    Tests.Activities.Heartbeat.self,
                    options: .init(scheduleToCloseTimeout: .seconds(5)),
                    input: ()
                )
            }
        }

        final class CountingInterceptor: WorkerInterceptor {
            let counter: Mutex<[String: Int]> = .init([:])

            struct Inbound: ActivityInboundInterceptor {
                let interceptor: CountingInterceptor

                init(interceptor: CountingInterceptor) {
                    self.interceptor = interceptor
                }

                func executeActivity<Activity>(
                    input: ExecuteActivityInput<Activity>,
                    next: (ExecuteActivityInput<Activity>) async throws -> Activity.Output
                ) async throws -> Activity.Output {
                    interceptor.counter.withLock { $0[Activity.name, default: 0] += 1 }
                    return try await next(input)
                }
            }

            func makeActivityInboundInterceptor() -> Inbound? {
                return Inbound(interceptor: self)
            }
        }

        @Test
        func interceptsActivityExecution() async throws {
            let interceptor = CountingInterceptor()

            let result = try await executeWorkflow(
                VoidWorkflow.self,
                input: (),
                activities: [Tests().activities.constant],
                interceptors: [interceptor]
            )

            #expect(result == 42)
            #expect(interceptor.counter.withLock { $0[Tests.Activities.Constant.name] } == 1)
        }

        @Test
        func interceptorsWrapEachOther() async throws {
            final class SecondInterceptor: WorkerInterceptor {
                let firstInterceptor: CountingInterceptor

                init(firstInterceptor: CountingInterceptor) { self.firstInterceptor = firstInterceptor }

                struct Inbound: ActivityInboundInterceptor {
                    let interceptor: CountingInterceptor

                    init(interceptor: CountingInterceptor) {
                        self.interceptor = interceptor
                    }

                    func executeActivity<Activity>(
                        input: ExecuteActivityInput<Activity>,
                        next: (ExecuteActivityInput<Activity>) async throws -> Activity.Output
                    ) async throws -> Activity.Output {
                        // If the previous interceptor didn't run before us this value would be nil.
                        #expect(interceptor.counter.withLock { $0[Activity.name] } == 1)
                        interceptor.counter.withLock { $0[Activity.name, default: 0] += 1 }
                        return try await next(input)
                    }
                }

                func makeActivityInboundInterceptor() -> Inbound? {
                    return Inbound(interceptor: self.firstInterceptor)
                }
            }

            let interceptor = CountingInterceptor()

            let result = try await executeWorkflow(
                VoidWorkflow.self,
                input: (),
                activities: [Tests().activities.constant],
                interceptors: [interceptor, SecondInterceptor(firstInterceptor: interceptor)]
            )
            #expect(result == 42)
            #expect(interceptor.counter.withLock { $0[Tests.Activities.Constant.name] } == 2)
        }

        final class HeartbeatCountingInterceptor: WorkerInterceptor {
            let counter: Mutex<Int> = .init(0)

            struct Outbound: ActivityOutboundInterceptor {
                let interceptor: HeartbeatCountingInterceptor

                init(interceptor: HeartbeatCountingInterceptor) {
                    self.interceptor = interceptor
                }

                func heartbeat<each Detail: Sendable>(
                    input: HeartbeatInput<repeat each Detail>,
                    next: (HeartbeatInput<repeat each Detail>) -> Void
                ) {
                    var i = 0
                    for d in repeat each input.details {
                        guard i == 0 else {
                            break
                        }

                        guard let first = d as? String else {
                            Issue.record("Wrong type passed to heartbeat first detail, expected `String`")
                            return
                        }
                        #expect(first == "Foo", #"First heartbeat detail wasn't "Foo""#)
                        i += 1
                    }

                    interceptor.counter.withLock { $0 += 1 }
                    next(input)
                }
            }

            func makeActivityOutboundInterceptor() -> Outbound? {
                return Outbound(interceptor: self)
            }
        }

        @Test
        func interceptsHeartbeat() async throws {
            let interceptor = HeartbeatCountingInterceptor()

            let _ = try await executeWorkflow(
                HeartbeatingWorkflow.self,
                input: (),
                activities: [Tests().activities.heartbeat],
                interceptors: [interceptor]
            )

            #expect(interceptor.counter.withLock { $0 } == 1)
        }

        @Test
        func outboundInterceptorsWrapEachOther() async throws {
            final class SecondInterceptor: WorkerInterceptor {
                let firstInterceptor: HeartbeatCountingInterceptor

                init(firstInterceptor: HeartbeatCountingInterceptor) { self.firstInterceptor = firstInterceptor }

                struct Outbound: ActivityOutboundInterceptor {
                    let interceptor: HeartbeatCountingInterceptor

                    init(interceptor: HeartbeatCountingInterceptor) {
                        self.interceptor = interceptor
                    }

                    func heartbeat<each Detail: Sendable>(
                        input: HeartbeatInput<repeat each Detail>,
                        next: (HeartbeatInput<repeat each Detail>) -> Void
                    ) {
                        #expect(interceptor.counter.withLock { $0 } == 1)
                        interceptor.counter.withLock { $0 += 1 }
                        next(input)
                    }
                }

                func makeActivityOutboundInterceptor() -> Outbound? {
                    return Outbound(interceptor: self.firstInterceptor)
                }
            }

            let interceptor = HeartbeatCountingInterceptor()

            let _ = try await executeWorkflow(
                HeartbeatingWorkflow.self,
                input: (),
                activities: [Tests().activities.heartbeat],
                interceptors: [interceptor, SecondInterceptor(firstInterceptor: interceptor)]
            )

            #expect(interceptor.counter.withLock { $0 } == 2)
        }
    }
}
#endif
