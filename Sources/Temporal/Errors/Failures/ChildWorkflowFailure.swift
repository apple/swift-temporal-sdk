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

/// Error thrown on child workflow failure.
public struct ChildWorkflowError: TemporalFailureError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// The child workflow's namespace.
    public var namespace: String

    /// The child workflow's ID.
    public var workflowID: String

    /// The child workflow's run ID.
    public var runID: String

    /// The child workflow's name.
    public var workflowName: String

    /// The child workflow's retry state.
    public var retryState: RetryState

    /// Initializes a new application error.
    ///
    /// - Parameters:
    ///   - message: The error's message.
    ///   - cause: The cause of the current error. Defaults to `nil`.
    ///   - stackTrace: The stack trace of the current error.
    ///   - namespace: The child workflow's namespace.
    ///   - workflowID: The child workflow's ID.
    ///   - runID: The child workflow's run ID.
    ///   - workflowName: The child workflow's name.
    ///   - retryState: The child workflow's retry state.
    public init(
        message: String,
        cause: (any Error)? = nil,
        stackTrace: String,
        namespace: String,
        workflowID: String,
        runID: String,
        workflowName: String,
        retryState: RetryState
    ) {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
        self.namespace = namespace
        self.workflowID = workflowID
        self.runID = runID
        self.workflowName = workflowName
        self.retryState = retryState
    }
}
