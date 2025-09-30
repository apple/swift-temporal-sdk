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

struct TemporalSDKError: TemporalError {
    /// The error's message.
    var message: String
    /// The cause of the current error.
    var cause: (any Error)?
    /// The stack trace of the current error.
    var stackTrace: String
    /// Indicates if the error is retryable.
    let nonRetryable: Bool

    init(
        _ message: String,
        cause: (any Error)? = nil,
        stackTrace: String = "",
        nonRetryable: Bool = false
    ) {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
        self.nonRetryable = nonRetryable
    }
}
