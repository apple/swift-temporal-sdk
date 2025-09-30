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
        final class WaitConditionWorkflow {
            enum Scenario: Codable {
                case workflowCancel
                case timeout
            }

            func run(input: Scenario) async -> String {
                switch input {
                case .workflowCancel:
                    // For testing purposes we are ignoring the error here.
                    // We just want the workflow to complete.
                    try? await Workflow.condition { false }
                    return "Done"
                case .timeout:
                    // For testing purposes we are ignoring the error here.
                    // We just want the workflow to complete.
                    try? await Workflow.timeout(for: .seconds(1)) {
                        // Waiting until cancellation here.
                        try await Workflow.condition { false }
                    }
                    return "Done"
                }
            }
        }

        @Workflow
        final class ConditionCancelledWorkflow {
            func run(input: Duration) async -> String {
                do {
                    try? await Task.sleep(for: input)  // if it throws a cancellation error already we are good!
                    try await Workflow.condition { false }
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
