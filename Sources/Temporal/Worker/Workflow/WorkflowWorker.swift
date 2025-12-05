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

package import Logging
import SwiftProtobuf

package protocol WorkflowWorkerProtocol: Sendable {
    associatedtype BridgeWorker: BridgeWorkerProtocol
    init(
        worker: BridgeWorker,
        configuration: TemporalWorker.Configuration,
        workflows: [any WorkflowDefinition.Type],
        logger: Logger
    ) throws
    var worker: BridgeWorker { get }
    var interceptors: [any WorkerInterceptor] { get }
    func run() async throws
    func completeWorkflowActivation(
        completion: consuming Coresdk_WorkflowCompletion_WorkflowActivationCompletion
    ) async throws
}

/// A worker responsible for handling workflow activations.
package final class WorkflowWorker<BridgeWorker: BridgeWorkerProtocol>: WorkflowWorkerProtocol {
    /// The bridge worker.
    package let worker: BridgeWorker
    /// The task queue.
    private let taskQueue: String
    /// The namespace.
    private let namespace: String
    /// The data converter.
    private let dataConverter: DataConverter
    /// Workflow definition keyed by their name.
    private let workflows: [String: any WorkflowDefinition.Type]
    /// The logger.
    private let logger: Logger
    /// The worker interceptor factories.
    package let interceptors: [any WorkerInterceptor]

    init(
        worker: BridgeWorker,
        taskQueue: String,
        namespace: String,
        dataConverter: DataConverter,
        workflows: [any WorkflowDefinition.Type],
        interceptors: [any WorkerInterceptor],
        logger: Logger
    ) throws {
        self.worker = worker
        self.taskQueue = taskQueue
        self.namespace = namespace
        self.dataConverter = dataConverter
        self.workflows = try Dictionary(
            workflows.map { ($0.name, $0) },
            uniquingKeysWith: { first, second in
                logger.info("Duplicate workflow registration", metadata: [LoggingKeys.workflowType: "\(first.name)"])
                throw TemporalSDKError("Duplicate workflow: \(first.name)")
            }
        )
        self.interceptors = interceptors
        self.logger = logger
    }

    package convenience init(
        worker: BridgeWorker,
        configuration: TemporalWorker.Configuration,
        workflows: [any WorkflowDefinition.Type],
        logger: Logger
    ) throws {
        try self.init(
            worker: worker,
            taskQueue: configuration.taskQueue,
            namespace: configuration.namespace,
            dataConverter: configuration.dataConverter,
            workflows: workflows,
            interceptors: configuration.interceptors,
            logger: logger
        )
    }

    package func run() async throws {
        // We are using an unstructured task here as a cancellation shield to avoid cancellation of the worker's task
        // to propagate to the workflow instances. The worker itself is listening to cancellation and informs the bridge worker
        // to initiate a shutdown. This will result in all workflow instances to be removed from cache at some point and rescheduled
        // onto another worker. The reason we want to avoid the workflow instances from getting cancelled is that
        // `CancellationError`s result in workflow failures which means those workflows aren't retried.
        try await Task {
            try await withDiscardingTaskGroup(returning: Result<Void, any Error>.self) { group in
                // These are our running workflows.
                var runningWorkflows = [String: AsyncStream<Coresdk_WorkflowActivation_WorkflowActivation>.Continuation]()

                // We don't have to handle cancellation here since the TemporalWorker is handling this
                // for us and telling the bridge worker about it.
                do {
                    while true {
                        self.logger.trace("Polling next workflow activation")
                        // Let's poll the next activation
                        var activation = try await self.worker.pollWorkflowActivation()
                        self.logger.trace(
                            "Polled next workflow activation",
                            metadata: [
                                LoggingKeys.workflowRunID: "\(activation.runID)"
                            ]
                        )

                        if let payloadCodec = dataConverter.payloadCodec {
                            try await activation.decode(payloadCodec: payloadCodec)
                            self.logger.trace(
                                "Decoded next workflow activation",
                                metadata: [
                                    LoggingKeys.workflowRunID: "\(activation.runID)"
                                ]
                            )
                        }

                        // Get the activations continuation for the workflow instance
                        // each workflow instance is running in a separate child task.
                        guard
                            let continuation = try await self.workflowInstanceActivationContinuation(
                                for: activation,
                                runningWorkflows: &runningWorkflows,
                                taskGroup: &group
                            )
                        else {
                            continue
                        }

                        // If the activation has only one job and that's remove from cache we need
                        // to finish the continuation right away and remove the workflow from our cache
                        if case .removeFromCache = activation.jobs.first?.variant, activation.jobs.count == 1 {
                            self.logger.debug(
                                "Removing workflow instance from cache",
                                metadata: [
                                    LoggingKeys.workflowRunID: "\(activation.runID)"
                                ]
                            )
                            runningWorkflows.removeValue(forKey: activation.runID)
                            continuation.finish()
                            try await self.worker.completeWorkflowActivation(
                                completion: .with {
                                    $0.runID = activation.runID
                                    $0.successful = .init()
                                }
                            )
                        } else {
                            self.logger.trace(
                                "Yielding activation to existing workflow instance",
                                metadata: [
                                    LoggingKeys.workflowRunID: "\(activation.runID)"
                                ]
                            )
                            // We have at least one job that we need to process that's not a remove from cache
                            continuation.yield(activation)

                            // If our activation contains a remove from cache job
                            // we need to finish the continuation and remove it from our running workflows
                            for job in activation.jobs {
                                switch job.variant {
                                case .removeFromCache:
                                    runningWorkflows.removeValue(forKey: activation.runID)
                                    continuation.finish()
                                    break
                                default:
                                    break
                                }
                            }
                        }
                    }
                } catch {
                    // Something went wrong while processing activations this can
                    // either be a cancellation from the TemporalWorker or
                    // the payload codec failed. In any way, we are toast here.
                    // We can't cancel the task group though since we must ensure that
                    // the workflow instance is the only thing interacting with
                    // the workflow state machine
                    self.logger.debug(
                        "Workflow worker encountered error while processing activations",
                        metadata: [
                            LoggingKeys.error: "\(error)"
                        ]
                    )

                    for continuation in runningWorkflows.values {
                        continuation.finish()
                    }
                    return .failure(error)
                }
                return .success(())
            }.get()
        }.value
    }

    private func workflowInstanceActivationContinuation(
        for activation: Coresdk_WorkflowActivation_WorkflowActivation,
        runningWorkflows: inout [String: AsyncStream<Coresdk_WorkflowActivation_WorkflowActivation>.Continuation],
        taskGroup: inout DiscardingTaskGroup
    ) async throws -> AsyncStream<Coresdk_WorkflowActivation_WorkflowActivation>.Continuation? {
        let runID = activation.runID

        // First we check if we have a running workflow
        if let continuation = runningWorkflows[runID] {
            return continuation
        }

        // If we don't have a running workflow then this must contain an activation
        for case let .initializeWorkflow(initializeWorkflow) in activation.jobs.map({ $0.variant }) {
            let workflowType = initializeWorkflow.workflowType
            guard let workflowType = self.workflows[workflowType] else {
                logger.error("Workflow type not found", metadata: [LoggingKeys.workflowType: "\(workflowType)"])
                try await self.worker.completeWorkflowActivation(
                    completion: .with {
                        $0.runID = runID
                        $0.failed = .with {
                            $0.failure = .with {
                                $0.message = "Workflow \(workflowType) not found"
                            }
                        }
                    }
                )

                return nil
            }

            var logger = self.logger
            logger[metadataKey: LoggingKeys.workflowRunID] = "\(runID)"
            logger[metadataKey: LoggingKeys.workflowType] = "\(workflowType)"

            logger.debug("Creating new workflow instance")

            let workflowInstance = WorkflowInstance(
                workflowWorker: self,
                taskQueue: self.taskQueue,
                namespace: self.namespace,
                payloadConverter: self.dataConverter.payloadConverter,
                failureConverter: self.dataConverter.failureConverter,
                logger: logger
            )
            // Other SDKs keep this without an upper buffer limit as well
            // TODO: Check if we should enforce a buffer size
            let (activationsStream, activationsContinuation) = AsyncStream<Coresdk_WorkflowActivation_WorkflowActivation>.makeStream()
            runningWorkflows[runID] = activationsContinuation
            taskGroup.addTask {
                self.logger.trace("Running workflow instance")
                do {
                    try await workflowInstance.run(
                        workflowType: workflowType,
                        activations: activationsStream
                    )
                    self.logger.trace("Workflow instance finished")
                } catch {
                    // TODO: We should probably log an error here and let it all tear down
                    // since this can only happen if we failed to send a completion to the worker
                    self.logger.error("Workflow instance failed to send a completion")
                }
            }
            return activationsContinuation
        }

        return nil
    }

    package func completeWorkflowActivation(
        completion: consuming Coresdk_WorkflowCompletion_WorkflowActivationCompletion
    ) async throws {
        if let payloadCodec = dataConverter.payloadCodec {
            try await completion.encode(payloadCodec: payloadCodec)
        }
        try await self.worker.completeWorkflowActivation(completion: completion)
    }
}
