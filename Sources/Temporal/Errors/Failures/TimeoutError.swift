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

/// Error representing a timed out workflow.
public struct TimeoutError: TemporalFailureError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// Type of the timeout.
    public var type: TimeoutType

    /// The details of the last heartbeat.
    public var lastHeartbeatDetails: [Api.Common.V1.Payload]

    /// Initializes a new timed out error.
    ///
    /// - Parameters:
    ///   - message: The error's message.
    ///   - type: The type of the timeout.
    ///   - cause: The cause of the current error. Defaults to `nil`.
    ///   - stackTrace: The stack trace of the current error.
    ///   - lastHeartbeatDetails: The details of the last heartbeat.
    public init(
        message: String,
        type: TimeoutType,
        cause: (any Error)? = nil,
        stackTrace: String = "",
        lastHeartbeatDetails: [Api.Common.V1.Payload] = []
    ) {
        self.message = message
        self.type = type
        self.cause = cause
        self.stackTrace = stackTrace
        self.lastHeartbeatDetails = lastHeartbeatDetails
    }
}
