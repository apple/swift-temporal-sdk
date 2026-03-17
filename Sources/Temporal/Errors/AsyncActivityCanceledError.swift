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

/// Error thrown from ``AsyncActivityHandle/heartbeat(options:)`` or ``TemporalClient/WorkflowService-swift.struct/heartbeatAsyncActivity(activity:options:dataConverter:)`` if
/// the server indicates the activity has been cancelled, paused, or reset.
public struct AsyncActivityCanceledError: TemporalError {
    /// The error's message.
    public var message: String = "Activity cancelled"

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String = ""

    /// Details about why the activity was cancelled.
    public var details: ActivityCancellationDetails

    /// Creates an ``AsyncActivityCanceledError`` with the given cancellation details.
    ///
    /// - Parameter details: The cancellation details describing why the activity was cancelled.
    public init(details: ActivityCancellationDetails) {
        self.details = details
    }
}
