//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// Error thrown by a client when attempting to create a schedule that already exists.
public struct ScheduleAlreadyRunningError: TemporalError {
    /// The error's message.
    public var message: String = "Schedule already running"

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// Initializes a new schedule already running error.
    ///
    /// - Parameters:
    ///   - cause: The error's cause.
    ///   - stackTrace: The stack trace of the current error.
    public init(
        cause: (any Error)? = nil,
        stackTrace: String = ""
    ) {
        self.cause = cause
        self.stackTrace = stackTrace
    }
}
