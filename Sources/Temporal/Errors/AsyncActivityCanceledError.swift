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

/// Error thrown from ``AsyncActivityHandle/heartbeat(options:)`` or ``TemporalClient/WorkflowService-swift.struct/heartbeatAsyncActivity(activity:options:dataConverter:)`` if
/// workflow has requested that an activity be cancelled.
public struct AsyncActivityCanceledError: TemporalError {
    /// The error's message.
    public var message: String = "Activity cancelled"

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String = ""
}
