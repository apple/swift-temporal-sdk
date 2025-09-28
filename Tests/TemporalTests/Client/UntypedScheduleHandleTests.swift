//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Foundation
import Synchronization
import Temporal
import Testing

import struct GRPCCore.RPCError

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct UntypedScheduleHandleTests {
        @Workflow
        final class HelloInputScheduleWorkflow {
            func run(input: String) async -> String {
                input
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func createSchedule() async throws {
            let interceptor = InterceptedOperationsTests.ScheduleCountingInterceptor()
            let expectedOutput = "hello"

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloInputScheduleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.createSchedule(
                    schedule: Schedule(
                        action: .startWorkflow(
                            .init(
                                workflowName: "\(HelloInputScheduleWorkflow.self)",
                                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                                input: expectedOutput
                            )
                        ),
                        specification: .init()
                    ),
                    options: .init(triggerImmediately: true),  // Triggers schedule immediately
                )

                try await Task.sleep(for: .seconds(1))  // Schedule should trigger immediately, but Temporal may delay under heavy parallel load

                // Fetch workflow ID of immediately scheduled workflow
                let workflowId = try await handle.describe(inputType: String.self).info.recentActions.first?.action.workflowId
                guard let workflowId else {
                    Issue.record("Couldn't get workflow ID for scheduled workflow.")
                    return
                }

                try #expect(await client.interceptedService.workflowResult(id: workflowId, resultTypes: String.self) == expectedOutput)

                try await handle.delete()

                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .createSchedule),
                        .init(2, kind: .describeSchedule),
                        .init(3, kind: .deleteSchedule),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func backfillSchedule() async throws {
            let interceptor = InterceptedOperationsTests.ScheduleCountingInterceptor()
            // Intervals align to the epoch boundary, so trim off seconds
            let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970 / 60) * 60)

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloInputScheduleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.createSchedule(
                    schedule: Schedule(
                        action: .startWorkflow(
                            .init(
                                workflowName: "\(HelloInputScheduleWorkflow.self)",
                                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                                input: ""
                            )
                        ),
                        specification: .init(
                            intervals: [.init(every: .seconds(60))]
                        ),
                        state: .init(paused: true)
                    ),
                    options: .init(
                        backfills: [
                            .init(
                                startAt: now.addingTimeInterval(-10 * 60 - 1),
                                endAt: now.addingTimeInterval(-9 * 60),
                                overlap: .allowAll
                            )
                        ]
                    )
                )

                try #expect(await handle.describe(inputType: String.self).info.numActions == 2)

                try await handle.backfill(
                    backfills: [
                        // Half-open: [-4m, -2m)
                        .init(
                            startAt: now.addingTimeInterval(-4 * 60),
                            endAt: now.addingTimeInterval(-2 * 60 - 1),  // make end exclusive
                            overlap: .allowAll
                        ),
                        // [-2m, 0]
                        .init(
                            startAt: now.addingTimeInterval(-2 * 60),
                            endAt: now,
                            overlap: .allowAll
                        ),
                    ]
                )

                let numActions = try await handle.describe(inputType: String.self).info.numActions
                // Servers < 1.24 this is 6, servers >= 1.24 this is 7
                #expect(numActions == 6 || numActions == 7)

                try await handle.delete()

                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .createSchedule),
                        .init(2, kind: .describeSchedule),
                        .init(3, kind: .backfillSchedule),
                        .init(4, kind: .describeSchedule),
                        .init(5, kind: .deleteSchedule),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func triggerSchedule() async throws {
            let interceptor = InterceptedOperationsTests.ScheduleCountingInterceptor()

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloInputScheduleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.createSchedule(
                    schedule: Schedule(
                        action: .startWorkflow(
                            .init(
                                workflowName: "\(HelloInputScheduleWorkflow.self)",
                                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                                input: ""
                            )
                        ),
                        specification: .init()
                    )
                )

                #expect(try await handle.describe(inputType: String.self).info.numActions == 0)

                // Trigger invocation of schedule
                try await handle.trigger()

                #expect(try await handle.describe(inputType: String.self).info.numActions == 1)

                try await handle.delete()

                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .createSchedule),
                        .init(2, kind: .describeSchedule),
                        .init(3, kind: .triggerSchedule),
                        .init(4, kind: .describeSchedule),
                        .init(5, kind: .deleteSchedule),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func updateSchedule() async throws {
            let interceptor = InterceptedOperationsTests.ScheduleCountingInterceptor()

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloInputScheduleWorkflow.self]
            ) { taskQueue, client in
                let timeout: Duration = .seconds(7 * 60)

                let handle = try await client.createSchedule(
                    schedule: Schedule(
                        action: .startWorkflow(
                            .init(
                                workflowName: "\(HelloInputScheduleWorkflow.self)",
                                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                                input: ""
                            )
                        ),
                        specification: .init()
                    )
                )

                // Update to just change the schedule workflow's task timeout
                try await handle.update(inputType: String.self) { description in
                    var description = description
                    guard case var .startWorkflow(options) = description.schedule.action else {
                        Issue.record("Schedule Action type not supported")
                        return nil
                    }

                    options.options.executionTimeOut = timeout
                    description.schedule.action = .startWorkflow(options)

                    return .init(schedule: description.schedule)
                }

                let description = try await handle.describe(inputType: String.self)
                guard case let .startWorkflow(options) = description.schedule.action else {
                    Issue.record("Schedule Action type not supported")
                    return
                }
                #expect(options.options.executionTimeOut == timeout)

                try await handle.delete()

                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .createSchedule),
                        .init(2, kind: .updateSchedule),
                        .init(3, kind: .describeSchedule),
                        .init(4, kind: .deleteSchedule),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func pauseSchedule() async throws {
            let interceptor = InterceptedOperationsTests.ScheduleCountingInterceptor()

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloInputScheduleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.createSchedule(
                    schedule: Schedule(
                        action: .startWorkflow(
                            .init(
                                workflowName: "\(HelloInputScheduleWorkflow.self)",
                                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                                input: ""
                            )
                        ),
                        specification: .init(),
                        state: .init(paused: true)
                    )
                )

                // Confirm already paused schedule
                #expect(try await handle.describe(inputType: String.self).schedule.state.paused == true)

                // Pause and confirm still paused
                try await handle.pause()
                let descriptionPaused = try await handle.describe(inputType: String.self)
                #expect(descriptionPaused.schedule.state.paused == true)
                #expect(descriptionPaused.schedule.state.note == "Paused via swift-temporal-sdk")

                // Unpause
                try await handle.unpause()
                let descriptionUnpaused = try await handle.describe(inputType: String.self)
                #expect(descriptionUnpaused.schedule.state.paused == false)
                #expect(descriptionUnpaused.schedule.state.note == "Unpaused via swift-temporal-sdk")

                try await handle.delete()

                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .createSchedule),
                        .init(2, kind: .describeSchedule),
                        .init(3, kind: .pauseSchedule),
                        .init(4, kind: .describeSchedule),
                        .init(5, kind: .unpauseSchedule),
                        .init(6, kind: .describeSchedule),
                        .init(7, kind: .deleteSchedule),
                    ]
                )
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func deleteSchedule() async throws {
            let interceptor = InterceptedOperationsTests.ScheduleCountingInterceptor()

            return try await withTestWorkerAndClient(
                namespace: "default",
                taskQueue: "tq-\(UUID().uuidString)",
                workerBuildID: "",
                clientInterceptors: [interceptor],
                workflows: [HelloInputScheduleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.createSchedule(
                    schedule: Schedule(
                        action: .startWorkflow(
                            .init(
                                workflowName: "\(HelloInputScheduleWorkflow.self)",
                                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                                input: ""
                            )
                        ),
                        specification: .init(),
                        state: .init(paused: true)
                    )
                )

                let getSchedule = try await handle.describe(inputType: String.self)
                guard case .startWorkflow = getSchedule.schedule.action else {
                    Issue.record("Unexpected schedule action type")
                    return
                }

                #expect(getSchedule.info.createdAt > Date().addingTimeInterval(-5) && getSchedule.info.createdAt < Date())

                try await handle.delete()

                let error = await #expect(throws: RPCError.self, "Deleted schedule should not be able to be retrieved") {
                    _ = try await handle.describe(inputType: String.self)
                }

                if let error {
                    #expect(error.code == .notFound)
                    #expect(error.message == "schedule not found")
                } else {
                    Issue.record("No error was thrown upon fetching a deleted schedule")
                }

                #expect(
                    interceptor.events.withLock { $0 } == [
                        .init(1, kind: .createSchedule),
                        .init(2, kind: .describeSchedule),
                        .init(3, kind: .deleteSchedule),
                        .init(4, kind: .describeSchedule),
                    ]
                )
            }
        }
    }
}
