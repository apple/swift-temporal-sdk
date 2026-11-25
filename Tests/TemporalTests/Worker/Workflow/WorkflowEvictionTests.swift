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

import Logging
import Temporal
import TemporalTestKit
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TestServerDependentTests {
    /// Regression tests for the fatal crash that previously occurred when a worker was torn
    /// down while a workflow was parked inside `try await childHandle.result()`.
    ///
    /// Before the fix, `WorkflowStateMachineStorage.uncancellableCondition` did
    /// `try! await withCheckedThrowingContinuation { … }`. When the worker's
    /// cache evicted the parked workflow, the continuation was resumed with
    /// `WorkflowRemovedFromCacheError`, the `try!` re-raised, and the worker
    /// thread crashed — causing tests to block indefinitely.
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

        struct NoopActivity: ActivityDefinition {
            func run(input: Void) async throws {}
        }

        @Workflow
        struct CleanupAfterCancellationWorkflow {
            @WorkflowQuery
            func isParked(input: Void) -> Bool {
                true
            }

            func run(context: WorkflowContext<Self>, input: Void) async throws {
                do {
                    try await context.condition { false }
                } catch {
                    try await context.withCancellationShield {
                        try await context.executeActivity(
                            NoopActivity.self,
                            options: .init(startToCloseTimeout: .seconds(10))
                        )
                    }
                    throw error
                }
            }
        }

        /// Shutting down the worker evicts a workflow that awaits cleanup after a cancellation.
        ///
        /// Eviction cancels the workflow, so the parked condition throws `CanceledError`, as it would for a real
        /// cancellation. The workflow then awaits an activity inside a cancellation shield. Nothing resolves
        /// that activity once the workflow is evicted, so the workflow never finishes and the worker never
        /// shuts down.
        @Test
        func workerShutsDownWhileWorkflowAwaitsCleanup() async throws {
            let shutDown = await finishes(within: .seconds(30)) {
                try await withTestWorkerAndClient(
                    activities: [NoopActivity()],
                    workflows: [CleanupAfterCancellationWorkflow.self]
                ) { taskQueue, client in
                    let handle = try await client.startWorkflow(
                        type: CleanupAfterCancellationWorkflow.self,
                        options: .init(id: "evict-cleanup-\(UUID().uuidString)", taskQueue: taskQueue)
                    )
                    // Answered only once the workflow has run up to the condition.
                    _ = try await handle.query(queryType: CleanupAfterCancellationWorkflow.IsParked.self)
                }
            }
            #expect(shutDown, "The worker didn't shut down within 30 seconds")
        }

        /// Runs `operation` in an unstructured task and reports whether it finished within `timeout`.
        ///
        /// A stuck workflow ignores cancellation, so neither awaiting the operation nor a test time limit would
        /// end the test. The task is left behind when the timeout wins.
        private func finishes(
            within timeout: Duration,
            _ operation: @escaping @Sendable () async throws -> Void
        ) async -> Bool {
            let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
            Task {
                do {
                    try await operation()
                } catch {
                    Issue.record(error)
                }
                continuation.yield(true)
            }
            let timer = Task {
                try await Task.sleep(for: timeout)
                continuation.yield(false)
            }
            defer { timer.cancel() }
            for await finished in stream {
                return finished
            }
            return false
        }
    }
}
