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

/// Error indicating that the activity will be completed asynchronously.
///
/// Throw this from an activity to tell the worker not to complete, fail, or cancel it immediately.
/// The activity will be completed later using its task token, typically from another task,
/// process, or service, via an ``AsyncActivityHandle``.
///
/// This is useful for long-running or externally-managed operations where the final
/// completion result is not available within the activity's execution.
///
/// ### Usage
///
/// ```swift
/// var taskToken: ActivityTaskToken?
///
/// @Activity
/// func activityDefault(input: String) async throws -> String {
///     taskToken = ActivityExecutionContext.current!.info.taskToken  // Save the token for later completion
///     throw CompleteAsyncError()  // indicate that activity will be completed later
/// }
/// ```
///
/// Later, from another task or process:
/// ```swift
/// let handle = client.asyncActivityHandle(for: .taskToken(taskToken))
/// try await handle.complete(result: "Done!")
/// ```
public struct CompleteAsyncError: TemporalError {
    /// The error's message.
    public var message: String = "Activity will be completed asynchronously"

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String = ""

    /// Create a new error that signals that the activity will be completed asynchronously.
    public init() {}
}
