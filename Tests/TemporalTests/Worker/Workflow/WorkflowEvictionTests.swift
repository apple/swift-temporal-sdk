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
import Logging
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    /// Regression tests for the fatal crash that previously occurred when a worker was torn
    /// down while a workflow was parked inside `try await childHandle.result()`.
    ///
    /// Before the fix, `WorkflowStateMachineStorage.uncancellableCondition` did
    /// `try! await withCheckedThrowingContinuation { … }`. When the worker's
    /// cache evicted the parked workflow, the continuation was resumed with
    /// `WorkflowRemovedFromCacheError`, the `try!` re-raised, and the worker
    /// thread terminated fatally — causing tests to hang indefinitely.
    ///
    /// After the fix, eviction surfaces as a regular thrown error from the workflow code.
    /// The worker shuts down cleanly and the test completes.
    @Suite(.tags(.workflowTests))
    struct WorkflowEvictionTests {

        @Workflow
        struct ChildWorkflow {
            struct Input: Codable {}

            func run(context: WorkflowContext<Self>, input: Input) async throws {
                // Long enough that the parent is guaranteed to still be awaiting this when
                // the test body returns and the worker tears down.
                try await context.sleep(for: .seconds(300))
            }
        }

        @Workflow
        struct ParentWorkflow {
            struct Input: Codable {}

            enum Phase: String, Codable, Sendable {
                case waiting
                case awaitingChild
            }

            struct EmptyInput: Codable {}
            struct ShutdownInput: Codable {}

            private var phase: Phase = .waiting
            private var shutdownRequested: Bool = false

            @WorkflowSignal
            mutating func shutdown(context: WorkflowContext<Self>, input: ShutdownInput) {
                shutdownRequested = true
            }

            @WorkflowQuery
            func currentPhase(input: EmptyInput) -> Phase {
                return phase
            }

            mutating func run(context: WorkflowContext<Self>, input: Input) async throws {
                try await context.condition { $0.shutdownRequested }

                let childHandle = try await context.startChildWorkflow(
                    ChildWorkflow.self,
                    options: ChildWorkflowOptions(id: "evict-child-\(context.info.workflowID)"),
                    input: ChildWorkflow.Input()
                )
                phase = .awaitingChild
                _ = try await childHandle.result()
            }
        }

        /// Returning from the worker body while the parent is parked inside
        /// `try await childHandle.result()` used to crash the worker thread.
        ///
        /// With the fix, the eviction surfaces as a thrown error and the test
        /// completes cleanly.
        @Test
        func workerTeardownWhileParentAwaitsChildDoesNotFatal() async throws {
            try await withTestWorkerAndClient(
                workflows: [ParentWorkflow.self, ChildWorkflow.self]
            ) { taskQueue, client in
                let parentId = "evict-parent-\(UUID().uuidString)"

                _ = try await client.startWorkflow(
                    type: ParentWorkflow.self,
                    options: .init(id: parentId, taskQueue: taskQueue),
                    input: ParentWorkflow.Input()
                )
                let parentHandle = client.untypedWorkflowHandle(id: parentId)

                try await parentHandle.signal(
                    signalName: "Shutdown",
                    input: ParentWorkflow.ShutdownInput()
                )

                // Poll until the parent reports it has entered the uncancellable
                // `await childHandle.result()`. Without this we may exit the test body
                // before the parent ever enters the failing code path.
                let deadline = ContinuousClock.now.advanced(by: .seconds(5))
                while ContinuousClock.now < deadline {
                    let phase: ParentWorkflow.Phase = try await parentHandle.query(
                        queryName: "CurrentPhase",
                        input: ParentWorkflow.EmptyInput(),
                        resultTypes: ParentWorkflow.Phase.self
                    )
                    if phase == .awaitingChild { break }
                    try await Task.sleep(for: .milliseconds(20))
                }

                // Returning here used to fatal in `WorkflowStateMachineStorage`. So the test
                // passing here is the assertion.
            }
        }
    }
}
