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

/// Error that is thrown when an argument is invalid.
///
/// For example ``Workflow/sleep(for:summary:)`` throws this error
/// when a negative duration is passed.
public struct ArgumentError: TemporalError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

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
