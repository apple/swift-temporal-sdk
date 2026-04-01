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
    struct WorkflowUpdateTests {
        @Workflow
        final class UpdateWorkflow {
            private var state = ""

            func run(input: Void) async throws {
                try await Workflow.condition { self.state == "updated" }
                try await Workflow.condition { Workflow.allHandlersFinished }
            }

            @WorkflowUpdate
            func update(input: String) async throws -> String {
                self.state = "updated"
                return "Hello from update, \(input)"
            }
        }

        @Test
        func simpleUpdate() async throws {
            try await withTestWorkerAndClient(
                workflows: [UpdateWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: UpdateWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )
                let result = try await handle.executeUpdate(
                    updateType: UpdateWorkflow.Update.self,
                    input: "test"
                )
                #expect(result == "Hello from update, test")

                try await handle.result()
            }
        }

        @Test
        func startUpdateWithAcceptedStage() async throws {
            try await withTestWorkerAndClient(
                workflows: [UpdateWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: UpdateWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )
                let updateHandle = try await handle.startUpdate(
                    updateType: UpdateWorkflow.Update.self,
                    waitForStage: .accepted,
                    input: "test-accepted"
                )
                let result = try await updateHandle.result()
                #expect(result == "Hello from update, test-accepted")

                try await handle.result()
            }
        }

        @Test
        func interceptsUpdate() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let updateCounter: Mutex<Int> = .init(0)
                let validateCounter: Mutex<Int> = .init(0)

                struct Inbound: WorkflowInboundInterceptor {
                    let interceptor: CountingInterceptor

                    func handleUpdate<Update>(
                        input: HandleUpdateInput<Update>,
                        next: (HandleUpdateInput<Update>) async throws -> Update.Output
                    ) async throws -> Update.Output {
                        interceptor.updateCounter.withLock { $0 += 1 }
                        return try await next(input)
                    }

                    func validateUpdate<Update>(
                        input: HandleUpdateInput<Update>,
                        next: (HandleUpdateInput<Update>) throws -> Void
                    ) throws {
                        interceptor.validateCounter.withLock { $0 += 1 }
                        try next(input)
                    }
                }

                var workflowInboundInterceptor: Inbound? {
                    return Inbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            try await withTestWorkerAndClient(
                interceptors: [interceptor],
                workflows: [UpdateWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: UpdateWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )
                let result = try await handle.executeUpdate(
                    updateType: UpdateWorkflow.Update.self,
                    input: "test"
                )
                #expect(result == "Hello from update, test")

                try await handle.result()

                // These expectations are >= 1 since the workflow might run multiple times
                // in tests if the tests are slow
                #expect(interceptor.updateCounter.withLock { $0 } >= 1)
                #expect(interceptor.validateCounter.withLock { $0 } >= 1)
            }
        }

        // MARK: - Update-with-Start Tests

        @Workflow
        final class UpdateWithStartTargetWorkflow {
            var value: String = ""

            func run(input: String) async throws -> String {
                try await Workflow.condition { !self.value.isEmpty }
                return self.value
            }

            @WorkflowUpdate
            func setValue(input: String) async -> String {
                self.value = input
                return "updated:\(input)"
            }
        }

        @Test
        func startUpdateWithStartNewWorkflow() async throws {
            try await withTestWorkerAndClient(
                workflows: [UpdateWithStartTargetWorkflow.self]
            ) { taskQueue, client in
                let workflowID = "wf-\(UUID().uuidString)"
                let options = WorkflowOptions(id: workflowID, taskQueue: taskQueue)

                // Atomically start workflow and send update
                let updateHandle = try await client.startUpdateWithStartWorkflow(
                    type: UpdateWithStartTargetWorkflow.self,
                    input: "initial",
                    options: options,
                    updateType: UpdateWithStartTargetWorkflow.SetValue.self,
                    updateInput: "hello",
                    waitForStage: .accepted
                )

                // Verify the update handle is returned and the result is correct
                let updateResult = try await updateHandle.result()
                #expect(updateResult == "updated:hello")

                // Verify the workflow actually started and can complete
                let workflowHandle = client.workflowHandle(
                    type: UpdateWithStartTargetWorkflow.self,
                    id: workflowID
                )
                let workflowResult = try await workflowHandle.result()
                #expect(workflowResult == "hello")
            }
        }

        @Test
        func executeUpdateWithStartNewWorkflow() async throws {
            try await withTestWorkerAndClient(
                workflows: [UpdateWithStartTargetWorkflow.self]
            ) { taskQueue, client in
                let workflowID = "wf-\(UUID().uuidString)"
                let options = WorkflowOptions(id: workflowID, taskQueue: taskQueue)

                // Convenience method that waits for the update result directly
                let updateResult = try await client.executeUpdateWithStartWorkflow(
                    type: UpdateWithStartTargetWorkflow.self,
                    input: "initial",
                    options: options,
                    updateType: UpdateWithStartTargetWorkflow.SetValue.self,
                    updateInput: "world"
                )

                #expect(updateResult == "updated:world")

                // Verify the workflow started correctly
                let workflowHandle = client.workflowHandle(
                    type: UpdateWithStartTargetWorkflow.self,
                    id: workflowID
                )
                let workflowResult = try await workflowHandle.result()
                #expect(workflowResult == "world")
            }
        }

        @Test
        func updateWithStartExistingWorkflow() async throws {
            try await withTestWorkerAndClient(
                workflows: [UpdateWithStartTargetWorkflow.self]
            ) { taskQueue, client in
                let workflowID = "wf-\(UUID().uuidString)"

                // First, start the workflow normally
                let handle = try await client.startWorkflow(
                    type: UpdateWithStartTargetWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: "initial"
                )

                // Now use update-with-start on the same workflow ID with useExisting policy
                var options = WorkflowOptions(id: workflowID, taskQueue: taskQueue)
                options.idConflictPolicy = .useExisting

                let updateResult = try await client.executeUpdateWithStartWorkflow(
                    type: UpdateWithStartTargetWorkflow.self,
                    input: "ignored",
                    options: options,
                    updateType: UpdateWithStartTargetWorkflow.SetValue.self,
                    updateInput: "from-existing"
                )

                // The update should be delivered to the existing workflow
                #expect(updateResult == "updated:from-existing")

                // The existing workflow should complete with the update value
                let workflowResult = try await handle.result()
                #expect(workflowResult == "from-existing")
            }
        }

        @Test
        func untypedUpdateWithStart() async throws {
            try await withTestWorkerAndClient(
                workflows: [UpdateWithStartTargetWorkflow.self]
            ) { taskQueue, client in
                let workflowID = "wf-\(UUID().uuidString)"
                let options = WorkflowOptions(id: workflowID, taskQueue: taskQueue)

                // Use the untyped variant with string names
                let updateHandle = try await client.startUpdateWithStartWorkflow(
                    name: UpdateWithStartTargetWorkflow.name,
                    input: "initial",
                    options: options,
                    updateName: UpdateWithStartTargetWorkflow.SetValue.name,
                    updateInput: "untyped-hello",
                    waitForStage: .accepted
                )

                // Retrieve the result using the untyped handle
                let updateResult: String = try await updateHandle.result(
                    resultTypes: String.self
                )
                #expect(updateResult == "updated:untyped-hello")

                // Verify the workflow started and can complete
                let workflowHandle = client.untypedWorkflowHandle(id: workflowID)
                let workflowResult: String = try await workflowHandle.result(
                    resultTypes: String.self
                )
                #expect(workflowResult == "untyped-hello")
            }
        }
    }
}
