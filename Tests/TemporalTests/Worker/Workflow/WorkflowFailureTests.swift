//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Foundation
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowFailureTests {
        struct DomainError: Error {}
        struct OtherError: Error {}

        // MARK: - Helpers

        struct WorkflowTaskFailureNotFound: Error {}

        static func workerConfiguration(
            workflowFailureErrorTypes: [any Error.Type] = [],
            maxCachedWorkflows: Int? = nil
        ) -> TemporalWorker.Configuration {
            let (host, _) = TemporalTestServer.testServer!.hostAndPort()
            var config = TemporalWorker.Configuration(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                instrumentation: .init(serverHostname: host)
            )
            config.workflowFailureErrorTypes = workflowFailureErrorTypes
            if let maxCachedWorkflows {
                config.maxCachedWorkflows = maxCachedWorkflows
            }
            return config
        }

        /// The options to start a workflow with.
        ///
        /// The execution timeout makes a test fail fast if a workflow keeps failing its workflow task
        /// instead of failing.
        static func workflowOptions(taskQueue: String) -> WorkflowOptions {
            .init(id: "wf-\(UUID().uuidString)", taskQueue: taskQueue, executionTimeOut: .seconds(10))
        }

        /// Waits for the workflow execution to fail and returns the application error it failed with.
        static func workflowFailure<W: WorkflowDefinition>(
            of handle: WorkflowHandle<W>,
            sourceLocation: SourceLocation = #_sourceLocation
        ) async throws -> ApplicationError {
            let error = try await #require(throws: WorkflowFailedError.self, sourceLocation: sourceLocation) {
                try await handle.result()
            }
            return try #require(error.cause as? ApplicationError, sourceLocation: sourceLocation)
        }

        /// Waits for the first `WorkflowTaskFailed` event in the workflow's history, then terminates the
        /// workflow, whose workflow task would otherwise keep failing.
        ///
        /// Fails if the workflow execution closed instead.
        static func workflowTaskFailure<W: WorkflowDefinition>(
            of handle: WorkflowHandle<W>,
            sourceLocation: SourceLocation = #_sourceLocation
        ) async throws -> Api.History.V1.WorkflowTaskFailedEventAttributes {
            let closedEventTypes: [Api.Enums.V1.EventType] = [
                .workflowExecutionCompleted, .workflowExecutionFailed, .workflowExecutionTimedOut,
            ]
            let deadline = ContinuousClock.now.advanced(by: .seconds(10))
            while ContinuousClock.now < deadline {
                let events = try await handle.fetchHistoryEvents()
                if let closed = events.first(where: { closedEventTypes.contains($0.eventType) }) {
                    Issue.record(
                        "Workflow execution closed with \(closed.eventType) instead of failing its workflow task",
                        sourceLocation: sourceLocation
                    )
                    throw WorkflowTaskFailureNotFound()
                }
                if let event = events.first(where: { $0.eventType == .workflowTaskFailed }) {
                    try await handle.terminate()
                    return event.workflowTaskFailedEventAttributes
                }
                try await Task.sleep(for: .milliseconds(100))
            }
            Issue.record("Timed out waiting for a workflow task failure", sourceLocation: sourceLocation)
            // The workflow may have timed out in the meantime, which the issue above already covers.
            try? await handle.terminate()
            throw WorkflowTaskFailureNotFound()
        }

        // MARK: - Nondeterminism

        /// Starts a timer on the first execution only, so replaying the history hits nondeterminism.
        static func startTimerUnlessReplaying<W: WorkflowDefinition>(_ context: WorkflowContext<W>) async throws {
            if !context.isReplaying {
                try await context.sleep(for: .milliseconds(1))
            }
        }

        @Workflow
        struct NondeterministicWorkflow {
            func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await WorkflowFailureTests.startTimerUnlessReplaying(context)
            }
        }

        @Workflow(failureErrorTypes: [WorkflowNondeterminismError.self])
        struct NondeterministicFailingWorkflow {
            func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await WorkflowFailureTests.startTimerUnlessReplaying(context)
            }
        }

        @Test
        func nondeterminismWithDefaultsFailsTheTask() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(maxCachedWorkflows: 0),
                workflows: [NondeterministicWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: NondeterministicWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let failure = try await Self.workflowTaskFailure(of: handle)
                #expect(failure.cause == .nonDeterministicError)
            }
        }

        @Test
        func nondeterminismInWorkerListFailsTheWorkflow() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(
                    workflowFailureErrorTypes: [WorkflowNondeterminismError.self],
                    maxCachedWorkflows: 0
                ),
                workflows: [NondeterministicWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: NondeterministicWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let failure = try await Self.workflowFailure(of: handle)
                #expect(failure.message.contains("Nondeterminism"))
            }
        }

        @Test
        func nondeterminismPerWorkflowOnlyFailsThatType() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(maxCachedWorkflows: 0),
                workflows: [NondeterministicWorkflow.self, NondeterministicFailingWorkflow.self]
            ) { taskQueue, client in
                let failing = try await client.startWorkflow(
                    type: NondeterministicFailingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let workflowFailure = try await Self.workflowFailure(of: failing)
                #expect(workflowFailure.message.contains("Nondeterminism"))

                let other = try await client.startWorkflow(
                    type: NondeterministicWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let failure = try await Self.workflowTaskFailure(of: other)
                #expect(failure.cause == .nonDeterministicError)
            }
        }

        // MARK: - Run method

        @Workflow
        struct ThrowingWorkflow {
            func run(context: WorkflowContext<Self>, input: Void) async throws {
                throw DomainError()
            }
        }

        @Workflow(failureErrorTypes: [DomainError.self])
        struct ThrowingFailingWorkflow {
            func run(context: WorkflowContext<Self>, input: Void) async throws {
                throw DomainError()
            }
        }

        @Workflow(failureErrorTypes: [DomainError.self])
        struct OtherThrowingFailingWorkflow {
            func run(context: WorkflowContext<Self>, input: Void) async throws {
                throw OtherError()
            }
        }

        @Test
        func workerAndWorkflowListsCombine() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [OtherError.self]),
                workflows: [ThrowingFailingWorkflow.self, OtherThrowingFailingWorkflow.self]
            ) { taskQueue, client in
                let workflowListed = try await client.startWorkflow(
                    type: ThrowingFailingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let workflowListedFailure = try await Self.workflowFailure(of: workflowListed)
                #expect(workflowListedFailure.type == "DomainError")
                #expect(!workflowListedFailure.isNonRetryable)

                let workerListed = try await client.startWorkflow(
                    type: OtherThrowingFailingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                #expect(try await Self.workflowFailure(of: workerListed).type == "OtherError")
            }
        }

        @Test
        func perWorkflowListDoesNotAffectOtherWorkflows() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(),
                workflows: [ThrowingWorkflow.self, ThrowingFailingWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: ThrowingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let failure = try await Self.workflowTaskFailure(of: handle)
                #expect(failure.cause == .workflowWorkerUnhandledFailure)
            }
        }

        // MARK: - Update handlers

        @Workflow
        struct UpdateThrowingWorkflow {
            private var done = false

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.condition { $0.done }
            }

            @WorkflowUpdate
            mutating func fail(context: WorkflowContext<Self>, input: Void) async throws {
                throw DomainError()
            }

            @WorkflowUpdate
            mutating func finish(context: WorkflowContext<Self>, input: Void) async throws {
                self.done = true
            }
        }

        @Test
        func unlistedErrorInUpdateFailsTheTask() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(),
                workflows: [UpdateThrowingWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UpdateThrowingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                // The update never completes, because its workflow task keeps failing.
                let update = Task {
                    try await handle.executeUpdate(updateType: UpdateThrowingWorkflow.Fail.self, input: ())
                }
                let failure = try await Self.workflowTaskFailure(of: handle)
                #expect(failure.cause == .workflowWorkerUnhandledFailure)
                update.cancel()
                _ = await update.result
            }
        }

        @Test
        func errorInWorkerListFailsOnlyTheUpdate() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [DomainError.self]),
                workflows: [UpdateThrowingWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UpdateThrowingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let error = try await #require(throws: WorkflowUpdateFailedError.self) {
                    try await handle.executeUpdate(updateType: UpdateThrowingWorkflow.Fail.self, input: ())
                }
                #expect((error.cause as? ApplicationError)?.type == "DomainError")
                try await handle.executeUpdate(updateType: UpdateThrowingWorkflow.Finish.self, input: ())
                try await handle.result()
            }
        }

        @Workflow
        struct UpdateResultWorkflow {
            private var done = false

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.condition { $0.done }
            }

            @WorkflowUpdate
            mutating func returnUnencodable(context: WorkflowContext<Self>, input: Void) async throws -> Unencodable {
                Unencodable()
            }

            @WorkflowUpdate
            mutating func continueAsNew(context: WorkflowContext<Self>, input: Void) async throws {
                throw try await context.makeContinueAsNewError(options: .init())
            }

            @WorkflowUpdate
            mutating func finish(context: WorkflowContext<Self>, input: Void) async throws {
                self.done = true
            }
        }

        @Test
        func listedErrorFromUpdateResultEncodingFailsOnlyTheUpdate() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [PayloadConverterError.self]),
                workflows: [UpdateResultWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UpdateResultWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let error = try await #require(throws: WorkflowUpdateFailedError.self) {
                    try await handle.executeUpdate(updateType: UpdateResultWorkflow.ReturnUnencodable.self, input: ())
                }
                #expect((error.cause as? ApplicationError)?.type == "PayloadConverterError")
                try await handle.executeUpdate(updateType: UpdateResultWorkflow.Finish.self, input: ())
                try await handle.result()
            }
        }

        @Test
        func continueAsNewFromUpdateFailsTheTaskEvenIfListed() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [(any Error).self]),
                workflows: [UpdateResultWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UpdateResultWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                // The update never completes, because its workflow task keeps failing.
                let update = Task {
                    try await handle.executeUpdate(updateType: UpdateResultWorkflow.ContinueAsNew.self, input: ())
                }
                let failure = try await Self.workflowTaskFailure(of: handle)
                #expect(failure.cause == .workflowWorkerUnhandledFailure)
                update.cancel()
                _ = await update.result
            }
        }

        // MARK: - Signal handlers

        @Workflow
        struct SignalThrowingWorkflow {
            private var done = false

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.condition { $0.done }
            }

            @WorkflowSignal
            mutating func fail(context: WorkflowContext<Self>, input: Void) async throws {
                throw DomainError()
            }
        }

        @Test
        func unlistedErrorInSignalFailsTheTask() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(),
                workflows: [SignalThrowingWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SignalThrowingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                try await handle.signal(signalType: SignalThrowingWorkflow.Fail.self)
                let failure = try await Self.workflowTaskFailure(of: handle)
                #expect(failure.cause == .workflowWorkerUnhandledFailure)
            }
        }

        @Test
        func listedErrorInSignalFailsTheWorkflow() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [DomainError.self]),
                workflows: [SignalThrowingWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SignalThrowingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                try await handle.signal(signalType: SignalThrowingWorkflow.Fail.self)
                let failure = try await Self.workflowFailure(of: handle)
                #expect(failure.type == "DomainError")
            }
        }

        // MARK: - Precedence

        @Workflow
        struct ContinueAsNewOnceWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Bool) async throws -> String {
                if input {
                    return "continued"
                }
                throw try await context.makeContinueAsNewError(options: .init(), input: true)
            }
        }

        @Test
        func continueAsNewTakesPrecedenceOverList() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [ContinueAsNewError.self]),
                workflows: [ContinueAsNewOnceWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: ContinueAsNewOnceWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue),
                    input: false
                )
                #expect(try await handle.result() == "continued")
            }
        }

        @Test
        func cancellationTakesPrecedenceOverList() async throws {
            typealias CancellationWorkflow = WorkflowCancellationTests.CancellationWorkflow
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [CancellationError.self]),
                workflows: [CancellationWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: CancellationWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue),
                    input: .swiftCancellationError
                )
                try await handle.cancel()
                let error = try await #require(throws: WorkflowFailedError.self) {
                    try await handle.result()
                }
                #expect((error.cause as? CanceledError)?.message == "Workflow execution canceled")
            }
        }

        // MARK: - Payload conversion

        struct Unencodable {}

        @Workflow
        struct UnencodableResultWorkflow {
            func run(context: WorkflowContext<Self>, input: Void) async throws -> Unencodable {
                Unencodable()
            }
        }

        @Test
        func unlistedErrorFromResultEncodingFailsTheTask() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(),
                workflows: [UnencodableResultWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UnencodableResultWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let failure = try await Self.workflowTaskFailure(of: handle)
                #expect(failure.cause == .workflowWorkerUnhandledFailure)
            }
        }

        @Test
        func listedErrorFromResultEncodingFailsTheWorkflow() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [PayloadConverterError.self]),
                workflows: [UnencodableResultWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UnencodableResultWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                let failure = try await Self.workflowFailure(of: handle)
                #expect(failure.type == "PayloadConverterError")
            }
        }

        @Workflow(name: "InputDecodingWorkflow")
        struct IntInputWorkflow {
            func run(context: WorkflowContext<Self>, input: Int) async throws {}
        }

        /// Shares its name with ``IntInputWorkflow``, so starting it sends input that workflow can't decode.
        @Workflow(name: "InputDecodingWorkflow")
        struct StringInputWorkflow {
            func run(context: WorkflowContext<Self>, input: String) async throws {}
        }

        @Test
        func unlistedErrorFromInputDecodingFailsTheTask() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(),
                workflows: [IntInputWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: StringInputWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue),
                    input: "not a number"
                )
                let failure = try await Self.workflowTaskFailure(of: handle)
                #expect(failure.cause == .workflowWorkerUnhandledFailure)
            }
        }

        @Test
        func listedErrorFromInputDecodingFailsTheWorkflow() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [DecodingError.self]),
                workflows: [IntInputWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: StringInputWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue),
                    input: "not a number"
                )
                let failure = try await Self.workflowFailure(of: handle)
                #expect(failure.type == "DecodingError")
            }
        }

        /// Throws an application error when decoded.
        struct RejectingInput: Codable {
            init(from decoder: any Decoder) throws {
                throw ApplicationError(message: "Rejected decoding", type: "Rejected")
            }
        }

        @Workflow(name: "RejectingInputWorkflow")
        struct RejectingInputWorkflow {
            func run(context: WorkflowContext<Self>, input: RejectingInput) async throws {}
        }

        /// Shares its name with ``RejectingInputWorkflow``, so starting it sends input that workflow rejects.
        @Workflow(name: "RejectingInputWorkflow")
        struct BoolInputWorkflow {
            func run(context: WorkflowContext<Self>, input: Bool) async throws {}
        }

        @Test
        func temporalFailureFromInputDecodingFailsTheWorkflow() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(),
                workflows: [RejectingInputWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: BoolInputWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue),
                    input: true
                )
                let failure = try await Self.workflowFailure(of: handle)
                #expect(failure.message == "Rejected decoding")
            }
        }

        // MARK: - Replayer

        @Test
        func replayWorkflowFailedFromListedErrorNeedsTheList() async throws {
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(workflowFailureErrorTypes: [DomainError.self]),
                workflows: [ThrowingWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: ThrowingWorkflow.self,
                    options: Self.workflowOptions(taskQueue: taskQueue)
                )
                _ = try await Self.workflowFailure(of: handle)
                let history = try await handle.fetchHistory()

                let replayer = WorkflowReplayer(
                    configuration: .init(
                        workflows: [ThrowingWorkflow.self],
                        workflowFailureErrorTypes: [DomainError.self]
                    )
                )
                let result = try await replayer.replayWorkflow(history: history, throwOnReplayFailure: false)
                #expect(result.replayFailure == nil)

                let replayerWithoutList = WorkflowReplayer(configuration: .init(workflows: [ThrowingWorkflow.self]))
                let resultWithoutList = try await replayerWithoutList.replayWorkflow(
                    history: history,
                    throwOnReplayFailure: false
                )
                #expect(resultWithoutList.replayFailure is InvalidOperationError)
            }
        }
    }
}
