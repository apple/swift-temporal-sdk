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

/// Error that is thrown when querying a workflow and the query was rejected.
public struct WorkflowQueryRejectedError: TemporalError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String

    /// The workflow's execution status.
    public var workflowExecutionStatus: Api.Enums.V1.WorkflowExecutionStatus

    /// Creates a new workflow query rejected error.
    ///
    /// - Parameters:
    ///   - stackTrace: The stack trace of the current error.
    ///   - workflowExecutionStatus: The workflow's execution status.
    public init(
        stackTrace: String = "",
        workflowExecutionStatus: Api.Enums.V1.WorkflowExecutionStatus
    ) {
        self.message = "Workflow query rejected \(workflowExecutionStatus)"
        self.stackTrace = stackTrace
        self.workflowExecutionStatus = workflowExecutionStatus
    }
}
