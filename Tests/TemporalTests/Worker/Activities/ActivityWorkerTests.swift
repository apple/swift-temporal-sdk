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
import Logging
import Synchronization
import Temporal
import Testing

private final class MockBridgeWorker: BridgeWorkerProtocol {
    private let activityTaskStream: AsyncThrowingStream<Coresdk_ActivityTask_ActivityTask, any Error>
    let activityTaskContinuation: AsyncThrowingStream<Coresdk_ActivityTask_ActivityTask, any Error>.Continuation
    let activityTaskCompletionStream: AsyncThrowingStream<Coresdk_ActivityTaskCompletion, any Error>
    let heartbeatStream: AsyncStream<Coresdk_ActivityHeartbeat>
    private let heartbeatContinuation: AsyncStream<Coresdk_ActivityHeartbeat>.Continuation
    private let activityTaskCompletionContinuation: AsyncThrowingStream<Coresdk_ActivityTaskCompletion, any Error>.Continuation

    init() {
        (self.activityTaskStream, self.activityTaskContinuation) = AsyncThrowingStream<Coresdk_ActivityTask_ActivityTask, any Error>
            .makeStream()
        (self.activityTaskCompletionStream, self.activityTaskCompletionContinuation) = AsyncThrowingStream<Coresdk_ActivityTaskCompletion, any Error>
            .makeStream()
        (self.heartbeatStream, self.heartbeatContinuation) = AsyncStream<Coresdk_ActivityHeartbeat>
            .makeStream()
    }

    init(
        client: borrowing Temporal.BridgeClient,
        configuration: Temporal.TemporalWorker.Configuration
    ) throws {
        fatalError()
    }

    deinit {}

    func initiateShutdown() {}

    func finalizeShutdown() async throws {}

    func pollWorkflowActivation() async throws -> Coresdk_WorkflowActivation_WorkflowActivation {
        fatalError()
    }

    func completeWorkflowActivation(
        completion: Coresdk_WorkflowCompletion_WorkflowActivationCompletion
    ) async throws {
        fatalError()
    }

    func pollActivityTask() async throws -> Coresdk_ActivityTask_ActivityTask {
        var iterator = self.activityTaskStream.makeAsyncIterator()
        if let task = try await iterator.next() {
            return task
        }
        throw CancellationError()
    }

    func completeActivityTask(_ completion: Coresdk_ActivityTaskCompletion) async throws {
        self.activityTaskCompletionContinuation.yield(completion)
    }

    func recordActivityHeartbeat(_ heartbeat: Coresdk_ActivityHeartbeat) throws {
        self.heartbeatContinuation.yield(heartbeat)
    }
}

private struct VoidActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void

    static let name: String? = "VoidActivity"

    func run(input: Void) async throws {}
}

private struct DataActivity: ActivityDefinition {
    typealias Input = Data
    typealias Output = Data

    static let name: String? = "DataActivity"

    func run(input: Data) async throws -> Data {
        Data(input.reversed())
    }
}

private struct SleepActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void

    static let name: String? = "SleepActivity"

    func run(input: Void) async throws {
        try await Task.sleep(for: .seconds(10_000_000))
    }
}

private struct ThrowingActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void

    static let name: String? = "ThrowingActivity"

    let error: any Error

    func run(input: Void) async throws {
        throw self.error
    }
}

private struct ExecutionContextActivity: ActivityDefinition {
    struct ExecutionContext: Codable, Hashable {
        let activityID: String
        let activityType: String
        let attempt: Int
        let currentAttemptScheduled: Date
        let heartbeatTimeout: Duration?
        let isLocal: Bool
        let scheduleToCloseTimeout: Duration?
        let scheduledTime: Date
        let startToCloseTimeout: Duration?
        let startedTime: Date
        let taskQueue: String
        let taskToken: [UInt8]
        let workflowID: String
        let workflowNamespace: String
        let workflowRunId: String
        let workflowType: String

