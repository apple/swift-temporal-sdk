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
import SwiftProtobuf
import Synchronization
import Temporal
import Testing

private final class MockBridgeWorker: BridgeWorkerProtocol {
    private let activityTaskStream: AsyncThrowingStream<Coresdk.ActivityTask.ActivityTask, any Error>
    let activityTaskContinuation: AsyncThrowingStream<Coresdk.ActivityTask.ActivityTask, any Error>.Continuation
    let activityTaskCompletionStream: AsyncThrowingStream<Coresdk.ActivityTaskCompletion, any Error>
    let heartbeatStream: AsyncStream<Coresdk.ActivityHeartbeat>
    private let heartbeatContinuation: AsyncStream<Coresdk.ActivityHeartbeat>.Continuation
    private let activityTaskCompletionContinuation: AsyncThrowingStream<Coresdk.ActivityTaskCompletion, any Error>.Continuation

    init() {
        (self.activityTaskStream, self.activityTaskContinuation) = AsyncThrowingStream<Coresdk.ActivityTask.ActivityTask, any Error>
            .makeStream()
        (self.activityTaskCompletionStream, self.activityTaskCompletionContinuation) = AsyncThrowingStream<Coresdk.ActivityTaskCompletion, any Error>
            .makeStream()
        (self.heartbeatStream, self.heartbeatContinuation) = AsyncStream<Coresdk.ActivityHeartbeat>
            .makeStream()
    }

    init(
        client: borrowing Temporal.BridgeClient,
        configuration: Temporal.TemporalWorker.Configuration,
        hasActivities: Bool,
        hasWorkflows: Bool
    ) throws {
        fatalError()
    }

    deinit {}

    func initiateShutdown() {}

    func finalizeShutdown() async throws {}

    func pollWorkflowActivation() async throws -> Coresdk.WorkflowActivation.WorkflowActivation {
        fatalError()
    }

    func completeWorkflowActivation(
        completion: Coresdk.WorkflowCompletion.WorkflowActivationCompletion
    ) async throws {
        fatalError()
    }

    func pollActivityTask() async throws -> Coresdk.ActivityTask.ActivityTask {
        var iterator = self.activityTaskStream.makeAsyncIterator()
        if let task = try await iterator.next() {
            return task
        }
        throw CancellationError()
    }

    func completeActivityTask(_ completion: Coresdk.ActivityTaskCompletion) async throws {
        self.activityTaskCompletionContinuation.yield(completion)
    }

    func recordActivityHeartbeat(_ heartbeat: Coresdk.ActivityHeartbeat) throws {
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

private struct HeartbeatActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void

    static let name: String? = "HeartbeatAcivity"

    func run(input: Void) async throws {
        ActivityExecutionContext.current?.heartbeat(details: 1, "Foo", [UInt8]([1, 2, 3]))

        try await Task.sleep(for: .seconds(1))
    }
}

private struct TypeErasedHeartbeatActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void

    static let name: String? = "TypeErasedHeartbeatActivity"

    func run(input: Void) async throws {
        // Store the heartbeat detail as a type-erased `any Sendable` value.
        let typeErasedVoid: any Sendable = Void()
        ActivityExecutionContext.current?.heartbeat(details: typeErasedVoid)

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

private struct ReadingHeartbeatActivity: ActivityDefinition {
    struct HeartbeatDetails: Codable, Hashable {
        var string: String
        var data: Data
    }
    typealias Input = Void
    typealias Output = HeartbeatDetails?

    static let name: String? = "ReadingHeartbeatActivity"

    func run(input: Void) async throws -> HeartbeatDetails? {
        guard
            let (string, data) = try await ActivityExecutionContext.current!.info.heartbeatDetails(
                as: String.self,
                Data.self
            )
        else {
            return nil
        }

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

// Test activities with duplicate names for duplicate registration tests
private struct FirstActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void
    static var name: String { "DuplicateName" }
    func run(input: Void) async throws {}
}

private struct SecondActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void
    static var name: String { "DuplicateName" }  // Same name as FirstActivity
    func run(input: Void) async throws {}
}

private struct UniqueActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void
    static var name: String { "UniqueName" }
    func run(input: Void) async throws {}
}

@Suite()
struct ActivityWorkerTests {
    private let bridgeWorker = MockBridgeWorker()
    private let activityWorker: ActivityWorker<MockBridgeWorker>

