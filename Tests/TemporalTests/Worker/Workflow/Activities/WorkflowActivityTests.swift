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

import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowActivityTests {
        struct SimpleActivity: ActivityDefinition {
            static let name: String? = "SimpleActivity"

            func run(input: String) async throws -> String {
                "From activity \(input)"
            }
        }

        @Workflow
        final class SimpleActivityWorkflow {
            enum Scenario: String, Codable, CaseIterable {
                case remoteSymbol
                case remoteStringName
                case localSymbol
                case localStringName
            }

            private let scenario: Scenario

            init(input: Scenario) {
                self.scenario = input
            }

            func run(input: Scenario) async throws -> String {
                switch input {
                case .remoteSymbol:
                    return try await Workflow.executeActivity(
                        SimpleActivity.self,
                        options: .init(startToCloseTimeout: .seconds(1)),
                        input: scenario.rawValue
                    )
                case .remoteStringName:
                    return try await Workflow.executeActivity(
                        name: "SimpleActivity",
                        options: .init(scheduleToCloseTimeout: .seconds(10)),
                        input: scenario.rawValue,
                        outputType: String.self
                    )
                case .localSymbol:
                    return try await Workflow.executeLocalActivity(
                        SimpleActivity.self,
                        options: .init(startToCloseTimeout: .seconds(1)),
                        input: scenario.rawValue
                    )
                case .localStringName:
                    return try await Workflow.executeLocalActivity(
                        name: "SimpleActivity",
                        options: .init(scheduleToCloseTimeout: .seconds(10)),
                        input: scenario.rawValue,
                        outputType: String.self
                    )
                }
            }
        }

        @Test(arguments: SimpleActivityWorkflow.Scenario.allCases)
        func simpleActivity(scenario: SimpleActivityWorkflow.Scenario) async throws {
            let result = try await executeWorkflow(
                SimpleActivityWorkflow.self,
                input: scenario,
                activities: [SimpleActivity()]
            )

            #expect(result == "From activity \(scenario.rawValue)")
        }

        @Test(arguments: [SimpleActivityWorkflow.Scenario.localSymbol, SimpleActivityWorkflow.Scenario.remoteSymbol])
        func interceptsActivity(scenario: SimpleActivityWorkflow.Scenario) async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let counter: Mutex<Int> = .init(0)

                struct Outbound: WorkflowOutboundInterceptor {
                    let interceptor: CountingInterceptor

                    func executeLocalActivity<each Input, Output: Sendable>(
                        input: ScheduleLocalActivityInput<repeat each Input>,
                        next: (
                            ScheduleLocalActivityInput<repeat each Input>
                        ) async throws -> Output
                    ) async throws -> Output {
                        interceptor.counter.withLock { $0 += 1 }
                        return try await next(input)
                    }

                    func executeActivity<each Input, Output: Sendable>(
                        input: ScheduleActivityInput<repeat each Input>,
                        next: (ScheduleActivityInput<repeat each Input>) async throws -> Output
                    ) async throws -> Output {
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
                SimpleActivityWorkflow.self,
                input: scenario,
                activities: [SimpleActivity()],
                interceptors: [interceptor]
            )

            #expect(interceptor.counter.withLock { $0 } == 1)
        }

        struct InfiniteActivity: ActivityDefinition {
            static let name: String? = "InfiniteActivity"

            func run(input: Void) async throws {
                ActivityExecutionContext.current?.heartbeat(details: "Heartbeat")

                while true {
                    try Task.checkCancellation()
                    try await Task.sleep(for: .seconds(1))
                    ActivityExecutionContext.current?.heartbeat(details: "Heartbeat")
                }
            }
        }

        @Workflow
        final class SelfCancellingActivityWorkflow {
            enum Scenario: Codable {
                case preCancel(Int)
                case postCancel(Int)

                var cancellationType: ActivityOptions.CancellationType {
                    switch self {
                    case .preCancel(let raw):
                        .init(rawValue: raw)!
                    case .postCancel(let raw):
                        .init(rawValue: raw)!
                    }
                }
            }

            func run(input scenario: Scenario) async throws {
                try await withThrowingTaskGroup(of: Void.self) { taskGroup in
                    if case .preCancel = scenario {
                        taskGroup.cancelAll()
                    }

                    taskGroup.addTask {
                        var activityOptions = ActivityOptions(scheduleToCloseTimeout: .seconds(100))
                        activityOptions.heartbeatTimeout = .seconds(10)
                        activityOptions.cancellationType = scenario.cancellationType
                        let error = try await #require(throws: Error.self) {
                            try await Workflow.executeActivity(
                                InfiniteActivity.self,
                                options: activityOptions,
                                input: ()
                            )
                        }
                        #expect(error is ActivityError || error is CanceledError)
                    }

                    if case .postCancel = scenario {
                        try await Workflow.sleep(for: .seconds(1))
                        taskGroup.cancelAll()
                    }
                }
            }
        }

        @Test(
            arguments: [
                SelfCancellingActivityWorkflow.Scenario.preCancel(ActivityOptions.CancellationType.tryCancel.rawValue),
                SelfCancellingActivityWorkflow.Scenario.postCancel(ActivityOptions.CancellationType.tryCancel.rawValue),
                SelfCancellingActivityWorkflow.Scenario.preCancel(ActivityOptions.CancellationType.waitCancellationCompleted.rawValue),
                SelfCancellingActivityWorkflow.Scenario.postCancel(ActivityOptions.CancellationType.waitCancellationCompleted.rawValue),
                SelfCancellingActivityWorkflow.Scenario.preCancel(ActivityOptions.CancellationType.abandon.rawValue),
                SelfCancellingActivityWorkflow.Scenario.postCancel(ActivityOptions.CancellationType.abandon.rawValue),
            ]
        )
        func receivesActivityCancellation(
            scenario: SelfCancellingActivityWorkflow.Scenario
        ) async throws {
            try await executeWorkflow(
                SelfCancellingActivityWorkflow.self,
                input: scenario,
                workflowRetryPolicy: .init(maximumAttempts: 1),
                activities: [InfiniteActivity()],
            )
        }
    }
}

extension ActivityOptions.CancellationType: RawRepresentable {
    public var rawValue: Int {
        switch self {
        case .tryCancel:
            return 0
        case .waitCancellationCompleted:
            return 1
        case .abandon:
            return 2
        case .DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM:
            fatalError("Unknown activity cancellation type")
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .tryCancel
        case 1:
            self = .waitCancellationCompleted
        case 2:
            self = .abandon
        default:
            return nil
        }
    }
}
