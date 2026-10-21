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
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowWaitConditionTests {
        @Workflow
        struct WaitConditionWorkflow {
            enum Scenario: Codable {
                case workflowCancel
                case timeout
            }

            mutating func run(context: WorkflowContext<Self>, input: Scenario) async -> String {
                switch input {
                case .workflowCancel:
                    // For testing purposes we are ignoring the error here.
                    // We just want the workflow to complete.
                    try? await context.condition { false }
                    return "Done"
                case .timeout:
                    // For testing purposes we are ignoring the error here.
                    // We just want the workflow to complete.
                    try? await context.timeout(for: .seconds(1)) {
                        // Waiting until cancellation here.
                        try await context.condition { false }
                    }
                    return "Done"
                }
            }
        }

        @Workflow
        struct ConditionCancelledWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Duration) async -> String {
                do {
                    try? await Task.sleep(for: input)  // if it throws a cancellation error already we are good!
                    try await context.condition { false }
                    Issue.record("Condition resolved unexpectedly.")
                    return "Unexpected resolve"
                } catch let error as CanceledError {
                    return error.message
                } catch {
                    Issue.record(error, "Unexpected error.")
                    return "Unexpected error"
                }
            }
        }

        /// Echoes its activity type, so every waiter below can schedule a distinct type.
        struct ActivityTypeEchoActivity: ActivityDefinition {
            static var isDynamic: Bool { true }

            func run(input: [TemporalRawValue]) async throws -> String {
                ActivityExecutionContext.current!.info.activityType
            }
        }

        /// Parks `input` waiters on the same condition; one signal satisfies them all in the same
        /// activation and each waiter then schedules its own activity type.
        @Workflow
        struct ConditionOrderWorkflow {
            private var released = false

            mutating func run(context: WorkflowContext<Self>, input waiters: Int) async throws {
                try await withThrowingTaskGroup(of: String.self) { group in
                    for index in 0..<waiters {
                        group.addTask {
                            try await context.condition { $0.released }
                            return try await context.executeActivity(
                                name: "ConditionOrder\(index)",
                                options: .init(startToCloseTimeout: .seconds(10)),
                                input: index,
                                outputType: String.self
                            )
                        }
                    }
                    try await group.waitForAll()
                }
            }

            @WorkflowSignal
            mutating func release(input: Void) {
                released = true
            }
        }

        @Test
        func satisfiedConditionsResumeInRegistrationOrder() async throws {
            let waiters = 8
            try await withTestWorkerAndClient(
                activities: [ActivityTypeEchoActivity()],
                workflows: [ConditionOrderWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: ConditionOrderWorkflow.self,
                    options: .init(id: "condition-order-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: waiters
                )
                try await handle.signal(signalType: ConditionOrderWorkflow.Release.self)
                try await handle.result()

                let history = try await handle.fetchHistory()
                let scheduled = history.events.compactMap { event -> String? in
                    guard case .activityTaskScheduledEventAttributes(let attributes) = event.attributes else { return nil }
                    return attributes.activityType.name
                }
                #expect(scheduled == (0..<waiters).map { "ConditionOrder\($0)" })

                // Each replay builds a fresh workflow instance, which is where a hash-ordered table would differ.
                var config = WorkflowReplayer.Configuration()
                config.workflows.append(ConditionOrderWorkflow.self)
                for _ in 0..<5 {
                    let result = try await WorkflowReplayer(configuration: config).replayWorkflow(
                        history: history,
                        throwOnReplayFailure: false
                    )
                    #expect(result.replayFailure == nil)
                }
            }
        }

        @Test
        func replayConditionOrderFromJSONFileSucceeds() async throws {
            // Recorded by `satisfiedConditionsResumeInRegistrationOrder` in a separate test process.
            let url = try #require(
                Bundle.module.url(forResource: "condition-order", withExtension: "json", subdirectory: "Histories")
            )
            var config = WorkflowReplayer.Configuration()
            config.workflows.append(ConditionOrderWorkflow.self)
            let result = try await WorkflowReplayer(configuration: config).replayWorkflow(
                history: .fromJSON(workflowID: "condition-order", jsonData: Data(contentsOf: url)),
                throwOnReplayFailure: false
            )
            #expect(result.replayFailure == nil)
        }

        @Test(arguments: [
            (WaitConditionWorkflow.Scenario.timeout, "Done")
        ])
        func waitCondition(scenario: WaitConditionWorkflow.Scenario, expectedResult: String) async throws {
            let result = try await executeWorkflow(
                WaitConditionWorkflow.self,
                input: scenario
            )

            #expect(result == expectedResult)
        }

        @Test
        func cancelWorkflow() async throws {
            try await withTestWorkerAndClient(
                workflows: [WaitConditionWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: WaitConditionWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: .workflowCancel
                )

                try await handle.cancel()

                let result = try await handle.result()
                #expect(result == "Done")
            }
        }

        @Test
        func conditionCancelledBeforeStarted() async throws {
            try await withTestWorkerAndClient(
                workflows: [ConditionCancelledWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: ConditionCancelledWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: .seconds(1)  // the duration will throw a cancellation error anyways
                )

                try await handle.cancel()

                let result = try await handle.result()
                #expect(result == "Wait condition cancelled")
            }
        }

        @Test
        func conditionCancelledAfterStart() async throws {
            try await withTestWorkerAndClient(
                workflows: [ConditionCancelledWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: ConditionCancelledWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: .zero
                )

                try await Task.sleep(for: .seconds(1))

                try await handle.cancel()

                let result = try await handle.result()
                #expect(result == "Wait condition cancelled")
            }
        }
    }
}
