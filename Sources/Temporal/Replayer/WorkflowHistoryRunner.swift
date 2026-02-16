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

import Logging
internal import SwiftProtobuf

import struct Foundation.Data

/// Internal runner for workflow history replay.
package final class WorkflowHistoryRunner: Sendable {
    /// The bridge replayer instance.
    private let bridgeReplayer: BridgeReplayer

    /// The configuration for the replayer.
    private let configuration: WorkflowReplayer.Configuration

    /// The runtime used for the replayer.
    private let runtime: BridgeRuntime

    init(configuration: WorkflowReplayer.Configuration) throws {
        self.configuration = configuration
        self.runtime = try BridgeRuntime()
        self.bridgeReplayer = try BridgeReplayer(
            runtime: self.runtime,
            namespace: configuration.namespace,
            taskQueue: configuration.taskQueue
        )
    }

    /// Replays a single workflow history..
    func replayWorkflow(
        history: WorkflowHistory,
        throwOnReplayFailure: Bool
    ) async throws -> WorkflowReplayResult {
        // Serialize the history to protobuf bytes
        let historyData = try Api.History.V1.History
            .with { $0.events = history.events }
            .serializedData()

        var logger = self.configuration.logger
        logger[metadataKey: LoggingKeys.workflowID] = "\(history.id)"

        // Create a result box to capture the replay result
        let resultBox = ReplayResultBox()

        // Create the replay bridge worker
        let replayBridgeWorker = ReplayBridgeWorker(
            bridgeReplayer: self.bridgeReplayer,
            resultBox: resultBox,
            history: history,
            throwOnReplayFailure: throwOnReplayFailure
        )

        // Create the workflow worker with replay bridge
        let workflowWorker = try WorkflowWorker(
            worker: replayBridgeWorker,
            taskQueue: self.configuration.taskQueue,
            namespace: self.configuration.namespace,
            dataConverter: self.configuration.dataConverter,
            workflows: self.configuration.workflows,
            interceptors: self.configuration.interceptors,
            logger: logger
        )

        // Run replay following the pattern from TemporalWorker
        let result = try await self.runReplayWorker(
            replayBridgeWorker: replayBridgeWorker,
            workflowWorker: workflowWorker,
            resultBox: resultBox,
            history: history,
            historyData: historyData
        )

        guard let failure = result.replayFailure, throwOnReplayFailure else {
            return result
        }
        throw failure
    }

    /// Runs the replay worker with proper cancellation handling.
    private func runReplayWorker(
        replayBridgeWorker: ReplayBridgeWorker,
        workflowWorker: WorkflowWorker<ReplayBridgeWorker>,
        resultBox: ReplayResultBox,
        history: WorkflowHistory,
        historyData: Data
    ) async throws -> WorkflowReplayResult {
        await withTaskCancellationHandler {
            // Block cancellation from propagating inwards, similar to TemporalWorker
            await Task {
                await withTaskGroup(of: Void.self) { group in
                    // Start the worker running in the background
                    group.addTask {
                        do {
                            self.configuration.logger.debug("Starting replay workflow worker")
                            try await workflowWorker.run()
                        } catch {
                            // Worker encountered an error - this triggers shutdown
                            self.configuration.logger.debug(
                                "Replay worker encountered error",
                                metadata: [
                                    LoggingKeys.errorType: "\(type(of: error))",
                                    LoggingKeys.errorMessage: "\(error)",
                                ]
                            )
                        }
                    }

                    // Push the history and wait for RemoveFromCache
                    let result = await withCheckedContinuation { continuation in
                        // Store the continuation in the result box
                        resultBox.setContinuation(continuation)

                        // Push the history to the replayer
                        do {
                            try self.bridgeReplayer.pushHistory(
                                workflowID: history.id,
                                history: historyData
                            )
                        } catch {
                            fatalError("Failed to push history to replayer")
                        }
                    }

                    // Got the result from replay completion
                    // Now initiate shutdown and clean up
                    self.configuration.logger.debug("Replay complete, initiating shutdown")
                    replayBridgeWorker.initiateShutdown()

                    // Cancel remaining tasks
                    group.cancelAll()

                    // Wait for worker to finish cleaning up
                    _ = await group.next()
                    return result
                }
            }.value
        } onCancel: {
            // Handle cancellation by initiating shutdown
            self.configuration.logger.debug("Replay cancelled, initiating shutdown")
            replayBridgeWorker.initiateShutdown()
        }
    }
}

