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
    struct WorkflowInboundInterceptorTests {
        // The intent is to eventually make this use enough features to test all interception methods.
        @Workflow
        final class InterceptorTestingWorkflow {
            func run(input: Void) async throws {
                // ...although currently it doesn't do anything interesting
                try await Workflow.sleep(for: .seconds(1))
            }
        }

        final class CountingInterceptor: WorkerInterceptor {
            let counter: Mutex<Int> = .init(0)

            struct Inbound: WorkflowInboundInterceptor {
                let interceptor: CountingInterceptor

                init(interceptor: CountingInterceptor) {
                    self.interceptor = interceptor
                }

                func executeWorkflow<Workflow>(
                    input: ExecuteWorkflowInput<Workflow>,
                    next: (ExecuteWorkflowInput<Workflow>) async throws -> Workflow.Output
                ) async throws -> Workflow.Output {
                    #expect(Temporal.Workflow.info.workflowName == "\(InterceptorTestingWorkflow.self)")
                    interceptor.counter.withLock { $0 += 1 }
                    return try await next(input)
                }
            }

            func makeWorkflowInboundInterceptor() -> Inbound? {
                Inbound(interceptor: self)
            }
        }

        @Test
        func interceptsWorkflowExecution() async throws {
            let interceptor = CountingInterceptor()

            try await executeWorkflow(
                InterceptorTestingWorkflow.self,
                input: (),
                interceptors: [interceptor]
            )

            #expect(interceptor.counter.withLock { $0 } == 1)

            try await executeWorkflow(
                InterceptorTestingWorkflow.self,
                input: (),
                interceptors: [interceptor]
            )

            #expect(interceptor.counter.withLock { $0 } == 2)
        }

        @Test
        func multipleInterceptorsInterceptWorkflowExecution() async throws {
            struct SecondInterceptor: WorkerInterceptor {
                let firstInterceptor: CountingInterceptor

                struct Inbound: WorkflowInboundInterceptor {
                    let firstInterceptor: CountingInterceptor

                    init(firstInterceptor: CountingInterceptor) {
                        self.firstInterceptor = firstInterceptor
                    }

                    func executeWorkflow<Workflow>(
                        input: ExecuteWorkflowInput<Workflow>,
                        next: (ExecuteWorkflowInput<Workflow>) async throws -> Workflow.Output
                    ) async throws -> Workflow.Output {
                        // If the first interceptor runs before us the value will be 1, otherwise it will be 0.
                        #expect(firstInterceptor.counter.withLock { $0 } == 1)
                        return try await next(input)
                    }
                }

                func makeWorkflowInboundInterceptor() -> Inbound? {
                    Inbound(firstInterceptor: firstInterceptor)
                }
            }

            let firstInterceptor = CountingInterceptor()
            let secondInterceptor = SecondInterceptor(firstInterceptor: firstInterceptor)

            try await executeWorkflow(
                InterceptorTestingWorkflow.self,
                input: (),
                interceptors: [firstInterceptor, secondInterceptor]
            )
        }
    }
}
