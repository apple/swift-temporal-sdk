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

import Foundation
import Temporal
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowExecutionDescriptionTests {
        @Workflow
        struct SimpleWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.condition { false }
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func describeIncludesStaticSummaryAndDetails() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"
            let workflowID = "wf-\(UUID().uuidString)"

            try await withTestWorkerAndClient(
                taskQueue: taskQueue,
                workflows: [SimpleWorkflow.self]
            ) { taskQueue, client in
                var options = WorkflowOptions(id: workflowID, taskQueue: taskQueue)
                options.staticSummary = "test summary"
                options.staticDetails = "test details"

                let handle = try await client.startWorkflow(
                    type: SimpleWorkflow.self,
                    options: options,
                    input: ()
                )

                let description = try await handle.describe()

                #expect(description.execution.workflowID == workflowID)
                #expect(description.staticSummary == "test summary")
                #expect(description.staticDetails == "test details")
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func describeWithNoMetadataHasNilSummaryAndDetails() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"
            let workflowID = "wf-\(UUID().uuidString)"

            try await withTestWorkerAndClient(
                taskQueue: taskQueue,
                workflows: [SimpleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SimpleWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: ()
                )

                let description = try await handle.describe()

                #expect(description.execution.workflowID == workflowID)
                #expect(description.staticSummary == nil)
                #expect(description.staticDetails == nil)
            }
        }
    }
}
