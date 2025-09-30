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

/// Error thrown by a client or workflow when a workflow execution already started.
public struct WorkflowAlreadyStartedError: TemporalFailureError {
    /// The error's message.
    public var message: String = "Workflow execution already started"

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// ID of the already-started workflow.
    public var workflowID: String

    /// Run ID of the already-started workflow.
    public var runID: String?

    /// Name of the already-started workflow.
    public var workflowName: String

    /// Initializes a new workflow already started error.
    ///
    /// - Parameters:
    ///   - cause: The error's cause.
    ///   - stackTrace: The stack trace of the current error.
    ///   - workflowID: ID of the already-started workflow.
    ///   - runID: Run ID of the already-started workflow.
    ///   - workflowName: Name of the already-started workflow.
    public init(
        cause: (any Error)? = nil,
        stackTrace: String = "",
        workflowID: String,
        runID: String?,
        workflowName: String
    ) {
        self.cause = cause
        self.stackTrace = stackTrace
        self.workflowID = workflowID
        self.runID = runID
        self.workflowName = workflowName
    }
}
