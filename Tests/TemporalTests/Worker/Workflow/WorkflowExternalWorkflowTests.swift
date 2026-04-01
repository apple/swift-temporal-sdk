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
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowExternalWorkflowTests {
        @Workflow
        final class ExternalTargetWorkflow {
            private var signals = [String]()
            private var finished = false

            func run(input: Void) async throws -> String {
                try await Workflow.condition { self.finished }
                return "done"
            }

            @WorkflowSignal
            func signal(input: String) {
                self.signals.append(input)
            }

            @WorkflowSignal
            func finish(input: Void) {
                self.finished = true
            }

            @WorkflowQuery
            func getSignals(input: Void) -> [String] {
                self.signals
            }
        }

        @Workflow
        final class SignalExternalWorkflow {
            func run(input: String) async throws -> String {
                let handle = Workflow.getExternalWorkflowHandle(
                    ExternalTargetWorkflow.self,
                    id: input
                )
                try await handle.signal(
                    signalType: ExternalTargetWorkflow.Signal.self,
                    input: "hello"
                )
                try await handle.signal(
                    signalType: ExternalTargetWorkflow.Signal.self,
                    input: "world"
                )
                return "signaled"
            }
        }

        @Workflow
        final class CancelExternalWorkflow {
            func run(input: String) async throws -> String {
                let handle = Workflow.getExternalWorkflowHandle(
                    ExternalTargetWorkflow.self,
                    id: input
                )
                try await handle.cancel()
                return "cancelled"
            }
        }

        @Workflow
        final class SignalExternalWithInputWorkflow {
            func run(input: String) async throws -> String {
                let handle = Workflow.getExternalWorkflowHandle(id: input)
                try await handle.signal(
                    signalName: "Signal",
                    input: "custom-signal-data"
                )
                return "signaled-with-input"
            }
        }

        @Workflow
        final class CancelExternalUntypedWorkflow {
            func run(input: String) async throws -> String {
                let handle = Workflow.getExternalWorkflowHandle(id: input)
                try await handle.cancel()
                return "cancelled-untyped"
            }
        }

        @Test
        func signalExternalWorkflow() async throws {
            try await withTestWorkerAndClient(
                workflows: [
                    ExternalTargetWorkflow.self,
                    SignalExternalWorkflow.self,
                ]
            ) { taskQueue, client in
                // Start the target workflow
                let targetHandle = try await client.startWorkflow(
                    type: ExternalTargetWorkflow.self,
                    options: .init(id: "target-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: ()
                )

                // Start the parent workflow that signals the target
                let parentResult = try await client.startWorkflow(
                    type: SignalExternalWorkflow.self,
                    options: .init(id: "parent-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: targetHandle.id
                ).result()

                #expect(parentResult == "signaled")

                // Verify the signals were received
                let signals = try await targetHandle.query(queryType: ExternalTargetWorkflow.GetSignals.self)
                #expect(signals == ["hello", "world"])

                // Finish the target workflow
                try await targetHandle.signal(signalType: ExternalTargetWorkflow.Finish.self)
                let targetResult = try await targetHandle.result()
                #expect(targetResult == "done")
            }
        }

        @Test
        func cancelExternalWorkflow() async throws {
            try await withTestWorkerAndClient(
                workflows: [
                    ExternalTargetWorkflow.self,
                    CancelExternalWorkflow.self,
                ]
            ) { taskQueue, client in
                // Start the target workflow
                let targetHandle = try await client.startWorkflow(
                    type: ExternalTargetWorkflow.self,
                    options: .init(id: "target-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: ()
                )

                // Start the parent workflow that cancels the target
                let parentResult = try await client.startWorkflow(
                    type: CancelExternalWorkflow.self,
                    options: .init(id: "parent-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: targetHandle.id
                ).result()

                #expect(parentResult == "cancelled")

                // Verify the target workflow was cancelled
                let error = try await #require(throws: WorkflowFailedError.self) {
                    try await targetHandle.result()
                }
                #expect(error.cause is CanceledError)
            }
        }

        @Test
        func signalExternalWorkflowWithInput() async throws {
            try await withTestWorkerAndClient(
                workflows: [
                    ExternalTargetWorkflow.self,
                    SignalExternalWithInputWorkflow.self,
                ]
            ) { taskQueue, client in
                // Start the target workflow
                let targetHandle = try await client.startWorkflow(
                    type: ExternalTargetWorkflow.self,
                    options: .init(id: "target-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: ()
                )

                // Start the parent workflow that signals with custom input
                let parentResult = try await client.startWorkflow(
                    type: SignalExternalWithInputWorkflow.self,
                    options: .init(id: "parent-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: targetHandle.id
                ).result()

                #expect(parentResult == "signaled-with-input")

                // Verify the signal was received with the correct data
                let signals = try await targetHandle.query(queryType: ExternalTargetWorkflow.GetSignals.self)
                #expect(signals == ["custom-signal-data"])

                // Finish the target workflow
                try await targetHandle.signal(signalType: ExternalTargetWorkflow.Finish.self)
                let targetResult = try await targetHandle.result()
                #expect(targetResult == "done")
            }
        }

        @Test
        func interceptSignalExternalWorkflow() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let signalCount: Mutex<Int> = .init(0)
                let cancelCount: Mutex<Int> = .init(0)

                struct Outbound: WorkflowOutboundInterceptor {
                    let interceptor: CountingInterceptor

                    func signalExternalWorkflow<each Input>(
                        input: SignalExternalWorkflowInput<repeat each Input>,
                        next: (SignalExternalWorkflowInput<repeat each Input>) async throws -> Void
                    ) async throws {
                        interceptor.signalCount.withLock { $0 += 1 }
                        try await next(input)
                    }

                    func cancelExternalWorkflow(
                        input: CancelExternalWorkflowInput,
                        next: (CancelExternalWorkflowInput) async throws -> Void
                    ) async throws {
                        interceptor.cancelCount.withLock { $0 += 1 }
                        try await next(input)
                    }
                }

                var workflowOutboundInterceptor: Outbound? {
                    return Outbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            try await withTestWorkerAndClient(
                interceptors: [interceptor],
                workflows: [
                    ExternalTargetWorkflow.self,
                    SignalExternalWorkflow.self,
                ]
            ) { taskQueue, client in
                // Start the target workflow
                let targetHandle = try await client.startWorkflow(
                    type: ExternalTargetWorkflow.self,
                    options: .init(id: "target-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: ()
                )

                // Start the parent workflow that signals the target
                let parentResult = try await client.startWorkflow(
                    type: SignalExternalWorkflow.self,
                    options: .init(id: "parent-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: targetHandle.id
                ).result()

                #expect(parentResult == "signaled")

                // Verify interceptor was called for both signals
                #expect(interceptor.signalCount.withLock { $0 } == 2)

                // Finish the target workflow
                try await targetHandle.signal(signalType: ExternalTargetWorkflow.Finish.self)
                _ = try await targetHandle.result()
            }
        }

        @Test
        func cancelExternalWorkflowUntyped() async throws {
            try await withTestWorkerAndClient(
                workflows: [
                    ExternalTargetWorkflow.self,
                    CancelExternalUntypedWorkflow.self,
                ]
            ) { taskQueue, client in
                // Start the target workflow
                let targetHandle = try await client.startWorkflow(
                    type: ExternalTargetWorkflow.self,
                    options: .init(id: "target-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: ()
                )

                // Start the parent workflow that cancels the target using untyped handle
                let parentResult = try await client.startWorkflow(
                    type: CancelExternalUntypedWorkflow.self,
                    options: .init(id: "parent-wf-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: targetHandle.id
                ).result()

                #expect(parentResult == "cancelled-untyped")

                // Verify the target workflow was cancelled
                let error = try await #require(throws: WorkflowFailedError.self) {
                    try await targetHandle.result()
                }
                #expect(error.cause is CanceledError)
            }
        }
    }
}
