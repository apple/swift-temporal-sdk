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

import SwiftProtobuf

#if canImport(FoundationEssentials)
import struct FoundationEssentials.Data
#else
import struct Foundation.Data
#endif

extension TemporalClient.WorkflowService {
    /// Issue a heartbeat for a running activity task.
    ///
    /// Sends an activity heartbeat to the Temporal server to indicate that the activity is still
    /// in progress and to optionally include progress details. Heartbeats are used to:
    /// - Prevent the server from considering the activity as timed out.
    /// - Communicate progress information back to the workflow.
    /// - Detect cancellation requests.
    ///
    /// If the server has requested that this activity be cancelled, this method throws
    /// ``AsyncActivityCanceledError``. Call ``AsyncActivityHandle/reportCancellation(options:)``
    /// for proper cancellation reporting.
    ///
    /// - Parameters:
    ///   - activity: The activity reference, either by `workflowID`/`runID`/`activityID` or task token.
    ///   - options: Heartbeat options, including optional `details` and `callOptions`.
    ///   - dataConverter: Optional override for payload conversion.
    /// - Throws: ``AsyncActivityCanceledError`` if the server requested cancellation,
    ///           or any error that occurs during the heartbeat call.
    public func heartbeatAsyncActivity(
        activity: AsyncActivityHandle.Reference,
        options: AsyncActivityHeartbeatOptions?,
        dataConverter: DataConverter? = nil
    ) async throws {
        let dataConverter = dataConverter ?? self.configuration.dataConverter

        var detailsPayloads: Api.Common.V1.Payloads?
        if let items = options?.details, !items.isEmpty {
            var payloads: [Api.Common.V1.Payload] = []
            for item in items {
                payloads.append(try await dataConverter.convertValue(item))
            }

            detailsPayloads = .with {
                $0.payloads = payloads
            }
        }

        switch activity {
        case .id(let workflowID, let runID, let activityID):
            let response: Api.Workflowservice.V1.RecordActivityTaskHeartbeatByIdResponse =
                try await self.client.unary(
                    method: Api.Workflowservice.V1.WorkflowService.Method.RecordActivityTaskHeartbeatById.descriptor,
                    request: Api.Workflowservice.V1.WorkflowService.Method.RecordActivityTaskHeartbeatById.Input.with {
                        $0.namespace = self.configuration.namespace
                        $0.identity = self.configuration.identity
                        $0.workflowID = workflowID
                        if let runID { $0.runID = runID }
                        $0.activityID = activityID
                        if let detailsPayloads { $0.details = detailsPayloads }
                    },
                    callOptions: options?.callOptions
                )
            if response.cancelRequested {
                throw AsyncActivityCanceledError()
            }

        case .taskToken(let token):
            let response: Api.Workflowservice.V1.RecordActivityTaskHeartbeatResponse =
                try await self.client.unary(
                    method: Api.Workflowservice.V1.WorkflowService.Method.RecordActivityTaskHeartbeat.descriptor,
                    request: Api.Workflowservice.V1.WorkflowService.Method.RecordActivityTaskHeartbeat.Input.with {
                        $0.namespace = self.configuration.namespace
                        $0.identity = self.configuration.identity
                        $0.taskToken = Data(token.bytes)
                        if let detailsPayloads { $0.details = detailsPayloads }
                    },
                    callOptions: options?.callOptions
                )
            if response.cancelRequested {
                throw AsyncActivityCanceledError()
            }
        }
    }