/// A box for capturing the replay result and managing the continuation.
private final class ReplayResultBox: @unchecked Sendable {
    private var continuation: CheckedContinuation<WorkflowReplayResult, Never>?
    private var history: WorkflowHistory?
    private var throwOnReplayFailure: Bool = false

    func setContinuation(_ continuation: CheckedContinuation<WorkflowReplayResult, Never>) {
        self.continuation = continuation
    }

    func setHistory(_ history: WorkflowHistory, throwOnReplayFailure: Bool) {
        self.history = history
        self.throwOnReplayFailure = throwOnReplayFailure
    }

    func resumeWithResult(failure: (any Error)?) {
        guard let continuation = self.continuation,
            let history = self.history
        else {
            return
        }

        self.continuation = nil

        let result = WorkflowReplayResult(history: history, replayFailure: failure)
        continuation.resume(returning: result)
    }
}

/// A bridge worker implementation for replay that wraps the BridgeReplayer.
package final class ReplayBridgeWorker: BridgeWorkerProtocol {
    private let bridgeReplayer: BridgeReplayer
    private let resultBox: ReplayResultBox
    private let history: WorkflowHistory
    private let throwOnReplayFailure: Bool

    fileprivate init(
        bridgeReplayer: BridgeReplayer,
        resultBox: ReplayResultBox,
        history: WorkflowHistory,
        throwOnReplayFailure: Bool
    ) {
        self.bridgeReplayer = bridgeReplayer
        self.resultBox = resultBox
        self.history = history
        self.throwOnReplayFailure = throwOnReplayFailure

        // Store history in result box for later use
        resultBox.setHistory(history, throwOnReplayFailure: throwOnReplayFailure)
    }

    package init(
        client: borrowing BridgeClient,
        configuration: TemporalWorker.Configuration,
        hasActivities: Bool,
        hasWorkflows: Bool
    ) throws {
        fatalError("ReplayBridgeWorker should not be created with BridgeClient")
    }

    package func initiateShutdown() {
        bridgeReplayer.initiateShutdown()
    }

    package func finalizeShutdown() async throws {
        try await bridgeReplayer.finalizeShutdown()
    }

    package func pollWorkflowActivation() async throws -> Coresdk.WorkflowActivation.WorkflowActivation {
        let activation = try await bridgeReplayer.pollWorkflowActivation()

        // Check for RemoveFromCache and capture the eviction reason
        for job in activation.jobs {
            if case .removeFromCache(let removeFromCache) = job.variant {
                // Capture any failure from the eviction reason
                let failure = self.failureFromEvictionReason(
                    reason: removeFromCache.reason,
                    message: removeFromCache.message
                )

                // Resume the continuation with the result
                self.resultBox.resumeWithResult(failure: failure)
            }
        }

        return activation
    }

    package func completeWorkflowActivation(
        completion: Coresdk.WorkflowCompletion.WorkflowActivationCompletion
    ) async throws {
        try await bridgeReplayer.completeWorkflowActivation(completion: completion)
    }

    package func pollActivityTask() async throws -> Coresdk.ActivityTask.ActivityTask {
        throw InvalidOperationError(message: "Activities are not supported during replay")
    }

    package func completeActivityTask(_ completion: Coresdk.ActivityTaskCompletion) async throws {
        throw InvalidOperationError(message: "Activities are not supported during replay")
    }

    package func recordActivityHeartbeat(_ heartbeat: Coresdk.ActivityHeartbeat) throws {
        throw InvalidOperationError(message: "Activities are not supported during replay")
    }

    /// Converts an eviction reason to an appropriate error.
    private func failureFromEvictionReason(
        reason: Coresdk.WorkflowActivation.RemoveFromCache.EvictionReason,
        message: String
    ) -> (any Error)? {
        switch reason {
        case .nondeterminism:
            return WorkflowNondeterminismError(message: message)
        case .cacheFull, .langRequested, .workflowExecutionEnding:
            // Normal completion - no failure
            return nil
        case .langFail, .fatal, .unhandledCommand:
            return InvalidOperationError(message: "\(reason): \(message)")
        case .unspecified, .cacheMiss, .taskNotFound, .paginationOrHistoryFetch:
            // Unexpected reasons - treat as errors
            return InvalidOperationError(message: "\(reason): \(message)")
        case .UNRECOGNIZED(let code):
            return InvalidOperationError(message: "Unrecognized eviction reason (\(code)): \(message)")
        }
    }
}