    init(activities: [any ActivityDefinition] = [], dataConverter: DataConverter = .default, interceptors: [any WorkerInterceptor] = []) {
        do {
            self.activityWorker = try .init(
                worker: self.bridgeWorker,
                activities: activities,
                taskQueue: "test-queue",
                dataConverter: dataConverter,
                interceptors: interceptors,
                logger: .init(label: "TestLogger")
            )
        } catch {
            fatalError("Failed to initialize ActivityWorker: \(error)")
        }
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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
        let test = ActivityWorkerTests(activities: [HeartbeatActivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "HeartbeatActivity"
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
            let expectedHeartbeat = Coresdk.ActivityHeartbeat.with {
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
                $0.taskToken = Data([1])
                $0.result.completed.result = .init()
            }
            #expect(completion == expectedCompletion)
            group.cancelAll()
        }
    }

    @Test
    static func typeErasedHeartbeat() async throws {
        let test = ActivityWorkerTests(activities: [TypeErasedHeartbeatActivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "TypeErasedHeartbeatActivity"
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
            let expectedHeartbeat = Coresdk.ActivityHeartbeat.with {
                $0.taskToken = Data([1])
                $0.details = [.init()]
            }
            #expect(heartbeat == expectedHeartbeat)

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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
            let expectedCompletion = Coresdk.ActivityTaskCompletion.with {
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

    @Test("Read Heartbeat Details", arguments: [true, false])
    static func readingHeartbeat(heartbeatDetailsAvailable: Bool) async throws {
        let test = ActivityWorkerTests(activities: [ReadingHeartbeatActivity()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await test.activityWorker.run()
            }

            test.bridgeWorker.activityTaskContinuation.yield(
                .with {
                    $0.taskToken = Data([1])
                    $0.start.activityType = "ReadingHeartbeatActivity"
                    $0.start.activityID = "ActivityID1"
                    $0.start.attempt = 1
                    $0.start.workflowType = "WorkflowType"
                    $0.start.workflowExecution = .with {
                        $0.runID = "RunID"
                        $0.workflowID = "WorkflowID1"
                    }
                    if heartbeatDetailsAvailable {
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
                }
            )

            var activityTaskCompletionIterator = test.bridgeWorker.activityTaskCompletionStream.makeAsyncIterator()
            let completion = try await activityTaskCompletionIterator.next()
            #expect(completion?.taskToken == Data([1]))
            let jsonDecoder = JSONDecoder()
            let heartbeatDetails = try jsonDecoder.decode(
                (ReadingHeartbeatActivity.HeartbeatDetails?).self,
                from: completion!.result.completed.result.data
            )

            if heartbeatDetailsAvailable {
                let expectedHeartbeatDetails = ReadingHeartbeatActivity.HeartbeatDetails(
                    string: "Foo",
                    data: Data([1, 2, 3])
                )
                #expect(heartbeatDetails == expectedHeartbeatDetails)
            } else {
                #expect(heartbeatDetails == nil)
            }
            group.cancelAll()
        }
    }

    @Test
    func duplicateActivityRegistrationThrowsError() async throws {
        // Test that duplicate activity registrations throw TemporalSDKError
        let logHandler = InMemoryLogHandler()
        logHandler.logLevel = .trace  // Capture all logs including info
        let logger = Logger(label: "TestActivityWorker") { _ in logHandler }

        let bridgeWorker = MockBridgeWorker()

        // Expect error to be thrown when creating ActivityWorker with duplicate activity names
        #expect(throws: (any Error).self) {
            let _ = try ActivityWorker(
                worker: bridgeWorker,
                activities: [FirstActivity(), SecondActivity(), UniqueActivity()],
                taskQueue: "test-queue",
                dataConverter: .default,
                interceptors: [],
                logger: logger
            )
        }

        // Verify the info log was recorded before the error was thrown
        try logHandler.entries.withLock { entries in
            let infoEntries = entries.filter { $0.level == .info }
            #expect(infoEntries.count == 1)

            let logEntry = try #require(infoEntries.first)
            #expect(logEntry.message == "Duplicate activity registration")

            // Verify structured metadata using activity name key
            let activityName = try #require(logEntry.metadata?["temporal.activity.name"])
            #expect(activityName == "DuplicateName")
        }
    }

    @Test
    func noDuplicateActivitiesNoError() async throws {
        // Test that no duplicates means no errors and no logs
        let logHandler = InMemoryLogHandler()
        let logger = Logger(label: "TestActivityWorker") { _ in logHandler }

        let bridgeWorker = MockBridgeWorker()

        // Should not throw when creating ActivityWorker with unique activity names
        let _ = try ActivityWorker(
            worker: bridgeWorker,
            activities: [UniqueActivity()],
            taskQueue: "test-queue",
            dataConverter: .default,
            interceptors: [],
            logger: logger
        )

        // Verify no logs were recorded
        logHandler.entries.withLock { entries in
            #expect(entries.isEmpty)
        }
    }
}
