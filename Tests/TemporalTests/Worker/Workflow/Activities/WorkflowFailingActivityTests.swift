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

import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowFailingActivityTests {
        struct FailureActivity: ActivityDefinition {
            func run(input: Void) async throws {
                throw ApplicationError(message: "Intentional error")
            }
        }
        @Workflow
        final class FailureWorkflow {
            enum Scenario: String, Codable, CaseIterable {
                case local
                case remote
            }

            private let scenario: Scenario

            init(input: Scenario) {
                self.scenario = input
            }

            func run(input: Scenario) async throws {
                switch input {
                case .local:
                    try await Workflow.executeLocalActivity(
                        FailureActivity.self,
                        options: .init(startToCloseTimeout: .seconds(10), retryPolicy: .init(maximumAttempts: 1))
                    )
                case .remote:
                    try await Workflow.executeActivity(
                        FailureActivity.self,
                        options: .init(startToCloseTimeout: .seconds(10), retryPolicy: .init(maximumAttempts: 1))
                    )
                }
            }
        }

        @Test(arguments: FailureWorkflow.Scenario.allCases)
        func failure(scenario: FailureWorkflow.Scenario) async throws {
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    FailureWorkflow.self,
                    input: scenario,
                    activities: [FailureActivity()]
                )
            }

            let applicationError: ApplicationError
            switch scenario {
            case .local:
                applicationError = try #require(error.cause as? ApplicationError)
            case .remote:
                let activityError = try #require(error.cause as? ActivityError)
                applicationError = try #require(activityError.cause as? ApplicationError)
            }

            #expect(applicationError.message == "Intentional error")
        }
    }
}
