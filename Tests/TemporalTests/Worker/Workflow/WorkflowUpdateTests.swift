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
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowUpdateTests {
        @Workflow
        final class UpdateWorkflow {
            private var state = ""

            func run(input: Void) async throws {
                try await Workflow.condition { self.state == "updated" }
                try await Workflow.condition { Workflow.allHandlersFinished }
            }

            @WorkflowUpdate
            func update(input: String) async throws -> String {
                self.state = "updated"
                return "Hello from update, \(input)"
            }
        }

        @Test
        func simpleUpdate() async throws {
            try await withTestWorkerAndClient(
                workflows: [UpdateWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: UpdateWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )
                let result = try await handle.executeUpdate(
                    updateType: UpdateWorkflow.Update.self,
                    input: "test"
                )
                #expect(result == "Hello from update, test")

                try await handle.result()
            }
        }

        @Test
        func interceptsUpdate() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let updateCounter: Mutex<Int> = .init(0)
                let validateCounter: Mutex<Int> = .init(0)

                struct Inbound: WorkflowInboundInterceptor {
                    let interceptor: CountingInterceptor

                    func handleUpdate<Update>(
                        input: HandleUpdateInput<Update>,
                        next: (HandleUpdateInput<Update>) async throws -> Update.Output
                    ) async throws -> Update.Output {
                        interceptor.updateCounter.withLock { $0 += 1 }
                        return try await next(input)
                    }

                    func validateUpdate<Update>(
                        input: HandleUpdateInput<Update>,
                        next: (HandleUpdateInput<Update>) throws -> Void
                    ) throws {
                        interceptor.validateCounter.withLock { $0 += 1 }
                        try next(input)
                    }
                }

                func makeWorkflowInboundInterceptor() -> Inbound? {
                    return Inbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            try await withTestWorkerAndClient(
                interceptors: [interceptor],
                workflows: [UpdateWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: UpdateWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )
                let result = try await handle.executeUpdate(
                    updateType: UpdateWorkflow.Update.self,
                    input: "test"
                )
                #expect(result == "Hello from update, test")

                try await handle.result()

                #expect(interceptor.updateCounter.withLock { $0 } == 1)
                #expect(interceptor.validateCounter.withLock { $0 } == 1)
            }
        }
    }
}