    /// Complete a running activity task successfully.
    ///
    /// Sends a "completed" response to the Temporal server for the given activity task,
    /// including the result payload (if any). After this call succeeds, the activity is
    /// considered finished and cannot be heartbeated, failed, or cancelled.
    ///
    /// - Parameters:
    ///   - activity: The activity reference, either by `workflowID`/`runID`/`activityID` or task token.
    ///   - result: The result value to return to the workflow, or `nil` for no result.
    ///   - options: Completion options, including optional `callOptions`.
    ///   - dataConverter: Optional override for payload conversion.
    public func completeAsyncActivity<Result: Sendable>(
        activity: AsyncActivityHandle.Reference,
        result: Result?,
        options: AsyncActivityCompleteOptions?,
        dataConverter: DataConverter? = nil
    ) async throws {
        let dataConverter = dataConverter ?? self.configuration.dataConverter

        let payload = try await dataConverter.convertValue(result)
        let resultPayloads = Api.Common.V1.Payloads.with {
            $0.payloads = [payload]
        }

        switch activity {
        case .id(let workflowID, let runID, let activityID):
            _ = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskCompletedById.descriptor,
                request: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskCompletedById.Input.with {
                    $0.namespace = self.configuration.namespace
                    $0.identity = self.configuration.identity
                    $0.workflowID = workflowID
                    if let runID { $0.runID = runID }
                    $0.activityID = activityID
                    $0.result = resultPayloads
                },
                callOptions: options?.callOptions
            )

        case .taskToken(let token):
            _ = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskCompleted.descriptor,
                request: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskCompleted.Input.with {
                    $0.namespace = self.configuration.namespace
                    $0.identity = self.configuration.identity
                    $0.taskToken = Data(token.bytes)
                    $0.result = resultPayloads
                },
                callOptions: options?.callOptions
            )
        }
    }

    /// Fail a running activity task.
    ///
    /// Sends a "failed" response to the Temporal server for the given activity task,
    /// including the converted failure details. Optional last-heartbeat details may also be sent
    /// to the server for diagnostic or recovery purposes.
    ///
    /// After this call succeeds, the activity is considered finished and cannot be heartbeated,
    /// completed, or cancelled.
    ///
    /// - Parameters:
    ///   - activity: The activity reference, either by `workflowID`/`runID`/`activityID` or task token.
    ///   - error: The error describing the activity failure.
    ///   - options: Fail options, including optional `lastHeartbeatDetails` and `callOptions`.
    ///   - dataConverter: Optional override for payload conversion.
    public func failAsyncActivity(
        activity: AsyncActivityHandle.Reference,
        error: any Error,
        options: AsyncActivityFailOptions?,
        dataConverter: DataConverter? = nil
    ) async throws {
        let dataConverter = dataConverter ?? self.configuration.dataConverter

        let failure = await dataConverter.convertError(error)

        var lastHeartbeatDetails: Api.Common.V1.Payloads?
        if let items = options?.lastHeartbeatDetails, !items.isEmpty {
            let payloads = try await dataConverter.convertValues(items)
            lastHeartbeatDetails = .with {
                $0.payloads = payloads
            }
        }

        switch activity {
        case .id(let workflowID, let runID, let activityID):
            _ = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskFailedById.descriptor,
                request: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskFailedById.Input.with {
                    $0.namespace = self.configuration.namespace
                    $0.identity = self.configuration.identity
                    $0.workflowID = workflowID
                    if let runID { $0.runID = runID }
                    $0.activityID = activityID
                    $0.failure = .init(temporalFailure: failure)
                    if let lastHeartbeatDetails { $0.lastHeartbeatDetails = lastHeartbeatDetails }
                },
                callOptions: options?.callOptions
            )

        case .taskToken(let token):
            _ = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskFailed.descriptor,
                request: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskFailed.Input.with {
                    $0.namespace = self.configuration.namespace
                    $0.identity = self.configuration.identity
                    $0.taskToken = Data(token.bytes)
                    $0.failure = .init(temporalFailure: failure)
                    if let lastHeartbeatDetails { $0.lastHeartbeatDetails = lastHeartbeatDetails }
                },
                callOptions: options?.callOptions
            )
        }
    }

    /// Report a running activity task as cancelled.
    ///
    /// Sends a "cancelled" response to the Temporal server for the given activity task.
    /// Optional details may be provided to give context on the cancellation.
    ///
    /// After this call succeeds, the activity is considered finished and cannot be heartbeated,
    /// completed, or failed.
    ///
    /// - Parameters:
    ///   - activity: The activity reference, either by `workflowID`/`runID`/`activityID` or task token.
    ///   - options: Cancellation options, including optional `details` and `callOptions`.
    ///   - dataConverter: Optional override for payload conversion.
    public func reportCancellationAsyncActivity(
        activity: AsyncActivityHandle.Reference,
        options: AsyncActivityReportCancellationOptions?,
        dataConverter: DataConverter? = nil
    ) async throws {
        let dataConverter = dataConverter ?? self.configuration.dataConverter

        var detailsPayloads: Api.Common.V1.Payloads?
        if let items = options?.details, !items.isEmpty {
            let payloads = try await dataConverter.convertValues(items)
            detailsPayloads = .with {
                $0.payloads = payloads
            }
        }

        switch activity {
        case .id(let workflowID, let runID, let activityID):
            _ = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskCanceledById.descriptor,
                request: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskCanceledById.Input.with {
                    $0.namespace = self.configuration.namespace
                    $0.identity = self.configuration.identity
                    $0.workflowID = workflowID
                    if let runID { $0.runID = runID }
                    $0.activityID = activityID
                    if let detailsPayloads { $0.details = detailsPayloads }
                },
                callOptions: options?.callOptions
            )

        case .taskToken(let token):
            _ = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskCanceled.descriptor,
                request: Api.Workflowservice.V1.WorkflowService.Method.RespondActivityTaskCanceled.Input.with {
                    $0.namespace = self.configuration.namespace
                    $0.identity = self.configuration.identity
                    $0.taskToken = Data(token.bytes)
                    if let detailsPayloads { $0.details = detailsPayloads }
                },
                callOptions: options?.callOptions
            )
        }
    }
}