        init(
            activityID: String,
            activityType: String,
            attempt: Int,
            currentAttemptScheduled: Date,
            heartbeatTimeout: Duration? = nil,
            isLocal: Bool,
            scheduleToCloseTimeout: Duration? = nil,
            scheduledTime: Date,
            startToCloseTimeout: Duration? = nil,
            startedTime: Date,
            taskQueue: String,
            taskToken: ActivityTaskToken,
            workflowID: String,
            workflowNamespace: String,
            workflowRunId: String,
            workflowType: String
        ) {
            self.activityID = activityID
            self.activityType = activityType
            self.attempt = attempt
            self.currentAttemptScheduled = currentAttemptScheduled
            self.heartbeatTimeout = heartbeatTimeout
            self.isLocal = isLocal
            self.scheduleToCloseTimeout = scheduleToCloseTimeout
            self.scheduledTime = scheduledTime
            self.startToCloseTimeout = startToCloseTimeout
            self.startedTime = startedTime
            self.taskQueue = taskQueue
            self.taskToken = taskToken.bytes
            self.workflowID = workflowID
            self.workflowNamespace = workflowNamespace
            self.workflowRunId = workflowRunId
            self.workflowType = workflowType
        }

        init(activityExecutionContext: ActivityExecutionContext) {
            self.activityID = activityExecutionContext.info.activityID
            self.activityType = activityExecutionContext.info.activityType
            self.attempt = activityExecutionContext.info.attempt
            self.currentAttemptScheduled = activityExecutionContext.info.currentAttemptScheduled
            self.heartbeatTimeout = activityExecutionContext.info.heartbeatTimeout
            self.isLocal = activityExecutionContext.info.isLocal
            self.scheduleToCloseTimeout = activityExecutionContext.info.scheduleToCloseTimeout
            self.scheduledTime = activityExecutionContext.info.scheduledTime
            self.startToCloseTimeout = activityExecutionContext.info.startToCloseTimeout
            self.startedTime = activityExecutionContext.info.startedTime
            self.taskQueue = activityExecutionContext.info.taskQueue
            self.taskToken = activityExecutionContext.info.taskToken.bytes
            self.workflowID = activityExecutionContext.info.workflowID
            self.workflowNamespace = activityExecutionContext.info.workflowNamespace
            self.workflowRunId = activityExecutionContext.info.workflowRunID
            self.workflowType = activityExecutionContext.info.workflowType
        }
    }
    typealias Input = Void
    typealias Output = ExecutionContext

    static let name: String? = "ExecutionContextActivity"

    func run(input: Void) async throws -> ExecutionContext {
        .init(activityExecutionContext: ActivityExecutionContext.current!)
    }
}

private struct HeartbeatAcivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void

    static let name: String? = "HeartbeatAcivity"

    func run(input: Void) async throws {
        ActivityExecutionContext.current?.heartbeat(details: 1, "Foo", [UInt8]([1, 2, 3]))

        try await Task.sleep(for: .seconds(1))
    }
}

private struct BadHeartbeatAcivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void

    static let name: String? = "BadHeartbeatAcivity"

    func run(input: Void) async throws {
        struct RandomType {}
        ActivityExecutionContext.current?.heartbeat(details: RandomType())

        try await Task.sleep(for: .seconds(10))
    }
}

private struct ReadingHeartbeatAcivity: ActivityDefinition {
    struct HeartbeatDetails: Codable, Hashable {
        var string: String
        var data: Data
    }
    typealias Input = Void
    typealias Output = HeartbeatDetails

    static let name: String? = "ReadingHeartbeatAcivity"

    func run(input: Void) async throws -> HeartbeatDetails {
        let (string, data) = try await ActivityExecutionContext.current!.info.heartbeatDetails(
            as: String.self,
            Data.self
        )

        return .init(string: string, data: data)
    }
}

private final class ActivityHeaderToInputInterceptor: WorkerInterceptor {
    struct Inbound: ActivityInboundInterceptor {
        func executeActivity<Activity>(
            input: ExecuteActivityInput<Activity>,
            next: (ExecuteActivityInput<Activity>) async throws -> Activity.Output
        ) async throws -> Activity.Output {
            guard Activity.Input.self == [String: String].self else {
                return try await next(input)
            }

            var input = input
            var newInput = [String: String]()
            for (key, value) in input.headers {
                newInput[key] = try await DataConverter.default.convertPayload(value, as: String.self)
            }
            input.input = newInput as! Activity.Input
            return try await next(input)
        }
    }
    func makeActivityInboundInterceptor() -> Inbound? {
        Inbound()
    }
}

@Suite()
struct ActivityWorkerTests {
    private let bridgeWorker = MockBridgeWorker()
    private let activityWorker: ActivityWorker<MockBridgeWorker>

