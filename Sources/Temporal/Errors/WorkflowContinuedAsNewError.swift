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

/// Error that occurs when a workflow was continued as new.
public struct WorkflowContinuedAsNewError: TemporalError {
    /// The error's message.
    public var message: String = "Workflow was continued as new."

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String

    /// New execution run ID the workflow continued to.
    public var newRunID: String

    public init(
        stackTrace: String = "",
        newRunID: String
    ) {
        self.stackTrace = stackTrace
        self.newRunID = newRunID
    }
}
