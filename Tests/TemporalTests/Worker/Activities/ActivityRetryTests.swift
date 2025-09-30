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
    struct ActivityRetryTests {
        final class RetryTrackingActivity: ActivityDefinition {
            private let _numberOfAttempts = Mutex(0)

            var numberOfAttempts: Int {
                get {
                    self._numberOfAttempts.withLock { $0 }
                }
                set {
                    self._numberOfAttempts.withLock { $0 = newValue }
                }
            }

            func run(input: RetryTestWorkflow.Scenario) async throws {
                self.numberOfAttempts += 1
                throw RetryError(attempt: self.numberOfAttempts)
            }
        }

        struct RetryError: Error {
            let attempt: Int
        }

        struct NeverError: Error {}

        @Workflow
        final class RetryTestWorkflow {
            enum Scenario: String, Codable, Hashable {
                case defaultRetryPolicy
                case noRetryPolicy
                case customRetryPolicy
                case nonRetryableErrorTypesPolicy
            }

            func run(input: Scenario) async throws -> String {
                let options: ActivityOptions
                switch input {
                case .defaultRetryPolicy:
                    options = .init(
                        scheduleToCloseTimeout: .seconds(10)
                    )
                case .noRetryPolicy:
                    options = .init(
                        scheduleToCloseTimeout: .seconds(10),
                        retryPolicy: .init(maximumAttempts: 1)
                    )
                case .customRetryPolicy:
                    options = .init(
                        scheduleToCloseTimeout: .seconds(30),
                        retryPolicy: .init(
                            initialInterval: .milliseconds(100),
                            backoffCoefficient: 1.5,
                            maximumInterval: .seconds(1),
                            maximumAttempts: 5,
                            nonRetryableErrorTypes: []
                        )
                    )
                case .nonRetryableErrorTypesPolicy:
                    options = .init(
                        scheduleToCloseTimeout: .seconds(30),
                        retryPolicy: .init(
                            nonRetryableErrorTypes: ["RetryError"]
                        )
                    )
                }

                try await Workflow.executeActivity(
                    RetryTrackingActivity.self,
                    options: options,
                    input: input
                )

                throw NeverError()
            }
        }

        @Test
        func defaultRetryPolicy() async throws {
            let activity = RetryTrackingActivity()
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    RetryTestWorkflow.self,
                    input: RetryTestWorkflow.Scenario.defaultRetryPolicy,
                    workflowExecutionTimeout: .seconds(30),
                    activities: [activity]
                )
            }

            let activityError = try #require(error.cause as? ActivityError)
            let applicationError = try #require(activityError.cause as? ApplicationError)
            #expect(applicationError.type == "RetryError")

            #expect(activity.numberOfAttempts > 1)
        }

        @Test
        func noRetryPolicy() async throws {
            let activity = RetryTrackingActivity()
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    RetryTestWorkflow.self,
                    input: RetryTestWorkflow.Scenario.noRetryPolicy,
                    workflowExecutionTimeout: .seconds(30),
                    activities: [activity]
                )
            }

            let activityError = try #require(error.cause as? ActivityError)
            let applicationError = try #require(activityError.cause as? ApplicationError)
            #expect(applicationError.type == "RetryError")

            #expect(activity.numberOfAttempts == 1)
        }

        @Test
        func customRetryPolicy() async throws {
            let activity = RetryTrackingActivity()
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    RetryTestWorkflow.self,
                    input: RetryTestWorkflow.Scenario.customRetryPolicy,
                    workflowExecutionTimeout: .seconds(30),
                    activities: [activity]
                )
            }

            let activityError = try #require(error.cause as? ActivityError)
            let applicationError = try #require(activityError.cause as? ApplicationError)
            #expect(applicationError.type == "RetryError")

            #expect(activity.numberOfAttempts == 5)
        }

        @Test
        func nonRetryableErrorTypesPolicy() async throws {
            let activity = RetryTrackingActivity()
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    RetryTestWorkflow.self,
                    input: RetryTestWorkflow.Scenario.nonRetryableErrorTypesPolicy,
                    workflowExecutionTimeout: .seconds(30),
                    activities: [activity]
                )
            }

            let activityError = try #require(error.cause as? ActivityError)
            let applicationError = try #require(activityError.cause as? ApplicationError)
            #expect(applicationError.type == "RetryError")

            // Occurrence of the `RetryError` limits the number of attempts to 1
            #expect(activity.numberOfAttempts == 1)
        }
    }
}
