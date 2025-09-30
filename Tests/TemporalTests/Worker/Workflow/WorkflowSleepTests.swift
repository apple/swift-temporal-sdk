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
    struct WorkflowSleepTests {
        @Workflow
        final class SleepWorkflow {
            enum Scenario: Codable {
                case singleSleep
                case multiSleep
                case concurrentSleep
                case alreadyCanceledSleep
                case cancelSleep
                case negativeDuration
                case zeroDuration
                case cancelWorklow
            }

            func run(input: Scenario) async throws -> String {
                switch input {
                case .singleSleep:
                    try await Workflow.sleep(for: .seconds(1))
                    return "Done"
                case .multiSleep:
                    try await Workflow.sleep(for: .seconds(1))
                    try await Workflow.sleep(for: .seconds(1))
                    try await Workflow.sleep(for: .seconds(1))
                    return "Done"
                case .concurrentSleep:
                    return try await self.concurrentSleep()
                case .alreadyCanceledSleep:
                    return await self.alreadyCanceledSleep()
                case .cancelSleep:
                    return await self.cancelSleep()
                case .negativeDuration:
                    return await self.negativeDuration()
                case .zeroDuration:
                    try await Workflow.sleep(for: .zero)
                    return "Done"
                case .cancelWorklow:
                    try? await Workflow.sleep(for: .seconds(10000))
                    return "Done"
                }
            }

            private func concurrentSleep() async throws -> String {
                return try await withThrowingTaskGroup(of: String.self) { group in
                    group.addTask {
                        try await Workflow.sleep(for: .seconds(1))
                        return "1"
                    }
                    group.addTask {
                        try await Workflow.sleep(for: .seconds(1))
                        return "2"
                    }
                    group.addTask {
                        try await Workflow.sleep(for: .seconds(1))
                        return "3"
                    }
                    var output = ""
                    for try await result in group {
                        output.append(result)
                    }
                    return output
                }
            }

            private func alreadyCanceledSleep() async -> String {
                await withThrowingTaskGroup(of: String.self) { group in
                    group.cancelAll()
                    group.addTask {
                        try await Workflow.sleep(for: .seconds(100))
                        return "Second"
                    }
                    do {
                        return try await group.next()!
                    } catch {
                        return "\(type(of: error))"
                    }
                }
            }

            private func cancelSleep() async -> String {
                await withThrowingTaskGroup(of: String.self) { group in
                    group.addTask {
                        try await Workflow.sleep(for: .seconds(100))
                        return "Done"
                    }

                    do {
                        try await Workflow.sleep(for: .seconds(1))
                        group.cancelAll()
                        return try await group.next()!
                    } catch {
                        return "\(type(of: error))"
                    }
                }
            }

            private func negativeDuration() async -> String {
                do {
                    try await Workflow.sleep(for: .seconds(-1))
                } catch {
                    return "\(type(of: error))"
                }
                return "Done"
            }
        }

        @Test(arguments: [
            (SleepWorkflow.Scenario.singleSleep, "Done"),
            (SleepWorkflow.Scenario.multiSleep, "Done"),
            (SleepWorkflow.Scenario.concurrentSleep, "123"),
            (SleepWorkflow.Scenario.alreadyCanceledSleep, "CanceledError"),
            (SleepWorkflow.Scenario.cancelSleep, "CanceledError"),
            (SleepWorkflow.Scenario.negativeDuration, "ArgumentError"),
            (SleepWorkflow.Scenario.zeroDuration, "Done"),
        ])
        func sleep(scenario: SleepWorkflow.Scenario, expectedResult: String) async throws {
            let result = try await executeWorkflow(
                SleepWorkflow.self,
                input: scenario
            )
            #expect(result == expectedResult)
        }

        @Test
        func cancelWorkflow() async throws {
            try await withTestWorkerAndClient(
                workflows: [SleepWorkflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: SleepWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: .cancelWorklow
                )

                try await handle.cancel()

                let result = try await handle.result()
                #expect(result == "Done")
            }
        }

        @Test
        func interceptsSleep() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let counter: Mutex<Int> = .init(0)

                struct Outbound: WorkflowOutboundInterceptor {
                    let interceptor: CountingInterceptor

                    func handleSleep(
                        input: HandleSleepInput,
                        next: (HandleSleepInput) async throws -> Void
                    ) async throws {
                        interceptor.counter.withLock { $0 += 1 }
                        return try await next(input)
                    }
                }

                func makeWorkflowOutboundInterceptor() -> Outbound? {
                    return Outbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            _ = try await executeWorkflow(
                SleepWorkflow.self,
                input: .singleSleep,
                interceptors: [interceptor]
            )

            #expect(interceptor.counter.withLock { $0 } == 1)
        }
    }
}
