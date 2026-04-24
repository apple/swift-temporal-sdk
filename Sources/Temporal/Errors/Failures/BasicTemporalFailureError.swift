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

/// A basic Temporal failure error.
public struct BasicTemporalFailureError: TemporalFailureError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// Creates a new basic Temporal failure error.
    ///
    /// - Parameters:
    ///   - message: The error's message.
    ///   - cause: The cause of the current error. Defaults to `nil`.
    ///   - stackTrace: The stack trace of the current error.
    public init(
        message: String,
        cause: (any Error)? = nil,
        stackTrace: String
    ) {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
    }
}
