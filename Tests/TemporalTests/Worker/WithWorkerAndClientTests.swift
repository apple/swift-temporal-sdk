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
    @Suite
    struct WithWorkerAndClientTests {
        @ActivityContainer
        struct TestActivities {
            @Activity
            func greet(input: String) -> String {
                "Hello, \(input)!"
            }
        }

        @Workflow
        struct TestWorkflow {
            mutating func run(
                context: WorkflowContext<Self>,
                input: String
            ) async throws -> String {
                try await context.executeActivity(
                    TestActivities.Activities.Greet.self,
                    options: ActivityOptions(startToCloseTimeout: .seconds(30)),
                    input: input
                )
            }
        }

        @Test
        func workflowExecutesThroughHelper() async throws {
            let testServer = TemporalTestServer.testServer!

            let result = try await testServer.withWorkerAndClient(
                activities: TestActivities().allActivities,
                workflows: [TestWorkflow.self]
            ) { taskQueue, client in
                try await client.executeWorkflow(
                    type: TestWorkflow.self,
                    options: .init(id: "wf-\(UUID())", taskQueue: taskQueue),
                    input: "World"
                )
            }
            #expect(result == "Hello, World!")
        }
    }
}
