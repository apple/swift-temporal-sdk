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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct WorkflowHandleTests {
        @Workflow
        struct HelloWorldWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async -> String {
                "Hello, World!"
            }
        }

        @Workflow
        struct HelloInputWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: String) async -> String {
                input
            }
        }

        @Test
        func startWorkflowWithoutInput() async throws {
            try await workflowHandle(for: HelloWorldWorkflow.self, input: ()) { handle in
                let result = try await handle.result()
                #expect(result == "Hello, World!")
            }

            let result = try await workflowHandle(for: HelloWorldWorkflow.self, input: ()) { handle in
                try await handle.result()
            }
            #expect(result == "Hello, World!")
        }

        @Test
        func startWorkflowWithInput() async throws {
            let input = "Hello, Input!"

            try await workflowHandle(for: HelloInputWorkflow.self, input: input) { handle in
                let result = try await handle.result()
                #expect(result == input)
            }
        }

        @Test
        func startWorkflowThrowsAlreadyStartedErrorWhenWorkflowIsRunning() async throws {
            try await withTestWorkerAndClient(workflows: [HelloWorldWorkflow.self]) { _, client in
                let workflowID = "wf-\(UUID())"
                // Nothing polls this task queue so the first execution stays running.
                let options = WorkflowOptions(
                    id: workflowID,
                    taskQueue: "unpolled-\(UUID())",
                    executionTimeOut: .seconds(60)
                )
                let handle = try await client.startWorkflow(type: HelloWorldWorkflow.self, options: options)

                let error = await #expect(throws: WorkflowAlreadyStartedError.self) {
                    try await client.startWorkflow(type: HelloWorldWorkflow.self, options: options)
                }
                #expect(error?.workflowID == workflowID)
                #expect(error?.workflowName == HelloWorldWorkflow.name)
                #expect(error?.runID == handle.resultRunID)

                try await handle.terminate()
            }
        }

        @Test
        func startWorkflowThrowsAlreadyStartedErrorWhenWorkflowIsFinished() async throws {
            try await withTestWorkerAndClient(workflows: [HelloWorldWorkflow.self]) { taskQueue, client in
                let workflowID = "wf-\(UUID())"
                let options = WorkflowOptions(
                    id: workflowID,
                    taskQueue: taskQueue,
                    executionTimeOut: .seconds(60),
                    idReusePolicy: .rejectDuplicate
                )
                let handle = try await client.startWorkflow(type: HelloWorldWorkflow.self, options: options)
                _ = try await handle.result()

                let error = await #expect(throws: WorkflowAlreadyStartedError.self) {
                    try await client.startWorkflow(type: HelloWorldWorkflow.self, options: options)
                }
                #expect(error?.workflowID == workflowID)
                #expect(error?.workflowName == HelloWorldWorkflow.name)
                #expect(error?.runID == handle.resultRunID)
            }
        }
    }
}
