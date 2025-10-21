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

extension AsyncActivityHandle {
    /// Sends a heartbeat signal for this asynchronous activity to indicate ongoing progress
    /// and optionally include additional details.
    ///
    /// Heartbeats are used to let the Temporal service know that the activity is still
    /// executing, which can prevent it from being timed out. They can also be used to send
    /// progress details back to the workflow.
    ///
    /// - Parameter options: Optional heartbeat configuration, including progress details
    ///   and gRPC call options.
    /// - Throws: ``AsyncActivityCanceledError`` if the service has requested that the activity be cancelled.
    ///           This should be caught by the caller, and ``reportCancellation(options:)`` invoked for proper handling.
    public func heartbeat(options: AsyncActivityHeartbeatOptions? = nil) async throws {
        try await self.interceptor.heartbeatAsyncActivity(
            .init(
                activity: self.reference,
                options: options,
                dataConverter: self.dataConverter
            )
        )
    }

    /// Marks this asynchronous activity as successfully completed and optionally returns a result.
    ///
    /// This signals to the Temporal service that the activity finished successfully. If a result
    /// is provided, it will be converted and delivered to the workflow that scheduled the activity.
    ///
    /// - Parameters:
    ///   - result: The result value to send back to the workflow. May be `nil` if the activity
    ///     has no return value.
    ///   - options: Optional completion configuration, including gRPC call options.
    public func complete<Result: Sendable>(
        result: Result? = nil,
        options: AsyncActivityCompleteOptions? = nil
    ) async throws {
        try await self.interceptor.completeAsyncActivity(
            .init(
                activity: self.reference,
                result: result,
                options: options,
                dataConverter: self.dataConverter
            )
        )
    }

    /// Marks this asynchronous activity as failed with the specified error.
    ///
    /// This signals to the Temporal service that the activity has encountered an unrecoverable error
    /// and should be marked as failed. The provided error will be converted and sent to the workflow.
    ///
    /// - Parameters:
    ///   - error: The error describing why the activity failed.
    ///   - options: Optional failure configuration, including last heartbeat details and gRPC call options.
    public func fail(
        _ error: any Error,
        options: AsyncActivityFailOptions? = nil
    ) async throws {
        try await self.interceptor.failAsyncActivity(
            .init(
                activity: self.reference,
                error: error,
                options: options,
                dataConverter: self.dataConverter
            )
        )
    }

    /// Reports that this asynchronous activity has been cancelled.
    ///
    /// This informs the Temporal service that the activity is no longer running due to
    /// cancellation, and optionally sends additional details about the cancellation.
    ///
    /// - Parameter options: Optional cancellation configuration, including details and gRPC call options.
    public func reportCancellation(
        options: AsyncActivityReportCancellationOptions? = nil
    ) async throws {
        try await self.interceptor.reportCancellationAsyncActivity(
            .init(
                activity: self.reference,
                options: options,
                dataConverter: self.dataConverter
            )
        )
    }

    // TODO: withSerializationContext
}

extension TemporalClient.Interceptor {
    func heartbeatAsyncActivity(
        _ input: HeartbeatAsyncActivityInput
    ) async throws {
        try await self.intercept((any ClientOutboundInterceptor).heartbeatAsyncActivity, input: input) { input in
            try await self.workflowService.heartbeatAsyncActivity(
                activity: input.activity,
                options: input.options,
                dataConverter: input.dataConverter
            )
        }
    }

    func completeAsyncActivity<Result>(
        _ input: CompleteAsyncActivityInput<Result>
    ) async throws {
        try await self.intercept((any ClientOutboundInterceptor).completeAsyncActivity, input: input) { input in
            try await self.workflowService.completeAsyncActivity(
                activity: input.activity,
                result: input.result,
                options: input.options,
                dataConverter: input.dataConverter
            )
        }
    }

    func failAsyncActivity(
        _ input: FailAsyncActivityInput
    ) async throws {
        try await self.intercept((any ClientOutboundInterceptor).failAsyncActivity, input: input) { input in
            try await self.workflowService.failAsyncActivity(
                activity: input.activity,
                error: input.error,
                options: input.options,
                dataConverter: input.dataConverter
            )
        }
    }

    func reportCancellationAsyncActivity(
        _ input: ReportCancellationAsyncActivityInput
    ) async throws {
        try await self.intercept((any ClientOutboundInterceptor).reportCancellationAsyncActivity, input: input) { input in
            try await self.workflowService.reportCancellationAsyncActivity(
                activity: input.activity,
                options: input.options,
                dataConverter: input.dataConverter
            )
        }
    }
}
