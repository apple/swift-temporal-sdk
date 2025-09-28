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

import Foundation
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowCancelActivityTests {
        final class CancellationActivity: ActivityDefinition {
            let forceComplete = Mutex<String?>(nil)
            let done = Mutex<String>("")

            func run(input: Void) async throws -> String {
                do {
                    while true {
                        ActivityExecutionContext.current?.heartbeat(details: ())

                        if let value = self.forceComplete.withLock({ $0 }) {
                            self.done.withLock { $0 = "done" }
                            return value
                        } else {
                            try await Task.sleep(for: .seconds(0.1))
                        }
                    }
                } catch is CancellationError {
                    self.done.withLock { $0 = "cancelled" }
                    guard case .serverRequest = ActivityExecutionContext.current?.cancellationReason else {
                        Issue.record("Incorrect activity cancellation Reason")
                        return ""
                    }
                    return "cancel swallowed"
                } catch {
                    self.done.withLock { $0 = "failure" }
                    return "\(error)"
                }
            }

            func forceComplete(value: String) {
                self.forceComplete.withLock { $0 = value }
            }
        }
        @Workflow
        final class CancellationWorkflow {
            enum Scenario: String, Codable, CaseIterable {
                case tryCancel
                case waitCancellationCompleted
                case abandon
            }

            func run(input: Void) async throws {
                try await Workflow.condition { false }
            }

            @WorkflowUpdate
            func update(input: Scenario) async throws -> String {
                let cancellationType =
                    switch input {
                    case .tryCancel:
                        ActivityOptions.CancellationType.tryCancel
                    case .waitCancellationCompleted:
                        ActivityOptions.CancellationType.waitCancellationCompleted
                    case .abandon:
                        ActivityOptions.CancellationType.abandon
                    }
                return try await Workflow.timeout(for: .seconds(0.1)) {
                    try await Workflow.executeActivity(
                        CancellationActivity.self,
                        options: .init(
                            scheduleToCloseTimeout: .seconds(10),
                            cancellationType: cancellationType
                        )
                    )
                }
            }
        }

        @Workflow
        final class CancellationShieldWorkflow {
            func run(input: Void) async throws -> String {
                do {
                    try await Workflow.condition { false }
                    Issue.record("Condition finished unexpectedly.")
                    return "condition became true"
                } catch is CanceledError {
                    return try await Workflow.withCancellationShield {
                        try await Workflow.executeActivity(
                            CancellationActivity.self,
                            options: .init(scheduleToCloseTimeout: .seconds(10)),
                        )
                    }
                } catch {
                    Issue.record("Unexpected error: \(error)")
                    return "another error"
                }
            }
        }

        @Workflow
        final class SimpleActivityWorkflow {
            func run(input: Void) async throws {
                _ = try await Workflow.executeActivity(SimpleActivity.self, options: .init(scheduleToCloseTimeout: .seconds(60)))
            }
        }

        final class SimpleActivity: ActivityDefinition {
            private let calledContinuation: AsyncStream<Void>.Continuation

            init(calledContinuation: AsyncStream<Void>.Continuation) {
                self.calledContinuation = calledContinuation
            }

            func run(input: Void) async throws -> String {
                calledContinuation.yield()
                return "Hello World"
            }
        }

        @Test
        func testWorkflowCancellationRace() async throws {
            let activity = AsyncStream<Void>.makeStream()

            try await withTestWorkerAndClient(
                activities: [SimpleActivity(calledContinuation: activity.continuation)],
                workflows: [SimpleActivityWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(type: SimpleActivityWorkflow.self, options: .init(id: "a1", taskQueue: taskQueue))

                var iterator = activity.stream.makeAsyncIterator()
                await iterator.next(isolation: #isolation)  // we don't want to cancel before the activity was called
                try await Task.sleep(for: .milliseconds(5), tolerance: .zero)
                try await handle.cancel()

                do {
                    try await handle.result()
                } catch let error as WorkflowFailedError {
                    guard let canceledError = error.cause as? CanceledError else {
                        throw error
                    }

                    if canceledError.message == "Activity cancelled before scheduled" {
                        Issue.record(error, "Incorrect test setup. Activity cancelled before it was called")
                    }

                    // silence other canceled errors if it is flakey
                }
            }
        }

        @Test
        func tryCancel() async throws {
            let cancellationActivity = CancellationActivity()
            let workflowID = UUID().uuidString
            let taskQueue = "tq-\(UUID().uuidString)"

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: taskQueue,
                workerBuildID: "",
                maxHeartbeatThrottleInterval: .milliseconds(20),
                activities: [cancellationActivity],
                workflows: [CancellationWorkflow.self]
            ) { taskQueue, client in
                let updateHandle = try await client.startWorkflow(
                    type: CancellationWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                )

                let error = try await #require(throws: WorkflowUpdateFailedError.self) {
                    try await updateHandle.executeUpdate(
                        updateType: CancellationWorkflow.Update.self,
                        input: .tryCancel
                    )
                }
                let activityError = try #require(error.cause as? ActivityError)
                #expect(activityError.cause is CanceledError)
                while cancellationActivity.done.withLock({ $0 != "cancelled" }) {
                    try await Task.sleep(for: .seconds(0.1))
                }
            }
        }

        @Test
        func waitCancellationCompleted() async throws {
            let cancellationActivity = CancellationActivity()
            let workflowID = UUID().uuidString
            let taskQueue = "tq-\(UUID().uuidString)"

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: taskQueue,
                workerBuildID: "",
                maxHeartbeatThrottleInterval: .milliseconds(20),
                activities: [cancellationActivity],
                workflows: [CancellationWorkflow.self]
            ) { taskQueue, client in
                let updateHandle = try await client.startWorkflow(
                    type: CancellationWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                )

                let result = try await updateHandle.executeUpdate(
                    updateType: CancellationWorkflow.Update.self,
                    input: .waitCancellationCompleted
                )

                #expect(result == "cancel swallowed")
                #expect(cancellationActivity.done.withLock { $0 } == "cancelled")
            }
        }

        @Test
        func abandon() async throws {
            let cancellationActivity = CancellationActivity()
            let workflowID = UUID().uuidString
            let taskQueue = "tq-\(UUID().uuidString)"

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: taskQueue,
                workerBuildID: "",
                maxHeartbeatThrottleInterval: .milliseconds(20),
                activities: [cancellationActivity],
                workflows: [CancellationWorkflow.self]
            ) { taskQueue, client in
                let updateHandle = try await client.startWorkflow(
                    type: CancellationWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                )

                let error = try await #require(throws: WorkflowUpdateFailedError.self) {
                    try await updateHandle.executeUpdate(
                        updateType: CancellationWorkflow.Update.self,
                        input: .abandon
                    )
                }
                let activityError = try #require(error.cause as? ActivityError)
                #expect(activityError.cause is CanceledError)
                #expect(cancellationActivity.done.withLock { $0 } == "")
                cancellationActivity.forceComplete(value: "manually complete")
                while cancellationActivity.done.withLock({ $0 != "done" }) {
                    try await Task.sleep(for: .seconds(0.1))
                }
            }
        }

        @Test
        func workflowCancelShield() async throws {
            let cancellationActivity = CancellationActivity()
            let value = "hello world from the activity"
            let workflowID = UUID().uuidString
            cancellationActivity.forceComplete(value: value)

            try await withTestWorkerAndClient(
                activities: [cancellationActivity],
                workflows: [CancellationShieldWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: CancellationShieldWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                try await handle.cancel()
                let result = try await handle.result()

                #expect(cancellationActivity.done.withLock({ $0 == "done" }) == true)
                #expect(result == value)
            }
        }
    }
}
