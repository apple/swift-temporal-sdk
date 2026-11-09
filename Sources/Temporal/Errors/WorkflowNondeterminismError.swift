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

/// Error describing nondeterminism, where a workflow's code no longer matches its history.
///
/// ``WorkflowReplayer`` reports this error when replaying a history hits nondeterminism.
///
/// By default, nondeterminism fails the workflow task. List this type, or `Error`, in
/// ``TemporalWorker/Configuration/workflowFailureErrorTypes`` or a workflow's
/// ``WorkflowDefinition/failureErrorTypes`` to fail the workflow execution instead.
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
