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

/// Error thrown when workflowdoes something potentially non-deterministic such as making an illegal call.
public struct WorkflowNondeterminismError: TemporalError {
    /// The error message describing the non-determinism.
    public var message: String

    /// The cause of the error, if any.
    public var cause: (any Error)?

    /// The stack trace at the point of failure.
    public var stackTrace: String

    /// Creates a new non-determinism error.
    ///
    /// - Parameters:
    ///   - message: The error message describing the non-determinism.
    ///   - cause: The underlying cause, if any.
    ///   - stackTrace: The stack trace at the point of failure.
    public init(
        message: String,
        cause: (any Error)? = nil,
        stackTrace: String = ""
    ) {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
    }
}