    init(activities: [any ActivityDefinition] = [], dataConverter: DataConverter = .default, interceptors: [any WorkerInterceptor] = []) {
        self.activityWorker = .init(
            worker: self.bridgeWorker,
            activities: activities,
            taskQueue: "test-queue",
            dataConverter: dataConverter,
            interceptors: interceptors,
            logger: .init(label: "TestLogger")
        )
    }

    @Test
    func unknownActivity() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.activityWorker.run()
            }

            self.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "UnkownActivity"
                }
            )

            var activityTaskCompletionIterator = self.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.failed.failure.message = "No activity found with name UnkownActivity. Supported types: []"
                $0.result.failed.failure.source = "SwiftSDK"
                $0.result.failed.failure.applicationFailureInfo.type = "ApplicationFailureType"
                $0.result.failed.failure.applicationFailureInfo.nonRetryable = true
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func voidActivity() async throws {
        let test = ActivityWorkerTests(activities: [VoidActivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "VoidActivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.completed.result = .init()
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func dataActivity() async throws {
        let test = ActivityWorkerTests(activities: [DataActivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "DataActivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                    $0.start.input = [
                        .with {
                            $0.data = Data([1, 2, 3])
                            $0.metadata = ["encoding": Data("binary/plain".utf8)]
                        }
                    ]
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.completed.result = .with {
                    $0.data = Data([3, 2, 1])
                    $0.metadata = ["encoding": Data("binary/plain".utf8)]
                }
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func cancelActivity() async throws {
        let test = ActivityWorkerTests(activities: [SleepActivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "SleepActivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                }
            )

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.cancel.reason = .init()
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.cancelled.failure.message = "Activity cancelled"
                $0.result.cancelled.failure.source = "swift-temporal-sdk"
                $0.result.cancelled.failure.stackTrace = ""
                $0.result.cancelled.failure.encodedAttributes = .init()
                $0.result.cancelled.failure.canceledFailureInfo.details = .init()
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func throwingActivity() async throws {
        let error = ApplicationError(
            message: "CustomMessage",
            stackTrace: "CustomStackTrace"
        )
        let test = ActivityWorkerTests(activities: [ThrowingActivity(error: error)])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "ThrowingActivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.failed.failure.message = "CustomMessage"
                $0.result.failed.failure.source = "swift-temporal-sdk"
                $0.result.failed.failure.stackTrace = "CustomStackTrace"
                $0.result.failed.failure.encodedAttributes = .init()
                $0.result.failed.failure.applicationFailureInfo = .init()
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func activityWithHeader() async throws {
        struct DictionaryActivity: ActivityDefinition {
            func run(input: [String: String]) async throws -> [String: String] {
                input
            }
        }

        let payloadCodec = Base64PayloadCodec()
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: payloadCodec
        )
        let test = ActivityWorkerTests(
            activities: [DictionaryActivity()],
            dataConverter: dataConverter,
            interceptors: [ActivityHeaderToInputInterceptor()]
        )

        let originalInput = try await dataConverter.convertValue(["wrong": "wrong"])
        let testValue = try await dataConverter.convertValue("value")
        let expectedOutput = try await dataConverter.convertValue(["key": "value"])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "DictionaryActivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                    $0.start.headerFields = [
                        "key": .init(temporalPayload: testValue)
                    ]
                    $0.start.input = [
                        .init(temporalPayload: originalInput)
                    ]
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.completed.result = .init(temporalPayload: expectedOutput)
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func activityThrowingCancellation() async throws {
        let error = CancellationError()
        let test = ActivityWorkerTests(activities: [ThrowingActivity(error: error)])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "ThrowingActivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.failed.failure.message = "CancellationError()"
                $0.result.failed.failure.source = "swift-temporal-sdk"
                $0.result.failed.failure.stackTrace = ""
                $0.result.failed.failure.encodedAttributes = .init()
                $0.result.failed.failure.applicationFailureInfo.type = "CancellationError"
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func activityExecutionContext() async throws {
        let test = ActivityWorkerTests(activities: [ExecutionContextActivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            let currentAttemptScheduledTime = Date(timeIntervalSince1970: 1_737_302_400)
            let scheduledTime = Date(timeIntervalSince1970: 1_737_298_800)
            let startedTime = Date(timeIntervalSince1970: 1_737_300_600)

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "ExecutionContextActivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.currentAttemptScheduledTime = .init(date: currentAttemptScheduledTime)
                    $0.start.heartbeatTimeout = .init(rounding: .seconds(60))
                    $0.start.isLocal = false
                    $0.start.scheduleToCloseTimeout = .init(rounding: .seconds(120))
                    $0.start.scheduledTime = .init(date: scheduledTime)
                    $0.start.startToCloseTimeout = .init(rounding: .seconds(30))
                    $0.start.startedTime = .init(date: startedTime)
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowNamespace = "WorkflowNamespace"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                    $0.start.input = [
                        .with {
                            $0.data = Data([1, 2, 3])
                            $0.metadata = ["encoding": Data("binary/plain".utf8)]
                        }
                    ]
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedExecutionContext = ExecutionContextActivity.ExecutionContext(
                activityID: "ActivityID1",
                activityType: "ExecutionContextActivity",
                attempt: 1,
                currentAttemptScheduled: currentAttemptScheduledTime,
                heartbeatTimeout: .seconds(60),
                isLocal: false,
                scheduleToCloseTimeout: .seconds(120),
                scheduledTime: scheduledTime,
                startToCloseTimeout: .seconds(30),
                startedTime: startedTime,
                taskQueue: "test-queue",
                taskToken: .init(bytes: [1]),
                workflowID: "WorkflowID1",
                workflowNamespace: "WorkflowNamespace",
                workflowRunId: "RunID",
                workflowType: "WorkflowType"
            )
            #expect(completion!.result.completed.result.metadata == ["encoding": Data("json/plain".utf8)])
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .iso8601
            let decodedExecutionContext = try jsonDecoder.decode(
                ExecutionContextActivity.ExecutionContext.self,
                from: completion!.result.completed.result.data
            )
            #expect(expectedExecutionContext == decodedExecutionContext)
            group.cancelAll()
        }
    }

    @Test
    static func heartbeat() async throws {
        let test = ActivityWorkerTests(activities: [HeartbeatAcivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "HeartbeatAcivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                }
            )

            var heartbeatIterator = test.bridgeWorker.heartbeatStream.makeAsyncIterator()
            let heartbeat = await heartbeatIterator.next()
            let expectedHeartbeat = Coresdk_ActivityHeartbeat.with {
                $0.taskToken = Data([1])
                $0.details = [
                    .with {
                        $0.data = Data(#"1"#.utf8)
                        $0.metadata = ["encoding": Data("json/plain".utf8)]
                    },
                    .with {
                        $0.data = Data(#""Foo""#.utf8)
                        $0.metadata = ["encoding": Data("json/plain".utf8)]
                    },
                    .with {
                        $0.data = Data([1, 2, 3])
                        $0.metadata = ["encoding": Data("binary/plain".utf8)]
                    },
                ]
            }
            #expect(heartbeat == expectedHeartbeat)

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.completed.result = .init()
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func badHeartbeat() async throws {
        let test = ActivityWorkerTests(activities: [BadHeartbeatAcivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "BadHeartbeatAcivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk_ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.failed.failure.message = "EncodingError()"
                $0.result.failed.failure.source = "swift-temporal-sdk"
                $0.result.failed.failure.stackTrace = ""
                $0.result.failed.failure.encodedAttributes = .init()
                $0.result.failed.failure.applicationFailureInfo.type = "EncodingError"
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func readingHeartbeat() async throws {
        let test = ActivityWorkerTests(activities: [ReadingHeartbeatAcivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "ReadingHeartbeatAcivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                    $0.start.heartbeatDetails = [
                        .with {
                            $0.data = Data(#""Foo""#.utf8)
                            $0.metadata = ["encoding": Data("json/plain".utf8)]
                        },
                        .with {
                            $0.data = Data([1, 2, 3])
                            $0.metadata = ["encoding": Data("binary/plain".utf8)]
                        },
                    ]
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            #expect(completion?.taskToken == Data([1]))
            let jsonDecoder = JSONDecoder()
            let expectedHeartbeatDetails = ReadingHeartbeatAcivity.HeartbeatDetails(
                string: "Foo",
                data: Data([1, 2, 3])
            )
            let heartbeatDetails = try jsonDecoder.decode(
                ReadingHeartbeatAcivity.HeartbeatDetails.self,
                from: completion!.result.completed.result.data
            )
            #expect(heartbeatDetails == expectedHeartbeatDetails)
            group.cancelAll()
        }
    }
}
