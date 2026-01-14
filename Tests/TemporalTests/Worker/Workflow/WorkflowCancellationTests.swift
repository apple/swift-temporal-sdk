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

import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowCancellationTests {
        enum Scenario: Hashable, Codable, CaseIterable {
            case swiftCancellationError
            case cancelledError
            case activityCancelled
            case childWorkflowCancelled
        }

        @ActivityContainer
        final class CancellationActivities {
            @Activity
            static func activityCancellation() async throws {
                try await Task.sleep(for: .seconds(40))
            }
        }

        @Workflow
        final class CancellationWorkflow {
            func run(input: Scenario) async throws {
                switch input {
                case .swiftCancellationError:
                    do {
                        try await Workflow.condition { false }
                    } catch {
                        // ignore cancellation handling from Workflow/condition(_:)
                        try Task.checkCancellation()
                    }
                case .cancelledError:
                    try await Workflow.sleep(for: .seconds(40))
                case .activityCancelled:
                    try await Workflow.executeActivity(
                        CancellationActivities.Activities.ActivityCancellation.self,
                        options: ActivityOptions(scheduleToCloseTimeout: .seconds(60))
                    )
                case .childWorkflowCancelled:
                    try await Workflow.executeChildWorkflow(
                        CancellationWorkflow.self,
                        options: .init(),
                        input: .cancelledError
                    )
                }
            }
        }

        @Workflow
        final class ThrowingWorkflow {
            func run(input: Void) async throws {
                throw CanceledError(message: "Workflow wasn't actually cancelled.")
            }
        }

        @Test("Workflow Cancellation", arguments: Scenario.allCases)
        func workflowCancellation(scenario: Scenario) async throws {
            try await workflowHandle(for: CancellationWorkflow.self, input: scenario, activities: CancellationActivities().allActivities) { handle in
                try await Task.sleep(for: .milliseconds(200))
                await #expect(throws: Never.self) {
                    try await handle.cancel()
                }

                let error = try await #require(throws: WorkflowFailedError.self) {
                    try await handle.result()
                }

                // `workflowExecutionCanceled` command translates to exactly this error
                #expect(error.cause is CanceledError)
                #expect((error.cause as? CanceledError)?.message == "Workflow execution canceled")
            }
        }

        @Test("Workflow Task must be cancelled")
        func workflowNotCancelled() async throws {
            // Make sure that we only treat Workflow cancelled if Task.isCancelled
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(ThrowingWorkflow.self, input: ())
            }

            // CanceledError message didn't get translated, so wasn't treated as cancellation
            let cancelledError = try #require(error.cause as? CanceledError)
            #expect(cancelledError.message == "Workflow wasn't actually cancelled.")
        }
    }
}
