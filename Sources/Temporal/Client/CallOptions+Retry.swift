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

import GRPCCore

extension CallOptions {
    /// Default retry call options for the client.
    static var defaultRetryOptions: Self {
        var callOptions = Self.defaults
        callOptions.executionPolicy = .retry(
            .init(
                // See https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/lib.rs#L227
                maxAttempts: 5,  // would actually be 10 in the Rust impl, but grpc-swift limits it to 5.
                initialBackoff: .milliseconds(100),
                maxBackoff: .seconds(5),
                backoffMultiplier: 1.7,  // Jitter cannot be specified
                // See https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/retry.rs#L10C11-L10C32
                retryableStatusCodes: [
                    .dataLoss, .internalError, .unknown, .resourceExhausted, .aborted, .outOfRange, .unavailable,
                ]
            )
        )
        // Includes retries, will cancel overall rpc within 30 sec
        // From: https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/lib.rs#L96
        callOptions.timeout = .seconds(30)
        return callOptions
    }

    /// Retry call options for task poll requests of the client.
    ///
    /// Slightly different retry configs than the default retry options and allows to retry `CANCELLED` and `DEADLINE_EXCEEDED` status response codes.
    /// Maps to `IsWorkerTaskLongPoll` requests from the Rust SDK: https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/lib.rs#L89
    ///
    /// - Note: Used for the following RPCs:
    ///     - `client.pollWorkflowTaskQueue()`
    ///     - `client.pollActivityTaskQueue()`
    ///     - `client.pollNexusTaskQueue()`
    static var taskPollRetryOptions: Self {
        var callOptions = Self.defaults
        callOptions.executionPolicy = .retry(
            .init(
                // See https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/lib.rs#L240
                maxAttempts: 5,  // would actually be unbounded (0) in the Rust impl, but grpc-swift limits it to 5.
                initialBackoff: .milliseconds(200),
                maxBackoff: .seconds(10),
                backoffMultiplier: 2.0,  // Jitter cannot be specified
                // See https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/retry.rs#L10C11-L10C32
                retryableStatusCodes: [
                    .dataLoss, .internalError, .unknown, .resourceExhausted, .aborted, .outOfRange, .unavailable,
                    // https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/retry.rs#L207
                    .cancelled, .deadlineExceeded,
                ]
            )
        )
        // Includes retries, will cancel overall rpc within 70 sec
        // From: https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/lib.rs#L95
        callOptions.timeout = .seconds(70)
        return callOptions
    }

    /// Retry call options for user poll requests of the client.
    ///
    /// Slightly different retry configs than the default retry options.
    /// Maps to `IsUserLongPoll` requests from the Rust SDK: https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/raw.rs#L369
    ///
    /// - Note: Used for the following RPCs:
    ///     - `client.getWorkflowExecutionHistory()`
    ///     - `client.updateWorkflowExecution()`
    static var userPollRetryOptions: Self {
        var callOptions = Self.defaults
        callOptions.executionPolicy = .retry(
            .init(
                // See https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/lib.rs#L251
                maxAttempts: 5,  // would actually be unbounded (0) in the Rust impl, but grpc-swift limits it to 5.
                initialBackoff: .seconds(1),
                maxBackoff: .seconds(10),
                backoffMultiplier: 2.0,  // Jitter cannot be specified
                // See https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/retry.rs#L10C11-L10C32
                retryableStatusCodes: [
                    .dataLoss, .internalError, .unknown, .resourceExhausted, .aborted, .outOfRange, .unavailable,
                ]
            )
        )
        // Includes retries, will cancel overall rpc within 70 sec
        // From: https://github.com/temporalio/sdk-core/blob/95db75dc950cf07a99c79e6794172572dd34e6a6/client/src/lib.rs#L95
        callOptions.timeout = .seconds(70)
        return callOptions
    }
}
