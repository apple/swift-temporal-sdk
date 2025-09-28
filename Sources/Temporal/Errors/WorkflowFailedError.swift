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

/// Error that is returned from  when a workflow is unsuccessful.
public struct WorkflowFailedError: TemporalError {
    /// The error's message.
    public var message: String = "Workflow execution failed"

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String

    public init(
        cause: (any Error)? = nil,
        stackTrace: String = ""
    ) {
        self.cause = cause
        self.stackTrace = stackTrace
    }
}
