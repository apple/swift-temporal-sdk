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

import Temporal

@Workflow
final class ErrorHandlingWorkflow {
    // Input type to determine which scenario to run
    enum Scenario: String, Codable {
        case success  // Will retry and succeed
        case nonRetryable  // Will fail with non-retryable error
        case compensation  // Will trigger compensation logic
    }
    
    // Helper function to extract key from profile result
    private func extractKeyFromProfileResult(_ profileResult: String) -> String {
        // Extract key from "Profile updated successfully with key: profile_XXXX"
        if let range = profileResult.range(of: "key: ") {
            return String(profileResult[range.upperBound...])
        }
        return "unknown_key"
    }

    func run(input: Scenario) async throws -> String {
        switch input {
        case .success:
            // Demonstrate successful retry pattern across multiple activities.
            // Only the first activity (FetchUserData) is expected to encounter
            // transient errors and be retried. The second activity should run
            // once the first has succeeded, showing Temporal preserves workflow
            // state across retries.
            let fetched = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.FetchUserData.self,
                options: .init(
                    scheduleToCloseTimeout: .seconds(30),
                    retryPolicy: .init(
                        initialInterval: .milliseconds(100),
                        backoffCoefficient: 2.0,
                        maximumInterval: .seconds(5),
                        maximumAttempts: 5
                    )
                ),
                input: "user1"  // This key exists and will succeed after retries
            )

            // Use the fetched result as input to a second activity which should
            // succeed (no transient errors expected here). This demonstrates
            // that only the failing activity is retried while the workflow
            // continues after success.
            let saved = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.SaveWithValidation.self,
                options: .init(
                    scheduleToCloseTimeout: .seconds(30),
                    retryPolicy: .init(
                        initialInterval: .milliseconds(200),
                        backoffCoefficient: 1.5,
                        maximumInterval: .seconds(3),
                        maximumAttempts: 4
                    )
                ),
                input: fetched
            )

            return "Success after retries: \(fetched)\nSaved: \(saved)"

        case .nonRetryable:
            // First activity should succeed (fetch user data)
            let fetched = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.FetchUserData.self,
                options: .init(
                    scheduleToCloseTimeout: .seconds(30),
                    retryPolicy: .init(
                        initialInterval: .milliseconds(100),
                        backoffCoefficient: 2.0,
                        maximumInterval: .seconds(5),
                        maximumAttempts: 5
                    )
                ),
                input: "user2"  // This will succeed immediately
            )

            // Second activity will fail with non-retryable error
            let saved = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.SaveWithValidation.self,
                options: .init(
                    scheduleToCloseTimeout: .seconds(30),
                    retryPolicy: .init(
                        initialInterval: .milliseconds(500),
                        maximumAttempts: 3,
                        nonRetryableErrorTypes: ["InvalidInputError"]
                    )
                ),
                input: ""  // Empty input will trigger validation error
            )

            return "Fetched: \(fetched)\nSaved: \(saved)"

        case .compensation:
            // First activity should succeed (fetch user data)
            let fetched = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.FetchUserData.self,
                options: .init(
                    scheduleToCloseTimeout: .seconds(30),
                    retryPolicy: .init(
                        initialInterval: .milliseconds(100),
                        backoffCoefficient: 2.0,
                        maximumInterval: .seconds(5),
                        maximumAttempts: 5
                    )
                ),
                input: "user3"  // This will succeed immediately
            )

            // Second activity - update user profile (this will succeed)
            let profileKey = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.UpdateUserProfile.self,
                options: .init(
                    scheduleToCloseTimeout: .seconds(30),
                    retryPolicy: .init(
                        initialInterval: .milliseconds(100),
                        backoffCoefficient: 2.0,
                        maximumInterval: .seconds(5),
                        maximumAttempts: 5
                    )
                ),
                input: "\(fetched)_profile_data"
            )

            // Third activity will fail and trigger compensation
            do {
                let processed = try await Workflow.executeActivity(
                    ErrorHandlingActivities.Activities.ProcessWithCompensation.self,
                    options: .init(
                        scheduleToCloseTimeout: .seconds(30),
                        retryPolicy: .init(
                            initialInterval: .milliseconds(200),
                            backoffCoefficient: 1.5,
                            maximumInterval: .seconds(2),
                            maximumAttempts: 4
                        )
                    ),
                    input: "\(fetched)_trigger_failure"  // This will trigger compensation
                )
                return "Fetched: \(fetched)\nProfile: \(profileKey)\nProcessed: \(processed)"
            } catch {
                // Rollback the profile update when the third activity fails
                print("🔄 Third activity failed, rolling back profile update...")
                do {
                    let rollbackResult = try await Workflow.executeActivity(
                        ErrorHandlingActivities.Activities.RollbackUserProfile.self,
                        options: .init(
                            scheduleToCloseTimeout: .seconds(30),
                            retryPolicy: .init(
                                initialInterval: .milliseconds(100),
                                backoffCoefficient: 2.0,
                                maximumInterval: .seconds(5),
                                maximumAttempts: 3
                            )
                        ),
                        input: extractKeyFromProfileResult(profileKey)
                    )
                    print("✅ Rollback completed: \(rollbackResult)")
                } catch {
                    print("❌ Rollback failed: \(error.localizedDescription)")
                }
                
                throw ApplicationError(
                    message: "Operation failed and profile was rolled back",
                    type: "CompensationError",
                    isNonRetryable: true
                )
            }
        }
    }
}
