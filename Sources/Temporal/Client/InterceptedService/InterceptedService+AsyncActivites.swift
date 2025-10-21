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

extension TemporalClient.InterceptedService {
    /// Issue a heartbeat for a running activity task.
    ///
    /// Routes a heartbeat through the outbound interceptor chain and into the underlying
    /// workflow service. Use this to indicate that the activity is still in progress and
    /// optionally attach progress details. The interceptor may observe, modify, or reject
    /// the call before it reaches the service layer.
    ///
    /// If the server has requested that this activity be cancelled, the operation throws
    /// ``AsyncActivityCanceledError``. Call ``AsyncActivityHandle/reportCancellation(options:)``
    /// afterward to acknowledge cancellation.
    ///
    /// - Parameters:
    ///   - activity: The activity reference, either by `workflowID` and `activityID` (and optional `runID`) or by task token.
    ///   - options: Heartbeat options, including optional `details` and `callOptions`.
    ///   - dataConverter: Optional override for payload conversion. If nil, uses the client configuration converter.
    /// - Throws: ``AsyncActivityCanceledError`` if cancellation was requested, or any error raised by interceptors or service.
    package func heartbeatAsyncActivity(
        activity: AsyncActivityHandle.Reference,
        options: AsyncActivityHeartbeatOptions?,
        dataConverter: DataConverter? = nil
    ) async throws {
        try await self.interceptor.heartbeatAsyncActivity(
            .init(
                activity: activity,
                options: options,
                dataConverter: dataConverter ?? self.interceptor.workflowService.configuration.dataConverter
            )
        )
    }

    /// Complete a running activity task successfully.
    ///
    /// Routes a completion through the outbound interceptor chain and into the workflow service.
    /// Sends the result payload to the server. After a successful call, the activity is finished
    /// and can no longer be heartbeated, failed, or cancelled.
    ///
    /// - Parameters:
    ///   - activity: The activity reference, either by `workflowID` and `activityID` (and optional `runID`) or by task token.
    ///   - result: The result value to return to the workflow, or `nil` for no result.
    ///   - options: Completion options, including optional `callOptions`.
    ///   - dataConverter: Optional override for payload conversion. If nil, uses the client configuration converter.
    package func completeAsyncActivity<Result: Sendable>(
        activity: AsyncActivityHandle.Reference,
        result: Result?,
        options: AsyncActivityCompleteOptions?,
        dataConverter: DataConverter? = nil
    ) async throws {
        try await self.interceptor.completeAsyncActivity(
            .init(
                activity: activity,
                result: result,
                options: options,
                dataConverter: dataConverter ?? self.interceptor.workflowService.configuration.dataConverter
            )
        )
    }

    /// Fail a running activity task.
    ///
    /// Routes a failure through the outbound interceptor chain and into the workflow service.
    /// Sends converted failure details and optional last-heartbeat details. After a successful call,
    /// the activity is finished and can no longer be heartbeated, completed, or cancelled.
    ///
    /// - Parameters:
    ///   - activity: The activity reference, either by `workflowID` and `activityID` (and optional `runID`) or by task token.
    ///   - error: The error describing the activity failure.
    ///   - options: Fail options, including optional `lastHeartbeatDetails` and `callOptions`.
    ///   - dataConverter: Optional override for payload conversion. If nil, uses the client configuration converter.
    package func failAsyncActivity(
        activity: AsyncActivityHandle.Reference,
        error: any Error,
        options: AsyncActivityFailOptions?,
        dataConverter: DataConverter? = nil
    ) async throws {
        try await self.interceptor.failAsyncActivity(
            .init(
                activity: activity,
                error: error,
                options: options,
                dataConverter: dataConverter ?? self.interceptor.workflowService.configuration.dataConverter
            )
        )
    }

    /// Report a running activity task as cancelled.
    ///
    /// Routes a cancellation through the outbound interceptor chain and into the workflow service.
    /// Optional details can be provided to describe the cancellation context. After a successful call,
    /// the activity is finished and can no longer be heartbeated, completed, or failed.
    ///
    /// - Parameters:
    ///   - activity: The activity reference, either by `workflowID` and `activityID` (and optional `runID`) or by task token.
    ///   - options: Cancellation options, including optional `details` and `callOptions`.
    ///   - dataConverter: Optional override for payload conversion. If nil, uses the client configuration converter.
    package func reportCancellationAsyncActivity(
        activity: AsyncActivityHandle.Reference,
        options: AsyncActivityReportCancellationOptions?,
        dataConverter: DataConverter? = nil
    ) async throws {
        try await self.interceptor.reportCancellationAsyncActivity(
            .init(
                activity: activity,
                options: options,
                dataConverter: dataConverter ?? self.interceptor.workflowService.configuration.dataConverter
            )
        )
    }
}
