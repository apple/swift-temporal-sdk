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

/// Error that is returned when a workflow execution is unsuccessful.
public struct WorkflowFailedError: TemporalError {
    /// The error's message.
    public var message: String = "Workflow execution failed"

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String

    /// Initializes a new workflow failed error.
    ///
    /// - Parameters:
    ///   - cause: The cause of the current error. Defaults to `nil`.
    ///   - stackTrace: The stack trace of the current error.
    public init(
        cause: (any Error)? = nil,
        stackTrace: String = ""
    ) {
        self.cause = cause
        self.stackTrace = stackTrace
    }
}
