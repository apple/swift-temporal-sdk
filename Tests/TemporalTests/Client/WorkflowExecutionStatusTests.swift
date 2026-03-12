//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import AsyncAlgorithms
import Foundation
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct WorkflowExecutionStatusTests {
        @Workflow
        final class SimpleStatusWorkflow {
            func run(input: Void) async -> String {
                "done"
            }
        }

        @Workflow
        final class WaitingStatusWorkflow {
            func run(input: Void) async throws {
                try await Workflow.condition { false }
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func describeRunningWorkflowHasRunningStatus() async throws {
            try await workflowHandle(
                for: WaitingStatusWorkflow.self,
                input: ()
            ) { handle in
                // Give the workflow a moment to start
                try await Task.sleep(for: .milliseconds(500))

                let description = try await handle.describe()
                #expect(description.execution.status == .running)

                // Terminate so the test can exit
                try await handle.terminate()
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func describeCompletedWorkflowHasCompletedStatus() async throws {
            try await workflowHandle(
                for: SimpleStatusWorkflow.self,
                input: ()
            ) { handle in
                _ = try await handle.result()

                let description = try await handle.describe()
                #expect(description.execution.status == .completed)
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func listWorkflowsReturnsCorrectStatus() async throws {
            let workflowID = "wf-\(UUID().uuidString)"

            try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                workflows: [SimpleStatusWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SimpleStatusWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: ()
                )

                _ = try await handle.result()

                let executions = try await Array(
                    client.listWorkflows(
                        query: "WorkflowId = '\(workflowID)'"
                    )
                )

                let execution = try #require(executions.first)
                #expect(execution.status == .completed)
            }
        }
    }
}
