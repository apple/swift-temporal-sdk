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

/// Error that indicates the underlying error was unknown.
public struct UnknownError: TemporalError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String

    /// Initializes a new unknown error.
    ///
    /// - Parameters:
    ///   - message: The error's message.
    ///   - cause: The cause of the current error.
    ///   - stackTrace: The stack trace of the current error.
    public init(message: String, cause: (any Error)? = nil, stackTrace: String = "") {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
    }
}
