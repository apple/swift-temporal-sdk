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
package import Logging
import SwiftProtobuf
import Synchronization

import struct Foundation.Data

package protocol ActivityWorkerProtocol: Sendable {
    associatedtype BridgeWorker: BridgeWorkerProtocol
    init(
        worker: BridgeWorker,
        configuration: TemporalWorker.Configuration,
        activities: [any ActivityDefinition],
        logger: Logger
    ) throws
    func run() async throws
}

/// Internal component responsible for managing and executing activity tasks within a Temporal worker.
///
/// The `ActivityWorker` handles the complete lifecycle of activity execution including polling for tasks
/// from the Temporal server, dispatching activities to their implementations, managing heartbeats, and
/// handling cancellation and completion. It works in conjunction with the registered activity definitions to
/// process activity tasks.
///
/// ## Key Responsibilities
///
/// - Polls for activity tasks from the Temporal server
/// - Dispatches tasks to registered activity implementations
/// - Manages activity lifecycle including cancellation and completion
/// - Handles heartbeat processing for long-running activities
/// - Provides execution context to running activities
///
/// ## Internal Architecture
///
/// The worker maintains a registry of activities by name and uses a thread-safe state container to track
/// running activities. Each activity execution runs in its own task with support for cancellation and heartbeat
/// processing.
package final class ActivityWorker<BridgeWorker: BridgeWorkerProtocol>: ActivityWorkerProtocol {
    /// State container for tracking currently executing activities.
    private struct State {
        /// A dictionary of currently executing activities indexed by their unique task tokens.
        ///
        /// This allows the worker to manage concurrent activity executions and handle cancellation
        /// requests for specific activities.
        var runningActivities: [ActivityTaskToken: RunningActivity] = [:]
    }
    /// The bridge worker instance that provides communication with the Temporal Core SDK.
    private let worker: BridgeWorker
    /// A dictionary of registered activity implementations indexed by their type names.
    ///
    /// Activities are stored with their registered names as keys. A `nil` key indicates support for dynamic
    /// activities (not yet implemented).
    // TODO: Add support for dynamic activities.
    private let activities: [String?: any ActivityDefinition]
    /// The name of the task queue from which this worker polls for activity tasks.
    private let taskQueue: String
    /// The data converter used for serializing activity inputs and deserializing outputs and errors.
    private let dataConverter: DataConverter
    /// The logger instance used for diagnostic and debugging output during activity execution.
    private let logger: Logger
    /// The collection of worker interceptors.
    private let interceptors: [any WorkerInterceptor]

    /// Thread-safe container for managing the worker's internal state.
    private let state: Mutex<State>

    /// The interceptor implementation chain for processing activity inbound calls.
    private let implementation: Implementation

    /// Creates an activity worker with the specified configuration and dependencies.
    ///
    /// The worker registers all provided activities by name and sets up the necessary infrastructure for
    /// polling and executing activity tasks.
    ///
    /// - Parameters:
    ///   - worker: The bridge worker providing communication with the Temporal Core SDK.
    ///   - activities: An array of activity definitions to register for execution.
    ///   - taskQueue: The name of the task queue to poll for activity tasks.
    ///   - dataConverter: The data converter for handling payload serialization and deserialization.
    ///   - interceptors: Worker interceptors for customizing activity execution behavior. Defaults to empty array.
    ///   - logger: The logger instance for diagnostic and debugging output.
    package init(
        worker: BridgeWorker,
        activities: [any ActivityDefinition],
        taskQueue: String,
        dataConverter: DataConverter,
        interceptors: [any WorkerInterceptor] = [],
        logger: Logger
    ) throws {
        self.worker = worker
        self.activities = try Dictionary(
            activities.map { (Self.getName(for: $0), $0) },
            uniquingKeysWith: { first, second in
                let activityName = Self.getName(for: first) ?? "unknown"
                logger.info("Duplicate activity registration", metadata: [LoggingKeys.activityName: "\(activityName)"])
                throw TemporalSDKError("Duplicate activity: \(activityName)")
            }
        )
        self.taskQueue = taskQueue
        self.dataConverter = dataConverter
        self.logger = logger
        self.state = .init(.init(runningActivities: [:]))
        self.interceptors = interceptors
        self.implementation = .init(interceptors: interceptors.compactMap { $0.makeActivityInboundInterceptor() })
    }

    package convenience init(
        worker: BridgeWorker,
        configuration: TemporalWorker.Configuration,
        activities: [any ActivityDefinition],
        logger: Logger
    ) throws {
        try self.init(
            worker: worker,
            activities: activities,
            taskQueue: configuration.taskQueue,
            dataConverter: configuration.dataConverter,
            interceptors: configuration.interceptors,
            logger: logger
        )
    }

    /// Starts the activity worker's main execution loop to poll for and process activity tasks.
    ///
    /// This method begins continuous polling for activity tasks from the Temporal server. The worker
    /// processes each task by either starting a new activity execution or handling cancellation requests.
    /// The method runs indefinitely until the task is cancelled or a critical error occurs.
    ///
    /// ## Execution Flow
    ///
    /// 1. Continuously polls for activity tasks from the server
    /// 2. Dispatches start tasks to registered activity implementations
    /// 3. Handles cancellation requests for running activities
    /// 4. Manages activity lifecycle including heartbeats and completion
    ///
    /// - Throws: Network errors, task execution errors, or cancellation errors that terminate the polling
    /// loop.
    package func run() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            // TODO: Check for task cancellation here
            while true {
                self.logger.debug("Polling next activity task")
                try await self.pollNextActivityTask(
                    taskGroup: &group,
                    logger: self.logger
                )
                self.logger.debug("Finished activity task")
            }
        }
    }

    /// Polls for and processes the next activity task from the Temporal server.
    ///
    /// This method handles both activity start and cancellation tasks. For start tasks, it verifies the activity
    /// is registered and initiates execution. For cancellation tasks, it finds the running activity and
    /// triggers cancellation.
    ///
    /// - Parameters:
    ///   - taskGroup: The task group for managing concurrent activity executions.
    ///   - logger: The logger instance for diagnostic output.
    private func pollNextActivityTask(
        taskGroup: inout ThrowingTaskGroup<Void, any Error>,
        logger: Logger
    ) async throws {
        var logger = self.logger

        let activityTask = try await self.worker.pollActivityTask()
        let activityTaskToken = ActivityTaskToken(bytes: Array(activityTask.taskToken))
        logger[metadataKey: LoggingKeys.taskToken] = "\(activityTask.taskToken.base64EncodedString())"

        switch activityTask.variant {
        case .start(let activityTaskStart):
            logger.debug("Starting activity")

            guard let activity = self.activities[activityTaskStart.activityType] else {
                logger.debug("No activity registered for type")
                try await self.sendActivityCompletionForUnknownActivity(
                    taskToken: activityTask.taskToken,
                    activityType: activityTaskStart.activityType,
                    logger: logger
                )
                return
            }

            try await self.startActivity(
                activity: activity,
                activityTaskStart: activityTaskStart,
                taskToken: activityTaskToken,
                taskGroup: &taskGroup,
                logger: logger
            )

        case .cancel(let activityTaskCancel):
            logger.debug(
                "Cancelling activity",
                metadata: [
                    LoggingKeys.activityCancellationReason: "\(activityTaskCancel.reason)"
                ]
            )

            guard let runningActivity = self.state.withLock({ $0.runningActivities.removeValue(forKey: activityTaskToken) }) else {
                logger.debug("No running activity found")
                return
            }

            runningActivity.cancel(reason: .init(temporalAPICancelReason: activityTaskCancel.reason))

        default:
            // TODO: Revisit throwing here
            logger.error("Received an unknown activity task \(String(describing: activityTask.variant))")
            throw TemporalSDKError("Unknown message type: \(String(describing: activityTask.variant))")
        }
    }

    /// Initiates execution of a specific activity within a managed task environment.
    ///
    /// This method sets up the complete execution environment for an activity including execution context,
    /// heartbeat processing, and cancellation handling. The activity runs in its own task group with proper
    /// isolation and lifecycle management.
    ///
    /// - Parameters:
    ///   - activity: The activity definition to execute.
    ///   - activityTaskStart: The task start information from the server.
    ///   - taskToken: The unique token identifying this activity execution.
    ///   - taskGroup: The task group for managing the activity execution task.
    ///   - logger: The logger instance for diagnostic output.
    private func startActivity<A: ActivityDefinition>(
        activity: A,
        activityTaskStart: Coresdk.ActivityTask.Start,
        taskToken: ActivityTaskToken,
        taskGroup: inout ThrowingTaskGroup<Void, any Error>,
        logger: Logger
    ) async throws {
        let runningActivity = RunningActivity()
        self.state.withLock { $0.runningActivities[taskToken] = runningActivity }

        taskGroup.addTask {
            // To allow us to manually cancel the activity we are putting it in a separate
            // task group. In this task group we have one child task that is to manually
            // trigger cancellation.
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    await runningActivity.waitForCancellation(logger: logger)
                    self.state.withLock {
                        let _ = $0.runningActivities.removeValue(forKey: taskToken)
                    }
                }

                group.addTask {
                    try await withThrowingTaskGroup(of: Coresdk.ActivityTaskCompletion?.self) { activityTaskGroup in
                        // Only the latest heartbeat matters so we don't have to buffer more than 1 ever. Each
                        // heartbeat adds an additional overhead since we need to convert the details so let's
                        // avoid doing unnecessary work.
                        let (heartbeatStream, heartbeatContinuation) = AsyncStream<[any Sendable]>.makeStream(
                            bufferingPolicy: .bufferingNewest(1)
                        )

                        let executionContext = ActivityExecutionContext(
                            activityTaskStart: activityTaskStart,
                            taskQueue: self.taskQueue,
                            taskToken: taskToken,
                            dataConverter: self.dataConverter,
                            logger: logger,
                            outboundInterceptors: self.interceptors.compactMap { $0.makeActivityOutboundInterceptor() },
                            heartbeatContinuation: heartbeatContinuation,
                            lookupCancellationReason: { runningActivity.cancellationReason }
                        )

                        activityTaskGroup.addTask {
                            for await heartbeat in heartbeatStream {
                                await self.heartbeat(taskToken: taskToken, heartbeatDetails: heartbeat)
                            }

                            return nil
                        }

                        activityTaskGroup.addTask {
                            try await ActivityExecutionContext.$taskLocal.withValue(executionContext) {
                                // Notify the heartbeating task that activity execution won't generate more heartbeats, when the activity finishes
                                defer {
                                    heartbeatContinuation.finish()
                                }

                                let resultPayload: Api.Common.V1.Payload
                                do {
                                    let input: A.Input
                                    if A.Input.self == Void.self {
                                        input = () as! A.Input
                                    } else {
                                        input = try await self.dataConverter.convertPayloads(
                                            activityTaskStart.input,
                                            as: (A.Input).self
                                        )
                                    }

                                    let headers: [String: Api.Common.V1.Payload]
                                    if let payloadCodec = self.dataConverter.payloadCodec {
                                        headers = try await .init(
                                            uniqueKeysWithValues: activityTaskStart.headerFields.async.map {
                                                ($0, try await payloadCodec.decode(payload: $1))
                                            }
                                        )
                                    } else {
                                        headers = activityTaskStart.headerFields
                                    }

                                    // TODO: We want to have a task local logger here
                                    let output = try await self.implementation.run(
                                        activity,
                                        input: .init(
                                            definition: activity,
                                            headers: headers,
                                            input: input
                                        )
                                    )
                                    resultPayload = try await self.dataConverter.convertValue(output)
                                } catch is CompleteAsyncError {  // Async completion of the activity
                                    logger.debug("Completing activity asynchronously", metadata: [LoggingKeys.activityName: "\(A.name)"])
                                    return .init(taskToken: Data(taskToken.bytes), result: .willCompleteAsync)
                                } catch {
                                    let errorToConvert =
                                        switch runningActivity.cancellationReason {
                                        case .goneFromServer, .serverRequest, .timeout, .workerShutdown:
                                            CanceledError(message: "Activity cancelled")
                                        case .heartbeatRecordFailure(let error):
                                            error
                                        default:
                                            error
                                        }

                                    let failure = await self.dataConverter.convertError(errorToConvert)
                                    return .with {
                                        $0.taskToken = Data(taskToken.bytes)
                                        if let failureInfo = failure.failureInfo,
                                            case .canceledFailureInfo = failureInfo
                                        {
                                            $0.result.cancelled.failure = failure
                                        } else {
                                            $0.result.failed.failure = failure
                                        }
                                    }
                                }

                                // TODO: What should we do if sending the completion fails?
                                try await self.sendActivityCompletion(
                                    completion: .init(
                                        taskToken: Data(taskToken.bytes),
                                        result: .completed(result: resultPayload)
                                    ),
                                    logger: logger
                                )

                                return nil
                            }
                        }

                        guard let completion = try await activityTaskGroup.reduce(nil, { return $0 ?? $1 }) else {
                            return
                        }

                        try await self.sendActivityCompletion(completion: completion, logger: logger)
                    }
                }

                try await group.next()
                group.cancelAll()
            }
        }
    }

    /// Sends an activity completion response for an unregistered activity type.
    ///
    /// When the worker receives a task for an activity type that isn't registered, this method sends a failure
    /// response indicating the activity type is unknown.
    ///
    /// - Parameters:
    ///   - taskToken: The unique token for the activity task.
    ///   - activityType: The name of the unregistered activity type.
    ///   - logger: The logger instance for diagnostic output.
    private func sendActivityCompletionForUnknownActivity(
        taskToken: Data,
        activityType: String,
        logger: Logger
    ) async throws {
        let completion = Coresdk.ActivityTaskCompletion.with {
            $0.taskToken = taskToken
            $0.result.failed.failure.message = "No activity found with name \(activityType). Supported types: \(self.activities.keys)"
            $0.result.failed.failure.source = "SwiftSDK"
            // TODO: Figure out what stack trace APIs to use.
            //            $0.result.failed.failure.stackTrace = Thread.callStackSymbols.joined(separator: "\n")
            $0.result.failed.failure.applicationFailureInfo.type = "ApplicationFailureType"
            $0.result.failed.failure.applicationFailureInfo.nonRetryable = true
            // TODO: encode real details
            // TODO: pass through data converter / payload converter
            // $0.result.failed.failure.applicationFailureInfo.details = "details payload"
        }

        try await self.sendActivityCompletion(completion: completion, logger: logger)
    }

    /// Sends an activity completion message to the Temporal server.
    ///
    /// This method delivers the final result of activity execution, whether successful or failed, back to the
    /// Temporal server for workflow processing.
    ///
    /// - Parameters:
    ///   - completion: The completion message containing results or failure information.
    ///   - logger: The logger instance for diagnostic output.
    private func sendActivityCompletion(
        completion: Coresdk.ActivityTaskCompletion,
        logger: Logger
    ) async throws {
        logger.debug("Sending activity completion \(completion)")

        try await self.worker.completeActivityTask(completion)
    }

    /// Records a heartbeat for the specified activity with optional progress details.
    ///
    /// This method processes heartbeat data by converting details to payloads and sending them to the
    /// server. If conversion fails, the activity is cancelled with a heartbeat failure reason.
    ///
    /// - Parameters:
    ///   - taskToken: The unique token identifying the activity.
    ///   - heartbeatDetails: Progress information to include with the heartbeat.
    func heartbeat(
        taskToken: ActivityTaskToken,
        heartbeatDetails: [any Sendable]
    ) async {
        var payloads = [Api.Common.V1.Payload]()
        payloads.reserveCapacity(heartbeatDetails.count)

        do {
            for heartbeatDetail in heartbeatDetails {
                let payload = try await self.dataConverter.convertValue(heartbeatDetail)
                payloads.append(payload)
            }
        } catch {
            logger.debug("Failed to convert heartbeat details. Cancelling activity")

            guard let runningActivity = self.state.withLock({ $0.runningActivities.removeValue(forKey: taskToken) }) else {
                logger.debug("No running activity found")
                return
            }

            runningActivity.cancel(reason: .heartbeatRecordFailure(error))
        }

        // This really cannot fail. The protobuf is encoded and decoded across the interop
        // boundary. If this fails we have a big problem.
        do {
            try self.worker.recordActivityHeartbeat(
                .with {
                    $0.taskToken = Data(taskToken.bytes)
                    $0.details = payloads
                }
            )
        } catch {
            fatalError("Failed to pass heartbeat to bridge")
        }
    }

    /// Extracts the activity name from an activity definition for registration purposes.
    ///
    /// - Parameter activity: The activity definition to get the name from.
    /// - Returns: The activity name used for server registration and routing.
    private static func getName<Activity: ActivityDefinition>(
        for activity: Activity
    ) -> String? {
        return Activity.name
    }
}

extension ActivityWorker {
    /// Interceptor implementation that chains activity inbound interceptors for customized execution behavior.
    struct Implementation: InterceptorImplementation {
        /// The chain of activity inbound interceptors to apply during execution.
        let interceptors: [any ActivityInboundInterceptor]
    }
}

extension ActivityWorker.Implementation {
    /// Executes an activity through the interceptor chain with the provided input.
    ///
    /// This method applies all registered inbound interceptors before executing the activity's run method.
    ///
    /// - Parameters:
    ///   - activity: The activity definition to execute.
    ///   - input: The execution input containing activity parameters and context.
    /// - Returns: The output produced by the activity execution.
    /// - Throws: Any error from the activity execution or interceptor processing.
    func run<Activity: ActivityDefinition>(
        _ activity: Activity,
        input: ExecuteActivityInput<Activity>
    ) async throws -> Activity.Output {
        try await intercept((any ActivityInboundInterceptor).executeActivity, input: input) { input in
            try await activity.run(input: input.input)
        }
    }
}
