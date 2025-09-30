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

import AsyncAlgorithms
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2Posix
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct ScheduleTests {
        @Workflow
        final class HelloWorldScheduleWorkflow {
            func run(input: Void) async -> String {
                "Hello, World!"
            }
        }

        @Workflow
        final class HelloInputScheduleWorkflow {
            func run(input: String) async -> String {
                input
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func workflowScheduleWithoutInput() async throws {
            try await runScheduleTest(
                workflow: HelloWorldScheduleWorkflow.self,
                input: (),
                expectedOutput: "Hello, World!"
            )
        }

        @Test(.timeLimit(.minutes(1)))
        func workflowScheduleWithInput() async throws {
            let input = "Hello, Input!"
            try await runScheduleTest(
                workflow: HelloInputScheduleWorkflow.self,
                input: input,
                expectedOutput: input
            )
        }

        private func runScheduleTest<Workflow: WorkflowDefinition>(
            workflow: Workflow.Type = Workflow.self,
            input: Workflow.Input,
            expectedOutput: Workflow.Output
        ) async throws where Workflow.Output: Equatable {
            let taskQueue = "tq-\(UUID().uuidString)"

            try await scheduleHandle(
                workflowType: workflow,
                schedule: Schedule(
                    action: .startWorkflow(
                        .init(
                            workflowType: workflow,
                            // Workflow ID is NOT taken "as-is" but suffixed with timestamp: https://github.com/temporalio/temporal/issues/4795
                            // That's why we need to fetch the ID of the workflow triggered by the schedule
                            options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                            input: input
                        )
                    ),
                    specification: .init()  // Empty spec as triggering happens immediately because of the `triggerImmediately` flag
                ),
                options: .init(triggerImmediately: true),  // Triggers schedule immediately
                taskQueue: taskQueue
            ) { scheduleHandle in
                try await Task.sleep(for: .seconds(1))  // Schedule should trigger immediately, but Temporal may delay under heavy parallel load

                // Fetch workflow ID of scheduled workflow
                let workflowId = try await scheduleHandle.describe().info.recentActions.first?.action.workflowId
                guard let workflowId else {
                    Issue.record("Couldn't get workflow ID for scheduled workflow.")
                    return
                }

                let workflowHandle = WorkflowHandle<Workflow>(
                    untypedHandle: .init(
                        interceptor: scheduleHandle.untypedHandle.interceptor,
                        id: workflowId
                    )
                )

                // Wait for scheduled workflow to complete
                try #expect(await workflowHandle.result() == expectedOutput)

                try await scheduleHandle.delete()
            }
        }

        @Test
        func backfillSchedule() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"
            // Intervals align to the epoch boundary, so trim off seconds
            let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970 / 60) * 60)

            // Create paused schedule that runs every minute and has two backfills
            try await scheduleHandle(
                workflowType: HelloWorldScheduleWorkflow.self,
                schedule: Schedule(
                    action: .startWorkflow(
                        .init(
                            workflowType: HelloWorldScheduleWorkflow.self,
                            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
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
                ),
                taskQueue: taskQueue
            ) { scheduleHandle in
                try #expect(await scheduleHandle.describe().info.numActions == 2)

                try await scheduleHandle.backfill(
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

                let numActions = try await scheduleHandle.describe().info.numActions
                // Servers < 1.24 this is 6, servers >= 1.24 this is 7
                #expect(numActions == 6 || numActions == 7)

                try await scheduleHandle.delete()
            }
        }

        @Test
        func triggerSchedule() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"

            try await scheduleHandle(
                workflowType: HelloWorldScheduleWorkflow.self,
                schedule: Schedule(
                    action: .startWorkflow(
                        .init(
                            workflowType: HelloWorldScheduleWorkflow.self,
                            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                        )
                    ),
                    specification: .init()
                ),
                taskQueue: taskQueue
            ) { scheduleHandle in
                #expect(try await scheduleHandle.describe().info.numActions == 0)

                // Trigger invocation of schedule
                try await scheduleHandle.trigger()

                #expect(try await scheduleHandle.describe().info.numActions == 1)

                try await scheduleHandle.delete()
            }
        }

        @Test
        func updateSchedule() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"

            try await scheduleHandle(
                workflowType: HelloWorldScheduleWorkflow.self,
                schedule: Schedule(
                    action: .startWorkflow(
                        .init(
                            workflowType: HelloWorldScheduleWorkflow.self,
                            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                        )
                    ),
                    specification: .init()
                ),
                taskQueue: taskQueue
            ) { scheduleHandle in
                let timeout: Duration = .seconds(7 * 60)

                // Update to just change the schedule workflow's task timeout
                try await scheduleHandle.update { description in
                    var description = description
                    guard case var .startWorkflow(options) = description.schedule.action else {
                        Issue.record("Schedule Action type not supported")
                        return nil
                    }

                    options.options.executionTimeOut = timeout
                    description.schedule.action = .startWorkflow(options)

                    return .init(schedule: description.schedule)
                }

                let descriptionFirstUpdate = try await scheduleHandle.describe()
                guard case let .startWorkflow(options) = descriptionFirstUpdate.schedule.action else {
                    Issue.record("Schedule Action type not supported")
                    return
                }
                #expect(options.options.executionTimeOut == timeout)

                // Update but cancel update
                let lastUpdateTime = try #require(descriptionFirstUpdate.info.lastUpdatedAt, "Last updated time must be set")
                try await scheduleHandle.update { _ in nil }  // Empty update
                let descriptionSecondUpdate = try await scheduleHandle.describe()
                #expect(lastUpdateTime == descriptionSecondUpdate.info.lastUpdatedAt)

                // Update to only be a schedule of simple defaults
                try await scheduleHandle.update { _ in
                    .init(
                        schedule: .init(
                            action: .startWorkflow(
                                .init(
                                    workflowType: HelloWorldScheduleWorkflow.self,
                                    options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                                )
                            ),
                            specification: .init(),
                            state: .init(paused: true)
                        )
                    )
                }
                let descriptionThirdUpdate = try await scheduleHandle.describe()
                #expect(lastUpdateTime != descriptionThirdUpdate.info.lastUpdatedAt)

                try await scheduleHandle.delete()
            }
        }

        @Test
        func pauseSchedule() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"

            try await scheduleHandle(
                workflowType: HelloWorldScheduleWorkflow.self,
                schedule: Schedule(
                    action: .startWorkflow(
                        .init(
                            workflowType: HelloWorldScheduleWorkflow.self,
                            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                        )
                    ),
                    specification: .init(),
                    state: .init(paused: true)
                ),
                taskQueue: taskQueue
            ) { scheduleHandle in
                // Confirm already paused schedule
                #expect(try await scheduleHandle.describe().schedule.state.paused == true)

                // Pause and confirm still paused
                try await scheduleHandle.pause()
                let descriptionPaused = try await scheduleHandle.describe()
                #expect(descriptionPaused.schedule.state.paused == true)
                #expect(descriptionPaused.schedule.state.note == "Paused via swift-temporal-sdk")

                // Unpause
                try await scheduleHandle.unpause()
                let descriptionUnpaused = try await scheduleHandle.describe()
                #expect(descriptionUnpaused.schedule.state.paused == false)
                #expect(descriptionUnpaused.schedule.state.note == "Unpaused via swift-temporal-sdk")

                // Pause with custom message
                try await scheduleHandle.pause(note: "Custom pause note")
                let descriptionPausedCustom = try await scheduleHandle.describe()
                #expect(descriptionPausedCustom.schedule.state.paused == true)
                #expect(descriptionPausedCustom.schedule.state.note == "Custom pause note")

                // Unpause with custom message
                try await scheduleHandle.unpause(note: "Custom unpause note")
                let descriptionUnpausedCustom = try await scheduleHandle.describe()
                #expect(descriptionUnpausedCustom.schedule.state.paused == false)
                #expect(descriptionUnpausedCustom.schedule.state.note == "Custom unpause note")

                try await scheduleHandle.delete()
            }
        }

        @Test
        func deleteSchedule() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"

            try await scheduleHandle(
                workflowType: HelloWorldScheduleWorkflow.self,
                schedule: Schedule(
                    action: .startWorkflow(
                        .init(
                            workflowType: HelloWorldScheduleWorkflow.self,
                            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                        )
                    ),
                    specification: .init()
                ),
                taskQueue: taskQueue
            ) { scheduleHandle in
                let getSchedule = try await scheduleHandle.describe()
                guard case .startWorkflow = getSchedule.schedule.action else {
                    Issue.record("Unexpected schedule action type")
                    return
                }

                #expect(getSchedule.info.createdAt > Date().addingTimeInterval(-5) && getSchedule.info.createdAt < Date())

                try await scheduleHandle.delete()

                let error = await #expect(throws: RPCError.self, "Deleted schedule should not be able to be retrieved") {
                    _ = try await scheduleHandle.describe()
                }

                if let error {
                    #expect(error.code == .notFound)
                    #expect(error.message == "schedule not found")
                } else {
                    Issue.record("No error was thrown upon fetching a deleted schedule")
                }
            }
        }

        @Test
        func listSchedules() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"

            try await scheduleHandle(
                workflowType: HelloWorldScheduleWorkflow.self,
                schedule: Schedule(
                    action: .startWorkflow(
                        .init(
                            workflowType: HelloWorldScheduleWorkflow.self,
                            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                        )
                    ),
                    specification: .init()
                ),
                taskQueue: taskQueue
            ) { handle in
                // Sleep gives Temporal enough time to process the schedules, otherwise they're not returned by `listSchedules()`
                try await Task.sleep(for: .seconds(1))

                let listedSchedules =
                    try await handle
                    .untypedHandle
                    .interceptor
                    .workflowService
                    .listSchedules()  // For now, don't filter schedules as we require search attributes

                let schedules: [ScheduleListDescription] = try await Array(listedSchedules)

                // As swift-testing runs tests in parallel, there could be multiple schedules that are listed in the response,
                // therefore we test that at least the schedule created within this test is present and matches the properties
                #expect(schedules.count >= 1)
                if let matchingSchedule = schedules.first(where: { $0.id == handle.id }) {
                    #expect(matchingSchedule.info == .init())
                    #expect(matchingSchedule.schedule?.spec == .init())
                    #expect(matchingSchedule.schedule?.state == .init())
                    #expect(matchingSchedule.schedule?.action.workflow == HelloWorldScheduleWorkflow.name)
                } else {
                    Issue.record("No schedule with ID \(handle.id) found.")
                }

                let testSpec: ScheduleSpecification = .init(
                    calendars: [.init(hour: [.init(value: 10)])],
                    skip: [.init(month: [.init(value: 20)])],
                    startAt: Calendar.current.date(byAdding: .day, value: 2, to: .now)
                )
                let testState: ScheduleState = .init(note: "Test pause note", paused: true)

                try await scheduleHandle(
                    workflowType: HelloWorldScheduleWorkflow.self,
                    schedule: Schedule(
                        action: .startWorkflow(
                            .init(
                                workflowType: HelloWorldScheduleWorkflow.self,
                                options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                            )
                        ),
                        specification: testSpec,
                        state: testState
                    ),
                    taskQueue: taskQueue
                ) { handle in
                    // Sleep gives Temporal enough time to process the schedules, otherwise they're not returned by `listSchedules()`
                    try await Task.sleep(for: .seconds(1))

                    let listedSchedules =
                        try await handle
                        .untypedHandle
                        .interceptor
                        .workflowService
                        .listSchedules()  // For now, don't filter schedules as we require search attributes

                    let schedules: [ScheduleListDescription] = try await Array(listedSchedules)

                    // As swift-testing runs tests in parallel, there could be multiple schedules that are listed in the response,
                    // therefore we test that at least the schedule created within this test is present and matches the properties
                    #expect(schedules.count >= 2)
                    if let matchingSchedule = schedules.first(where: { $0.id == handle.id }) {
                        #expect(matchingSchedule.info?.recentActions == [])
                        #expect(matchingSchedule.info?.nextActionTimes.count == 5)  // Max 5 action times are returned by Temporal

                        let calendar: Calendar = {
                            var calendar = Calendar(identifier: .gregorian)
                            calendar.timeZone = TimeZone(identifier: "UTC")!
                            return calendar
                        }()
                        if let nextActionTimes = matchingSchedule.info?.nextActionTimes {
                            for nextActionTime in nextActionTimes {
                                #expect(
                                    calendar.dateComponents([.hour, .minute, .second], from: nextActionTime)
                                        == DateComponents(hour: 10, minute: 0, second: 0)
                                )
                            }
                        }

                        #expect(matchingSchedule.schedule?.spec == testSpec)
                        #expect(matchingSchedule.schedule?.state.isPaused == testState.paused)
                        #expect(matchingSchedule.schedule?.state.note == testState.note)
                        #expect(matchingSchedule.schedule?.action.workflow == HelloWorldScheduleWorkflow.name)
                    } else {
                        Issue.record("No schedule with ID \(handle.id) found.")
                    }

                    try await handle.delete()
                }

                try await handle.delete()
            }
        }
    }
}
