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
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowQueryTests {
        struct SimpleActivity: ActivityDefinition {
            static let name: String? = "SimpleActivity"
            func run(input: Void) async throws -> String {
                "finished"
            }
        }
        struct SimpleActivityClone: ActivityDefinition {
            static let name: String? = "SimpleActivityClone"
            func run(input: Void) async throws -> String {
                "finished"
            }
        }

        @Workflow(name: "SimpleQueryWorkflow")
        final class SimpleQueryWorkflow<Activity: ActivityDefinition> where Activity.Input == Void, Activity.Output == String {
            @_WorkflowState  // This works around a compiler crash
            private var state = "initial"

            func run(input: Void) async throws {
                state = try await Workflow.executeActivity(Activity.self, options: .init(scheduleToCloseTimeout: .seconds(100)))
            }

            @WorkflowQuery
            func query(input: Void) throws -> String {
                state
            }
        }

        @Workflow
        final class QueryWorkflow {
            enum QueryScenario: Codable {
                case simpleQuery
            }

            private var state = "initial"

            func run(input: Void) async throws {
                try await Workflow.condition { self.state == "finished" }
            }

            @WorkflowQuery
            func query(input: QueryScenario) throws -> String {
                switch input {
                case .simpleQuery:
                    return self.state
                }
            }

            @WorkflowSignal
            func signal(input: String) async throws {
                self.state = input
            }
        }

        @Test
        func simpleQuery() async throws {
            try await withTestWorkerAndClient(
                workflows: [QueryWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: QueryWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                let initialState = try await handle.query(
                    queryType: QueryWorkflow.Query.self,
                    input: .simpleQuery
                )
                #expect(initialState == "initial")

                try await handle.signal(
                    signalType: QueryWorkflow.Signal.self,
                    input: "finished"
                )

                try await handle.result()
            }
        }

        @Test
        func simpleQueryAfterActivity() async throws {
            typealias Workflow = SimpleQueryWorkflow<SimpleActivity>
            try await withTestWorkerAndClient(
                activities: [SimpleActivity()],
                workflows: [Workflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: Workflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                var state = try await handle.query(
                    queryType: Workflow.Query.self
                )

                try await handle.result()

                state = try await handle.query(
                    queryType: Workflow.Query.self
                )
                #expect(state == "finished")
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func nondeterminismExitsCleanly() async throws {
            // NOTE: A non-clean exit where continuations are left orphaned may
            // lead to the test appearing to stall indefinitely hence the timeout.
            let id = "wf-\(UUID().uuidString)"
            let taskQueue = "tq-\(UUID().uuidString)"
            try await executeWorkflow(
                SimpleQueryWorkflow<SimpleActivity>.self,
                input: (),
                activities: [SimpleActivity()],
                taskQueue: taskQueue,
                id: id
            )

            try await executeWorkflow(
                SimpleQueryWorkflow<SimpleActivityClone>.self,
                input: (),
                activities: [SimpleActivityClone()],
                taskQueue: taskQueue
            ) { handle, _ in
                let error =
                    await #expect(throws: WorkflowQueryFailedError.self) {
                        _ = try await handle.with(id: id).query(queryType: SimpleQueryWorkflow<SimpleActivity>.Query.self)
                    }?.message ?? ""
                #expect(error.contains("Nondeterminism"))
            }
        }

        @Test
        func multiStepQuery() async throws {
            try await withTestWorkerAndClient(
                workflows: [QueryWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: QueryWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                let initialState = try await handle.query(
                    queryType: QueryWorkflow.Query.self,
                    input: .simpleQuery
                )
                #expect(initialState == "initial")

                try await handle.signal(
                    signalType: QueryWorkflow.Signal.self,
                    input: "updated"
                )

                let updatedState = try await handle.query(
                    queryType: QueryWorkflow.Query.self,
                    input: .simpleQuery
                )
                #expect(updatedState == "updated")

                try await handle.signal(
                    signalType: QueryWorkflow.Signal.self,
                    input: "finished"
                )

                let finishedState = try await handle.query(
                    queryType: QueryWorkflow.Query.self,
                    input: .simpleQuery
                )
                #expect(finishedState == "finished")

                try await handle.result()

                let finalState = try await handle.query(
                    queryType: QueryWorkflow.Query.self,
                    input: .simpleQuery
                )
                #expect(finalState == "finished")
            }
        }

        @Test
        func interceptsQuery() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let counter: Mutex<Int> = .init(0)

                struct Inbound: WorkflowInboundInterceptor {
                    let interceptor: CountingInterceptor

                    func handleQuery<Query>(
                        input: HandleQueryInput<Query>,
                        next: (HandleQueryInput<Query>) throws -> Query.Output
                    ) throws -> Query.Output {
                        interceptor.counter.withLock { $0 += 1 }
                        return try next(input)
                    }
                }

                func makeWorkflowInboundInterceptor() -> Inbound? {
                    return Inbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            try await withTestWorkerAndClient(
                interceptors: [interceptor],
                workflows: [QueryWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: QueryWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                let initialState = try await handle.query(
                    queryType: QueryWorkflow.Query.self,
                    input: .simpleQuery
                )
                #expect(initialState == "initial")

                try await handle.signal(
                    signalType: QueryWorkflow.Signal.self,
                    input: "finished"
                )

                try await handle.result()

                #expect(interceptor.counter.withLock { $0 } == 1)
            }
        }

    }
}
