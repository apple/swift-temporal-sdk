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

/// Error thrown during workflow/activity cancellation.
public struct CanceledError: TemporalFailureError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// The details of the error.
    public var details: [Api.Common.V1.Payload]

    /// Initializes a new application error.
    ///
    /// - Parameters:
    ///   - message: The error's message.
    ///   - cause: The cause of the current error. Defaults to `nil`.
    ///   - stackTrace: The stack trace of the current error.
    ///   - details: The details of the error. Defaults to empty details.
    public init(
        message: String,
        cause: (any Error)? = nil,
        stackTrace: String = "",
        details: [Api.Common.V1.Payload] = []
    ) {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
        self.details = details
    }
}
