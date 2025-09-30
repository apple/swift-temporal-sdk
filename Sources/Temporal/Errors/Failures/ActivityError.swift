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

/// Error representing a failed activity.
public struct ActivityError: TemporalFailureError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// Scheduled event ID for this activity.
    public var scheduledEventID: Int

    /// Started event ID for this activity.
    public var startedEventID: Int

    /// The failed activity's ID.
    public var activityID: String

    /// The failed activity's type.
    public var activityType: String

    /// The client/worker identity.
    public var identity: String

    /// The retry state of the failed activity.
    public var retryState: RetryState

    /// Initializes a new application error.
    ///
    /// - Parameters:
    ///   - message: The error's message.
    ///   - cause: The cause of the current error. Defaults to `nil`.
    ///   - stackTrace: The stack trace of the current error.
    ///   - scheduledEventID: Scheduled event ID for this activity.
    ///   - startedEventID: Started event ID for this activity.
    ///   - activityID: The failed activity's ID.
    ///   - activityType: The failed activity's type.
    ///   - identity: The client/worker identity.
    ///   - retryState: The retry state of the failed activity.
    public init(
        message: String,
        cause: (any Error)? = nil,
        stackTrace: String,
        scheduledEventID: Int,
        startedEventID: Int,
        activityID: String,
        activityType: String,
        identity: String,
        retryState: RetryState
    ) {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
        self.scheduledEventID = scheduledEventID
        self.startedEventID = startedEventID
        self.activityID = activityID
        self.activityType = activityType
        self.identity = identity
        self.retryState = retryState
    }
}
