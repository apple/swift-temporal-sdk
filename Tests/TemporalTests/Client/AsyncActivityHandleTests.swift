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

import struct GRPCCore.RPCError

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct AsyncActivityHandleTests {  // includes tests of the async activity interceptors
        struct AsyncActivityEvent: Equatable {
            enum Kind {
                case heartbeatAsyncActivity
                case completeAsyncActivity
                case failAsyncActivity
                case reportCancellationAsyncActivity
            }

            let tick: Int
            let kind: Kind

            init(_ tick: Int, kind: Kind) {
                self.tick = tick
                self.kind = kind
            }
        }

        final class AsyncActivityInterceptor: ClientInterceptor {
            let ticker: Mutex<Int> = .init(0)
            let events: Mutex<[AsyncActivityEvent]> = .init([])

            struct Outbound: ClientOutboundInterceptor {
                let interceptor: AsyncActivityInterceptor

                func heartbeatAsyncActivity(
                    input: HeartbeatAsyncActivityInput,
                    next: (HeartbeatAsyncActivityInput) async throws -> Void
                ) async throws {
                    self.interceptor.record(.heartbeatAsyncActivity)
                    return try await next(input)
                }

                func completeAsyncActivity<Result>(
                    input: CompleteAsyncActivityInput<Result>,
                    next: (CompleteAsyncActivityInput<Result>) async throws -> Void
                ) async throws {
                    self.interceptor.record(.completeAsyncActivity)
                    return try await next(input)
                }

                func failAsyncActivity(
                    input: FailAsyncActivityInput,
                    next: (FailAsyncActivityInput) async throws -> Void
                ) async throws {
                    self.interceptor.record(.failAsyncActivity)
                    return try await next(input)
                }

                func reportCancellationAsyncActivity(
                    input: ReportCancellationAsyncActivityInput,
                    next: (ReportCancellationAsyncActivityInput) async throws -> Void
                ) async throws {
                    self.interceptor.record(.reportCancellationAsyncActivity)
                    return try await next(input)
                }
            }

            func makeClientOutboundInterceptor() -> Outbound? {
                Outbound(interceptor: self)
            }

            func record(_ kind: AsyncActivityEvent.Kind) {
                let tick = self.ticker.withLock {
                    $0 += 1
                    return $0
                }
                self.events.withLock { $0.append(.init(tick, kind: kind)) }
            }
        }

        @Workflow
        final class AsyncCompletionWorkflow {
            func run(input: String) async throws -> String {
                let activity = CompleteExternalContainer.Activities.ActivityDefault.self
                return try await Workflow.executeActivity(
                    activity,
                    options: .init(scheduleToCloseTimeout: .seconds(1)),
                    input: input
                )
            }
        }

        @ActivityContainer
        struct CompleteExternalContainer {
            var taskTokenContinuation: AsyncStream<ActivityTaskToken>.Continuation

            @Activity
            func activityDefault(input: String) async throws -> String {
                self.taskTokenContinuation.yield(ActivityExecutionContext.current!.info.taskToken)
                self.taskTokenContinuation.finish()
                throw CompleteAsyncError()
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func asyncCompletionSucceeds() async throws {
            let interceptor = AsyncActivityInterceptor()
            let workflowID = UUID().uuidString
            let (taskTokenStream, taskTokenContinuation) = AsyncStream<ActivityTaskToken>.makeStream()

            return try await withTestWorkerAndClient(
                clientInterceptors: [interceptor],
                activities: CompleteExternalContainer(taskTokenContinuation: taskTokenContinuation).allActivities,
                workflows: [AsyncCompletionWorkflow.self],
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: AsyncCompletionWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "testInput"
                )

                let taskToken = await Array(taskTokenStream).first!

                let activityHandle = client.asyncActivityHandle(for: .taskToken(taskToken: taskToken))
                let expectedResult = "Yay completed"
                try await activityHandle.complete(result: expectedResult)

                let result = try await handle.result()

                #expect(expectedResult == result)

                // test interceptors
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .completeAsyncActivity)
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func asyncCompletionHeartbeatAndFailIsRecorded() async throws {
            let interceptor = AsyncActivityInterceptor()
            let workflowID = UUID().uuidString
            let (taskTokenStream, taskTokenContinuation) = AsyncStream<ActivityTaskToken>.makeStream()

            try await withTestWorkerAndClient(
                clientInterceptors: [interceptor],
                activities: CompleteExternalContainer(taskTokenContinuation: taskTokenContinuation).allActivities,
                workflows: [AsyncCompletionWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: AsyncCompletionWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "input"
                )

                let taskToken = await Array(taskTokenStream).first!

                // send heartbeat with details ["foo", "bar"]
                let asyncActivityHandle = client.asyncActivityHandle(for: .taskToken(taskToken: taskToken))
                try await asyncActivityHandle.heartbeat(options: .init(details: ["foo", "bar"]))

                let description = try await handle.describe()
                let payloads = description.pendingActivities.first!.heartbeatDetails
                let foo: String = try DataConverter.default.payloadConverter.convertPayloadHandlingVoid(payloads[0], as: String.self)
                let bar: String = try DataConverter.default.payloadConverter.convertPayloadHandlingVoid(payloads[1], as: String.self)
                #expect(foo == "foo")
                #expect(bar == "bar")

                // fail the async activity and verify workflow fails with correct info
                try await asyncActivityHandle.fail(InvalidOperationError(message: "Oh no"))

                do {
                    let _: String = try await handle.result()
                    Issue.record("Expected workflow to fail")
                } catch let error as WorkflowFailedError {
                    guard let activityFailure = error.cause as? ActivityError else {
                        Issue.record("Expected ActivityError, got \(error)")
                        return
                    }

                    guard let applicationFailure = activityFailure.cause as? ApplicationError else {
                        Issue.record("Expected ApplicationError, got \(error)")
                        return
                    }

                    #expect(applicationFailure.message == "Oh no")
                    #expect(applicationFailure.type == "InvalidOperationError")
                } catch {
                    Issue.record("Unexpected error: \(error)")
                }

                // test interceptors
                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .heartbeatAsyncActivity),
                        .init(2, kind: .failAsyncActivity),
                    ]
                )
            }
        }

        @Workflow
        final class AsyncCompletionCancellationWaitingWorkflow {
            func run(input: String) async throws -> String {
                let activity = CompleteExternalContainer.Activities.ActivityDefault.self
                return try await Workflow.executeActivity(
                    activity,
                    options: .init(scheduleToCloseTimeout: .seconds(1), cancellationType: .waitCancellationCompleted),
                    input: input
                )
            }
        }

        @Test(.timeLimit(.minutes(1)), if: .enabled(false))
        func asyncCompletionCancelReportsCancel() async throws {
            let interceptor = AsyncActivityInterceptor()
            let workflowID = UUID().uuidString
            let (taskTokenStream, taskTokenContinuation) = AsyncStream<ActivityTaskToken>.makeStream()

            try await withTestWorkerAndClient(
                clientInterceptors: [interceptor],
                activities: CompleteExternalContainer(taskTokenContinuation: taskTokenContinuation).allActivities,
                workflows: [AsyncCompletionCancellationWaitingWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: AsyncCompletionCancellationWaitingWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "input"
                )

                let taskToken = await Array(taskTokenStream).first!
                let asyncHandle = client.asyncActivityHandle(for: .taskToken(taskToken: taskToken))

                try await handle.cancel()

                // The async activity should start reporting “cancellation requested” to the async handle.
                // We assert this by heartbeating until we see the cancellation error.
                var sawCancellation = false
                for _ in 0..<15 {  // C# does the same polling
                    do {
                        try await asyncHandle.heartbeat()  // no details
                        try await Task.sleep(for: .milliseconds(300))
                    } catch is AsyncActivityCanceledError {
                        sawCancellation = true
                        break
                    } catch {
                        Issue.record("Unexpected heartbeat error: \(error)")
                        break
                    }
                }
                #expect(sawCancellation, "Expected async heartbeat to report cancellation")

                // Report cancellation back to the server
                try await asyncHandle.reportCancellation()

                // Workflow should fail with a cancellation
                do {
                    let _: String = try await handle.result()
                    Issue.record("Expected workflow to be cancelled")
                } catch let wf as WorkflowFailedError {
                    let activityError = try #require(wf.cause as? ActivityError, "Expected `ActivityError`, got \(String(describing: wf.cause))")
                    #expect(activityError.message == "Activity cancelled")
                } catch {
                    Issue.record("Unexpected error from workflow result: \(error)")
                }

                // test interceptors
                let events = interceptor.events.withLock { $0 }
                #expect(events.first!.kind == .heartbeatAsyncActivity)  // there can be up to 15 heartbeat events
                #expect(events.last!.kind == .reportCancellationAsyncActivity)  // last one needs to be the reporting of cancellation
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func asyncCompletionStartToCloseTimeoutReportsCancel() async throws {
            let interceptor = AsyncActivityInterceptor()
            let workflowID = UUID().uuidString
            let (taskTokenStream, taskTokenContinuation) = AsyncStream<ActivityTaskToken>.makeStream()

            try await withTestWorkerAndClient(
                clientInterceptors: [interceptor],
                activities: CompleteExternalContainer(taskTokenContinuation: taskTokenContinuation).allActivities,
                workflows: [AsyncCompletionCancellationWaitingWorkflow.self]
            ) { taskQueue, client in
                _ = try await client.startWorkflow(
                    type: AsyncCompletionCancellationWaitingWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "input"
                )

                // Wait for the activity task token emitted by the activity
                let taskToken = await Array(taskTokenStream).first!

                // Heartbeat until server reports NotFound (i.e., activity already timed out)
                let asyncHandle = client.asyncActivityHandle(for: .taskToken(taskToken: taskToken))
                var sawNotFound = false
                for _ in 0..<15 {  // C# does the same polling
                    do {
                        try await asyncHandle.heartbeat()  // no details
                        try await Task.sleep(for: .milliseconds(300))
                    } catch let e as RPCError where e.code == .notFound {
                        sawNotFound = true
                        break
                    } catch {
                        Issue.record("Unexpected heartbeat error: \(error)")
                        break
                    }
                }
                #expect(sawNotFound, "Expected heartbeat to report not found after start-to-close timeout")

                // test interceptors
                let events = interceptor.events.withLock { $0 }
                #expect(events.first!.kind == .heartbeatAsyncActivity)  // there can be up to 15 heartbeat events
            }
        }
    }
}
