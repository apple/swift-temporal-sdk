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
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct InterceptedOperationsTests {
        struct WorkflowEvent: Equatable {
            enum Kind {
                case startWorkflow
                case signalWorkflow
                case queryWorkflow
                case updateWorkflow
                case describeWorkflow
                case cancelWorkflow
                case terminateWorkflow
                case resultWorkflow
            }

            let tick: Int
            let kind: Kind

            init(_ tick: Int, kind: Kind) {
                self.tick = tick
                self.kind = kind
            }
        }

        final class WorkflowCountingInterceptor: ClientInterceptor {
            let ticker: Mutex<Int> = .init(0)
            let events: Mutex<[WorkflowEvent]> = .init([])

            struct Outbound: ClientOutboundInterceptor {
                let interceptor: WorkflowCountingInterceptor

                func startWorkflow<each Input>(
                    input: StartWorkflowInput<repeat each Input>,
                    next: (StartWorkflowInput<repeat each Input>) async throws -> UntypedWorkflowHandle
                ) async throws -> UntypedWorkflowHandle {
                    self.interceptor.record(.startWorkflow)
                    return try await next(input)
                }

                func signalWorkflow<each Input>(
                    input: SignalWorkflowInput<repeat each Input>,
                    next: (SignalWorkflowInput<repeat each Input>) async throws -> Void
                ) async throws {
                    self.interceptor.record(.signalWorkflow)
                    return try await next(input)
                }

                func queryWorkflow<each Input, each Result: Sendable>(
                    input: QueryWorkflowInput<repeat each Input>,
                    next: (QueryWorkflowInput<repeat each Input>) async throws -> (repeat each Result)
                ) async throws -> (repeat each Result) {
                    self.interceptor.record(.queryWorkflow)
                    return try await next(input)
                }

                func startWorkflowUpdate<each Input>(
                    input: StartWorkflowUpdateInput<repeat each Input>,
                    next: (StartWorkflowUpdateInput<repeat each Input>) async throws -> UntypedWorkflowUpdateHandle
                ) async throws -> UntypedWorkflowUpdateHandle {
                    self.interceptor.record(.updateWorkflow)
                    return try await next(input)
                }

                func describeWorkflow(
                    input: DescribeWorkflowInput,
                    next: (DescribeWorkflowInput) async throws -> (WorkflowExecutionDescription)
                ) async throws -> WorkflowExecutionDescription {
                    self.interceptor.record(.describeWorkflow)
                    return try await next(input)
                }

                func cancelWorkflow(
                    input: CancelWorkflowInput,
                    next: (CancelWorkflowInput) async throws -> Void
                ) async throws {
                    self.interceptor.record(.cancelWorkflow)
                    return try await next(input)
                }

                func terminateWorkflow<each Detail>(
                    input: TerminateWorkflowInput<repeat each Detail>,
                    next: (TerminateWorkflowInput<repeat each Detail>) async throws -> Void
                ) async throws {
                    self.interceptor.record(.terminateWorkflow)
                    return try await next(input)
                }

                func fetchWorkflowHistoryEvents(
                    input: FetchWorkflowHistoryEventsInput,
                    next: (FetchWorkflowHistoryEventsInput) async throws -> [HistoryEvent]
                ) async throws -> [HistoryEvent] {
                    self.interceptor.record(.resultWorkflow)
                    return try await next(input)
                }
            }

            func makeClientOutboundInterceptor() -> Outbound? {
                Outbound(interceptor: self)
            }

            func record(_ kind: TestServerDependentTests.InterceptedOperationsTests.WorkflowEvent.Kind) {
                let tick = self.ticker.withLock {
                    $0 += 1
                    return $0
                }
                self.events.withLock { $0.append(.init(tick, kind: kind)) }
            }
        }

        @Workflow
        final class HelloWorldUntypedOperationsWorkflow {
            func run(input: String) async -> String {
                "Hello World, \(input)!"
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func startWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloWorldUntypedOperationsWorkflow.self]
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(HelloWorldUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "Max",
                )

                let result = try await client.interceptedService.workflowResult(
                    id: workflowID,
                    runID: runID,
                    resultTypes: String.self
                )

                #expect(result == "Hello World, Max!")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .resultWorkflow),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func executeWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloWorldUntypedOperationsWorkflow.self]
            ) { taskQueue, client in
                let result = try await client.interceptedService.executeWorkflow(
                    name: "\(HelloWorldUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "Jan",
                    resultTypes: String.self
                )

                #expect(result == "Hello World, Jan!")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .resultWorkflow),
                    ]
                )
            }
        }

        @Workflow
        final class SignalUntypedOperationsWorkflow {
            private var received: String?

            func run(input: Void) async throws -> String {
                // wait until a signal sets `received`
                try await Workflow.condition { self.received != nil }
                return self.received ?? "no signal received"
            }

            @WorkflowSignal
            func signal(input: String) async throws {
                self.received = input
            }

            @WorkflowSignal(name: "NoInputSignal")
            func signalNoInput(input: Void) async throws {
                self.received = "No input signal"
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func signalWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [SignalUntypedOperationsWorkflow.self],
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(SignalUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                try await client.interceptedService.signalWorkflow(
                    id: workflowID,
                    runID: runID,
                    signalName: "\(SignalUntypedOperationsWorkflow.Signal.self)",
                    input: "Hello Signal!"
                )

                let result = try await client.interceptedService.workflowResult(
                    id: workflowID,
                    runID: runID,
                    resultTypes: String.self
                )

                #expect(result == "Hello Signal!")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .signalWorkflow),
                        .init(3, kind: .resultWorkflow),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func signalNoInputWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [SignalUntypedOperationsWorkflow.self],
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(SignalUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                try await client.interceptedService.signalWorkflow(
                    id: workflowID,
                    runID: runID,
                    signalName: "NoInputSignal"
                )

                let result = try await client.interceptedService.workflowResult(
                    id: workflowID,
                    runID: runID,
                    resultTypes: String.self
                )

                #expect(result == "No input signal")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .signalWorkflow),
                        .init(3, kind: .resultWorkflow),
                    ]
                )
            }
        }

        struct SimpleActivity: ActivityDefinition {
            static let name: String? = "SimpleActivity"
            func run(input: Void) async throws -> String {
                "finished"
            }
        }

        @Workflow
        final class QueryUntypedOperationsWorkflow {
            private var state = "initial"

            func run(input: Void) async throws {
                // simulate some work before updating state
                try await Workflow.sleep(for: .milliseconds(100))
                self.state = "finished"
            }

            @WorkflowQuery
            func query(input: String) throws -> String {
                input
            }

            @WorkflowQuery(name: "NoInputQuery")
            func queryNoInput(input: Void) throws -> String {
                self.state
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func queryWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [QueryUntypedOperationsWorkflow.self],
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(QueryUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                let queryResult = try await client.interceptedService.queryWorkflow(
                    id: workflowID,
                    runID: runID,
                    queryName: "\(QueryUntypedOperationsWorkflow.Query.self)",
                    input: "Hello Query!",
                    resultTypes: String.self
                )

                try await client.interceptedService.workflowResult(
                    id: workflowID,
                    runID: runID,
                    resultTypes: Void.self
                )

                #expect(queryResult == "Hello Query!")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .queryWorkflow),
                        .init(3, kind: .resultWorkflow),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func queryNoInputWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [QueryUntypedOperationsWorkflow.self],
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(QueryUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                let queryResult1 = try await client.interceptedService.queryWorkflow(
                    id: workflowID,
                    runID: runID,
                    queryName: "NoInputQuery",
                    resultTypes: String.self
                )

                try await client.interceptedService.workflowResult(
                    id: workflowID,
                    runID: runID,
                    resultTypes: Void.self
                )

                let queryResult2 = try await client.interceptedService.queryWorkflow(
                    id: workflowID,
                    runID: runID,
                    queryName: "NoInputQuery",
                    resultTypes: String.self
                )

                #expect(queryResult1 == "initial")
                #expect(queryResult2 == "finished")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .queryWorkflow),
                        .init(3, kind: .resultWorkflow),
                        .init(4, kind: .queryWorkflow),
                    ]
                )
            }
        }

        @Workflow
        final class UpdateUntypedOperationsWorkflow {
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

            @WorkflowUpdate(name: "NoInputUpdate")
            func updateNoInput(input: Void) async throws -> String {
                self.state = "updated"
                return "Hello from update"
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func updateWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [UpdateUntypedOperationsWorkflow.self],
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(UpdateUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                let updateID = try await client.interceptedService.startWorkflowUpdate(
                    id: workflowID,
                    runID: runID,
                    firstExecutionRunID: runID,
                    updateName: "\(UpdateUntypedOperationsWorkflow.Update.self)",
                    input: "testRegularUpdate"
                )

                let updateResult = try await client.interceptedService.workflowUpdateResult(
                    id: workflowID,
                    runID: runID,
                    updateID: updateID,
                    resultTypes: String.self
                )

                try await client.interceptedService.workflowResult(
                    id: workflowID,
                    runID: runID,
                    resultTypes: Void.self
                )

                #expect(updateResult == "Hello from update, testRegularUpdate")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .updateWorkflow),
                        .init(3, kind: .resultWorkflow),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func updateNoInputWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [UpdateUntypedOperationsWorkflow.self],
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(UpdateUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                let updateID = try await client.interceptedService.startWorkflowUpdate(
                    id: workflowID,
                    runID: runID,
                    firstExecutionRunID: runID,
                    updateName: "NoInputUpdate"
                )

                let updateResult = try await client.interceptedService.workflowUpdateResult(
                    id: workflowID,
                    runID: runID,
                    updateID: updateID,
                    resultTypes: String.self
                )

                try await client.interceptedService.workflowResult(
                    id: workflowID,
                    runID: runID,
                    resultTypes: Void.self
                )

                #expect(updateResult == "Hello from update")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .updateWorkflow),
                        .init(3, kind: .resultWorkflow),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func executeUpdateWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [UpdateUntypedOperationsWorkflow.self],
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(UpdateUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                let updateResult = try await client.interceptedService.executeWorkflowUpdate(
                    id: workflowID,
                    runID: runID,
                    firstExecutionRunID: runID,
                    updateName: "\(UpdateUntypedOperationsWorkflow.Update.self)",
                    input: "testExecuteUpdate",
                    resultTypes: String.self
                )

                try await client.interceptedService.workflowResult(
                    id: workflowID,
                    runID: runID,
                    resultTypes: Void.self
                )

                #expect(updateResult == "Hello from update, testExecuteUpdate")
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .updateWorkflow),
                        .init(3, kind: .resultWorkflow),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func describeWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloWorldUntypedOperationsWorkflow.self]
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(HelloWorldUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "Max",
                )

                let description = try await client.interceptedService.describeWorkflow(
                    id: workflowID,
                    runID: runID
                )

                #expect(description.execution.workflowID == workflowID)
                #expect(description.execution.runID == runID)
                #expect(description.execution.taskQueue == taskQueue)
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .describeWorkflow),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func cancelWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloWorldUntypedOperationsWorkflow.self]
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(HelloWorldUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "Max",
                )

                try await client.interceptedService.cancelWorkflow(
                    id: workflowID,
                    runID: runID,
                    firstExecutionRunID: runID
                )

                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .cancelWorkflow),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func terminateWorkflow() async throws {
            let interceptor = WorkflowCountingInterceptor()
            let workflowID = UUID().uuidString

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloWorldUntypedOperationsWorkflow.self]
            ) { taskQueue, client in
                let runID = try await client.interceptedService.startWorkflow(
                    name: "\(HelloWorldUntypedOperationsWorkflow.self)",
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "Max",
                )

                try await client.interceptedService.terminateWorkflow(
                    id: workflowID,
                    runID: runID,
                    firstExecutionRunID: runID,
                    reason: "test termination",
                    details: "test variadic details"
                )

                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .startWorkflow),
                        .init(2, kind: .terminateWorkflow),
                    ]
                )
            }
        }
    }
}
