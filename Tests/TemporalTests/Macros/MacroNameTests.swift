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
import Temporal
import Testing

extension TestServerDependentTests {
    @Suite
    struct MacroNameTests {
        @Test
        func defaultWorkflowNameMatchesTypeName() async throws {
            let name = ExampleWorkflowDefaultName.name
            #expect(name == "ExampleWorkflowDefaultName")
        }

        @Test
        func customWorkflowName() {
            let name = ExampleWorkflowCustomName.name
            #expect(name == "MyCustomWorkflowName")
        }

        @Test
        func defaultActivityNameMatchesFunctionName() async throws {
            let name = ExampleActivityContainer.Activities.ActivityDefault.name
            #expect(name == "ActivityDefault")
        }
        @Test
        func customActivityName() async throws {
            let name = ExampleActivityContainer.Activities.ActivityCustom.name
            #expect(name == "CustomActivity")
        }
        @Test
        func runningActivityWithDefaultName() async throws {
            _ = try await executeWorkflow(
                ExampleWorkflowDefaultName.self,
                input: "",
                activities: ExampleActivityContainer().allActivities
            )
        }

        @Test
        func runningActivityWithCustomName() async throws {
            _ = try await executeWorkflow(
                ExampleWorkflowCustomName.self,
                input: "",
                activities: ExampleActivityContainer().allActivities
            )
        }

        /// Has a default workflow name, invokes an activity
        /// with a default name.
        @Workflow
        final class ExampleWorkflowDefaultName {
            func run(
                input: String
            ) async throws -> String {
                let activity = ExampleActivityContainer.Activities.ActivityDefault.self
                return try await Workflow.executeActivity(
                    activity,
                    options: .init(startToCloseTimeout: .seconds(3)),
                    input: input
                )
            }
        }

        /// Has a custom workflow name, invokes an activity
        /// with a custom name.
        @Workflow(name: "MyCustomWorkflowName")
        final class ExampleWorkflowCustomName {
            func run(
                input: String
            ) async throws -> String {
                let activity = ExampleActivityContainer.Activities.ActivityCustom.self
                return try await Workflow.executeActivity(
                    activity,
                    options: .init(startToCloseTimeout: .seconds(3)),
                    input: input
                )
            }
        }

        @ActivityContainer
        struct ExampleActivityContainer {
            @Activity
            func activityDefault(input: String) async throws -> String {
                input
            }

            @Activity(name: "CustomActivity")
            func activityCustom(input: String) async throws -> String {
                input
            }
        }
    }
}
