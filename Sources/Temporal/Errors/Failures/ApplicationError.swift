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

/// Error thrown during workflow or activity execution.
///
/// For workflows, users should throw this error to signal a workflow failure.
/// Other non-``TemporalFailureError``s will not fail the workflow.
///
/// In activities, all non-``TemporalError``s are translated to this error as retryable with the type
/// as the unqualified error class name.
public struct ApplicationError: TemporalFailureError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// The details of the error.
    public var details: [Api.Common.V1.Payload]

    /// The string type of the error, if any.
    public var type: String?

    /// A Boolean value that indicates whether the error is nonretryable.
    public var isNonRetryable: Bool

    /// Delay duration before the next retry attempt.
    public var nextRetryDelay: Duration?

    /// The error category.
    public var category: Api.Enums.V1.ApplicationErrorCategory

    /// Creates a new application error.
    ///
    /// - Parameters:
    ///   - message: The error's message.
    ///   - cause: The cause of the current error. Defaults to `nil`.
    ///   - stackTrace: The stack trace of the current error.
    ///   - details: The details of the error. Defaults to empty details.
    ///   - type: The string type of the error, if any. Defaults to `nil`.
    ///   - isNonRetryable: A Boolean value that indicates whether the error is nonretryable. Defaults to `false`.
    ///   - nextRetryDelay: Delay duration before the next retry attempt. Defaults to `nil`.
    ///   - category: The error category. Defaults to `.unspecified`.
    public init(
        message: String,
        cause: (any Error)? = nil,
        stackTrace: String = "",
        details: [Api.Common.V1.Payload] = [],
        type: String? = nil,
        isNonRetryable: Bool = false,
        nextRetryDelay: Duration? = nil,
        category: Api.Enums.V1.ApplicationErrorCategory = .unspecified
    ) {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
        self.details = details
        self.type = type
        self.isNonRetryable = isNonRetryable
        self.nextRetryDelay = nextRetryDelay
        self.category = category
    }
}
