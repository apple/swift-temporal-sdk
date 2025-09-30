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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.WorkflowService {
    /// Waits for and retrieves the final result of the workflow execution.
    ///
    /// This method implements long-polling to wait for the workflow to reach a terminal state
    /// and return its final result. It handles various completion scenarios including successful
    /// completion, failures, cancellations, and continue-as-new operations.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow whose history to retrieve.
    ///   - runID: The specific run ID to get history for. If nil, retrieves history for the latest run.
    ///   - followRuns: Whether to automatically follow continue-as-new and retry chains to get the final result.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The final output of the workflow execution.
    /// - Throws: Various workflow-specific errors depending on the terminal state.
    public func result<Output: Sendable>(
        id: String,
        runID: String? = nil,
        followRuns: Bool = true,
        callOptions: CallOptions? = nil
    ) async throws -> Output {
        try await self.result(
            historyRunID: runID,
            followRuns: followRuns,
        ) { historyRunID in
            try await self.fetchWorkflowHistoryEvents(
                id: id,
                runID: historyRunID,
                waitNewEvent: true,
                eventFilterType: .closeEvent,
                skipArchival: true,
                callOptions: callOptions
            )
        }
    }

    /// Retrieves the complete workflow execution history using pagination.
    ///
    /// This method provides comprehensive access to a workflow's execution history, including
    /// all events that occurred during the workflow's lifetime. The history contains detailed
    /// information about workflow state transitions, activity executions, timer events, and
    /// other execution details crucial for monitoring, debugging, and auditing workflows.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow whose history to retrieve.
    ///   - runID: The specific run ID to get history for. If nil, retrieves history for the latest run.
    ///   - waitNewEvent: Whether to use long-polling to wait for new events. If true, waits for new events; if false or nil, returns immediately with available events.
    ///   - eventFilterType: The type of events to filter during retrieval. If nil, retrieves all event types.
    ///   - skipArchival: Whether to skip archived history events for faster retrieval. If true, only returns non-archived events; if nil or false, includes all events.
    ///   - callOptions: Custom call options including timeout settings for the RPC operation.
    /// - Returns: An array of ``HistoryEvent`` objects representing the complete workflow execution history in chronological order.
    /// - Throws: An error if the operation fails.
    public func fetchWorkflowHistoryEvents(
        id: String,
        runID: String? = nil,
        waitNewEvent: Bool? = nil,
        eventFilterType: HistoryEventFilterType? = nil,
        skipArchival: Bool? = nil,
        callOptions: CallOptions? = nil
    ) async throws -> [HistoryEvent] {
        let eventStream = withFlattenedPagination { pageToken in
            let response: Temporal_Api_Workflowservice_V1_GetWorkflowExecutionHistoryResponse = try await self.client.unary(
                method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.GetWorkflowExecutionHistory.descriptor,
                request: Temporal_Api_Workflowservice_V1_GetWorkflowExecutionHistoryRequest.with {
                    $0.namespace = self.configuration.namespace
                    $0.execution = .with {
                        $0.workflowID = id
                        if let runID {
                            $0.runID = runID
                        }
                    }
                    if let waitNewEvent {
                        $0.waitNewEvent = waitNewEvent
                    }
                    if let eventFilterType {
                        $0.historyEventFilterType = .init(eventFilterType)
                    }
                    if let skipArchival {
                        $0.skipArchival = skipArchival
                    }
                    $0.nextPageToken = pageToken
                },
                callOptions: callOptions ?? .userPollRetryOptions  // specifies increased connection timeout
            )
            return (elements: response.history.events, pageToken: response.nextPageToken)
        }
        .map { try HistoryEvent($0) }

        let events = try await Array(eventStream)

        if events.isEmpty {
            throw WorkflowHistoryEmptyError(message: "Unexpected empty workflow history")
        }

        return events
    }

    // Fetch workflow result helper that abstracts the RPC call (RPC either intercepted or not)
    func result<Output: Sendable>(
        historyRunID: String? = nil,
        followRuns: Bool = true,
        fetchWorkflowHistoryEvents: (_ historyRunID: String?) async throws -> [HistoryEvent],
    ) async throws -> Output {
        var historyRunID = historyRunID

        while true {
            let events = try await fetchWorkflowHistoryEvents(historyRunID)

            for event in events {
                switch event.attributes {
                case .workflowExecutionCompleted(let completed):
                    if followRuns, let newExecutionRunID = completed.newExecutionRunID, !newExecutionRunID.isEmpty {
                        historyRunID = newExecutionRunID
                        continue
                    }
                    let payloads = completed.result
                    return try await self.configuration.dataConverter.convertPayloads(
                        payloads,
                        as: Output.self
                    )

                case .workflowExecutionFailed(let failed):
                    if followRuns, let newExecutionRunID = failed.newExecutionRunID, !newExecutionRunID.isEmpty {
                        historyRunID = newExecutionRunID
                        continue
                    }
                    let error = await self.configuration.dataConverter.convertTemporalFailure(failed.failure)
                    throw WorkflowFailedError(cause: error)

                case .workflowExecutionContinuedAsNew(let continuedAsNew):
                    guard !continuedAsNew.newExecutionRunID.isEmpty else {
                        throw InvalidOperationError(message: "Continue as new missing new run ID")
                    }

                    if followRuns {
                        historyRunID = continuedAsNew.newExecutionRunID
                        // We are following the next run now
                        continue
                    }

                    throw WorkflowContinuedAsNewError(newRunID: continuedAsNew.newExecutionRunID)

                case .workflowExecutionTimedOut(let timedOut):
                    if followRuns, let newExecutionRunID = timedOut.newExecutionRunID, !newExecutionRunID.isEmpty {
                        historyRunID = newExecutionRunID
                        continue
                    }

                    throw WorkflowFailedError(
                        cause: TimeoutError(
                            message: "Workflow execution timed out",
                            type: .startToClose
                        )
                    )

                case .workflowExecutionCanceled(let canceled):
                    throw WorkflowFailedError(
                        cause: CanceledError(
                            message: "Workflow execution canceled",
                            details: canceled.details
                        )
                    )

                case .workflowExecutionTerminated(let terminated):
                    throw WorkflowFailedError(
                        cause: TerminatedError(
                            message: "Workflow execution terminated: \(terminated.reason ?? "<none>")",
                            details: terminated.details
                        )
                    )

                default:
                    throw UnknownWorkflowEventError(message: "Unknown CloseEvent type: \(event.eventType)")
                }
            }
        }
    }
}
