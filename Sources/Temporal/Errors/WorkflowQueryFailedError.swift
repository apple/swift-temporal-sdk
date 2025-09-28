//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// Error that occurs when a query fails.
public struct WorkflowQueryFailedError: TemporalError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    public init(
        message: String,
        cause: (any Error)?,
        stackTrace: String = ""
    ) {
        self.message = "Workflow query failed: \(message)"
        self.cause = cause
        self.stackTrace = stackTrace
    }
}
