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
    struct WorkflowContinueAsNewTests {

        @Workflow
        final class ContinueAsNewWorkflow {
            func run(input: [String]) async throws -> [String] {
                let pastRunIDsCount: Int? = try await Workflow.getMemoValue(for: "past_run_id_count")
                guard input.count == pastRunIDsCount ?? 0 else {
                    throw TestError()
                }
                guard Workflow.info.retryPolicy?.maximumAttempts == input.count + 1000 else {
                    throw TestError()
                }

                if input.count == 5 {
                    return input
                }

                var input = input
                input.append(Workflow.info.runID)
                throw try await Workflow.makeContinueAsNewError(
                    options: .init(
                        retryPolicy: .init(maximumAttempts: input.count + 1000),
                        memo: ["past_run_id_count": input.count]
                    ),
                    input: input
                )
            }
        }

        @Test
        func continueAsNew() async throws {
            let result = try await executeWorkflow(
                ContinueAsNewWorkflow.self,
                input: [String](),
                workflowRetryPolicy: .init(maximumAttempts: 1000)
            )
            #expect(result.count == 5)
        }

        @Test
        func interceptsContinueAsNew() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let counter: Mutex<Int> = .init(0)

                struct Outbound: WorkflowOutboundInterceptor {
                    let interceptor: CountingInterceptor

                    func makeContinueAsNewError<each Input>(
                        input: MakeContinueAsNewErrorInput<repeat each Input>,
                        next: (MakeContinueAsNewErrorInput<repeat each Input>) async throws -> ContinueAsNewError
                    ) async throws -> ContinueAsNewError {
                        interceptor.counter.withLock { $0 += 1 }
                        return try await next(input)
                    }
                }

                func makeWorkflowOutboundInterceptor() -> Outbound? {
                    return Outbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            let result = try await executeWorkflow(
                ContinueAsNewWorkflow.self,
                input: [],
                workflowRetryPolicy: .init(maximumAttempts: 1000),
                interceptors: [interceptor]
            )
            #expect(result.count == interceptor.counter.withLock { $0 })
        }
    }
}
