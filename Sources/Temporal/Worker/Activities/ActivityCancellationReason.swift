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

/// Enumeration of reasons that can lead to activity cancellation.
///
/// This enumeration provides specific information about why an activity was cancelled,
/// allowing for appropriate error handling and cleanup logic within activity implementations.
///
/// ## Usage
///
/// The cancellation reason can be accessed from within an activity using the execution context:
///
/// ```swift
/// func run(input: String) async throws -> String {
///     // Check if the activity has been cancelled
///     if let context = ActivityExecutionContext.current,
///        let reason = Workflow.cancellationReason {
///         // Handle cancellation based on the specific reason
///         switch reason {
///         case.timeout:
///             // Handle timeout-specific cleanup
///             break
///         case .workerShutdown:
///             // Handle worker shutdown cleanup
///             break
///         default:
///             // Handle other cancellation reasons
///             break
///         }
///     }
///
///     // Normal activity logic
///     return "Result"
/// }
/// ```
public enum ActivityCancellationReason: Sendable {
    /// The activity was cancelled due to an unknown reason.
    case unknown

    /// The activity no longer exists on the server.
    ///
    /// This could be due to the activity having already completed or its workflow having already completed.
    case goneFromServer

    /// The server explicitly requested cancellation of the activity.
    case serverRequest

    /// The activity execution timed out.
    case timeout

    /// The worker hosting the activity is shutting down.
    case workerShutdown

    /// Failed to record a heartbeat.
    ///
    /// This occurs when there's a failure to convert the heartbeat's details to payloads,
    /// typically due to serialization issues with the heartbeat data.
    ///
    /// - Parameter error: The underlying error that caused the heartbeat failure.
    case heartbeatRecordFailure(any Error)

    /// The activity was paused by the Temporal server.
    ///
    /// This indicates that activity execution has been temporarily suspended
    /// and may be resumed later.
    case paused

    /// The activity was reset by the Temporal server.
    ///
    /// This indicates that the activity execution was reset and should be
    /// restarted from the beginning.
    case reset
}
