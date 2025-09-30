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
final class MultipleActivitiesWorkflow {
    func run(input: String) async throws -> String {
        // First, fetch user data from database
        let userData = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.FetchUserData.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: input
        )
        
        // Call the first activity to compose a greeting using database template
        let greeting = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.ComposeGreeting.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: userData
        )
        
        // Call the second activity to add exclamation
        let withExclamation = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.AddExclamation.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: greeting
        )
        
        // Call the third activity to add question marks
        let withQuestion = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.AddQuestion.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: withExclamation
        )
        
        // Call the fourth activity to convert to uppercase
        let upperCase = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.ToUpperCase.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: withQuestion
        )
        
        // Call the fifth activity to add a prefix from database
        let withPrefix = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.AddPrefix.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: upperCase
        )
        
        // Finally, save the result to database
        let saveResult = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.SaveResult.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: withPrefix
        )
        
        return "\(withPrefix) | \(saveResult)"
    }
}
