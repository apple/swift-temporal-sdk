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
    struct WorkflowSignalTests {
        @Workflow
        final class SignalWorkflow {
            enum SignalScenario: Codable {
                case updateState
                case throwTestFailureError
                case throwApplicationError
                case timer
                case updateStateAndWaitCondition
            }

            private var state = ""

            func run(input: Void) async throws {
                try await Workflow.condition { self.state == "signaled" }
                self.state = "runFinished"
                try await Workflow.condition { Workflow.allHandlersFinished }
            }

            @WorkflowSignal
            func signal(input: SignalScenario) async throws {
                switch input {
                case .updateState:
                    self.state = "signaled"
                case .throwTestFailureError:
                    throw TestFailureError()
                case .throwApplicationError:
                    throw ApplicationError(
                        message: "CustomApplicationError",
                        type: "Failure"
                    )
                case .timer:
                    try await Workflow.sleep(for: .seconds(1))
                    self.state = "signaled"
                case .updateStateAndWaitCondition:
                    self.state = "signaled"
                    try await Workflow.condition { self.state == "runFinished" }
                }
            }
        }

        @Test
        func signalWaitCondition() async throws {
            try await withTestWorkerAndClient(
                workflows: [SignalWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: SignalWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                try await handle.signal(
                    signalType: SignalWorkflow.Signal.self,
                    input: .updateState
                )

                try await handle.result()
            }
        }

        @Test
        func signalThrowTestFailureError() async throws {
            try await withTestWorkerAndClient(
                workflows: [SignalWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                var options = WorkflowOptions(id: workflowID, taskQueue: taskQueue)
                options.executionTimeOut = .seconds(3)
                let handle = try await client.startWorkflow(
                    type: SignalWorkflow.self,
                    options: options
                )

                try await handle.signal(
                    signalType: SignalWorkflow.Signal.self,
                    input: .throwTestFailureError
                )

                await #expect(throws: WorkflowFailedError.self) {
                    try await handle.result()
                }
            }
        }

        @Test
        func signalThrowApplicationError() async throws {
            try await withTestWorkerAndClient(
                workflows: [SignalWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                var options = WorkflowOptions(id: workflowID, taskQueue: taskQueue)
                options.executionTimeOut = .seconds(3)
                let handle = try await client.startWorkflow(
                    type: SignalWorkflow.self,
                    options: options
                )

                try await handle.signal(
                    signalType: SignalWorkflow.Signal.self,
                    input: .throwApplicationError
                )

                await #expect(throws: WorkflowFailedError.self) {
                    try await handle.result()
                }
            }
        }

        @Test
        func signalTimer() async throws {
            try await withTestWorkerAndClient(
                workflows: [SignalWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: SignalWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                try await handle.signal(
                    signalType: SignalWorkflow.Signal.self,
                    input: .timer
                )

                try await handle.result()
            }
        }

        @Test
        func updateStateAndWaitCondition() async throws {
            try await withTestWorkerAndClient(
                workflows: [SignalWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: SignalWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                try await handle.signal(
                    signalType: SignalWorkflow.Signal.self,
                    input: .updateStateAndWaitCondition
                )

                try await handle.result()
            }
        }

        @Test
        func interceptsSignal() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let counter: Mutex<Int> = .init(0)

                struct Inbound: WorkflowInboundInterceptor {
                    let interceptor: CountingInterceptor
                    func handleSignal<Signal>(
                        input: HandleSignalInput<Signal>,
                        next: (HandleSignalInput<Signal>) async throws -> Void
                    ) async throws {
                        interceptor.counter.withLock { $0 += 1 }
                        try await next(input)
                    }
                }

                func makeWorkflowInboundInterceptor() -> Inbound? {
                    return Inbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            try await withTestWorkerAndClient(
                interceptors: [interceptor],
                workflows: [SignalWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: SignalWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue)
                )

                try await handle.signal(
                    signalType: SignalWorkflow.Signal.self,
                    input: .updateState
                )

                try await handle.result()

                #expect(interceptor.counter.withLock { $0 } == 1)
            }
        }
    }
}
