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

/// Error thrown when an update RPC call times out or is canceled.
///
/// This is not to be confused with an update itself timing out or being canceled,
/// this is only related to the client call itself.
public struct WorkflowUpdateRPCTimeoutOrCanceledError: TemporalError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// Creates a new workflow update RPC timeout or canceled error.
    ///
    /// - Parameters:
    ///   - cause: The underlying cause of the timeout or cancellation.
    ///   - stackTrace: The stack trace at the point of failure.
    public init(
        cause: (any Error)? = nil,
        stackTrace: String = ""
    ) {
        self.message = "Timeout or cancellation waiting for update"
        self.cause = cause
        self.stackTrace = stackTrace
    }
}
