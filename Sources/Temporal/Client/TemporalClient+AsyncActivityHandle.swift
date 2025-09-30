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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient {
    /// Creates a handle for performing asynchronous completion operations on an existing activity.
    ///
    /// Use this method when you have a reference to an activity that will be completed asynchronously
    /// (i.e., outside of its original execution context) and you need to send heartbeats, complete it
    /// with a result, fail it with an error, or report it as cancelled.
    ///
    /// The returned ``AsyncActivityHandle`` provides methods that map directly to Temporal's server-side
    /// APIs for asynchronous activities:
    /// - ``AsyncActivityHandle/heartbeat(options:)`` to record liveness and check for cancellation.
    /// - ``AsyncActivityHandle/complete(result:options:)`` to complete the activity successfully.
    /// - ``AsyncActivityHandle/fail(_:options:)`` to mark the activity as failed.
    /// - ``AsyncActivityHandle/reportCancellation(options:)`` to acknowledge and record cancellation.
    ///
    /// This is typically used in scenarios where:
    /// - The activity started in a workflow but cannot be completed immediately.
    /// - Completion will happen in a different process, thread, or at a later time.
    /// - You need to maintain progress updates and cancellation responsiveness for long-running or
    ///   externally driven tasks.
    ///
    /// The `reference` parameter specifies the unique identity of the activity. This can be:
    /// - An ``AsyncActivityHandle/Reference-swift.enum/id(workflowId:runId:activityId:)`` (workflow ID, optional run ID, activity ID).
    /// - A ``AsyncActivityHandle/Reference-swift.enum/taskToken(taskToken:)`` (server-issued binary task token).
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
    ///
    /// - Parameter reference: A reference to the existing activity to be managed asynchronously.
    /// - Returns: An ``AsyncActivityHandle`` bound to the specified activity reference.
    public func asyncActivityHandle(for reference: AsyncActivityHandle.Reference) -> AsyncActivityHandle {
        AsyncActivityHandle(interceptor: self.interceptor, reference: reference)
    }
}
