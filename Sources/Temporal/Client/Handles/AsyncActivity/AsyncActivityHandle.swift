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

import GRPCCore

import struct Foundation.Data

/// A handle for performing asynchronous completion operations on a specific activity.
///
/// An ``AsyncActivityHandle`` is used when an activity execution is not completed within
/// its initial invocation and must be completed at a later time, potentially from a
/// different process, thread, or service instance. This handle provides methods to:
///
/// - Send heartbeats to maintain liveness and detect cancellation requests.
/// - Complete the activity with a result.
/// - Fail the activity with an error.
/// - Report the activity as cancelled.
///
/// These operations correspond directly to Temporal's asynchronous activity APIs,
/// ensuring that the activity's lifecycle is accurately managed on the server.
///
/// ### Typical Use Cases
/// - **Long-running tasks** that depend on external systems or user input.
/// - **Work delegation** where the activity is picked up by another worker or service.
/// - **Multi-step processes** where the activity spans multiple application runs.
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
/// ### Obtaining a handle
/// An `AsyncActivityHandle` is typically obtained through:
/// - ``TemporalClient/asyncActivityHandle(for:)`` when you have an ``AsyncActivityHandle/Reference``.
/// - Directly within an activity that has opted into asynchronous completion.
///
/// ### Activity references
/// Each handle is bound to an ``AsyncActivityHandle/Reference``, which uniquely
/// identifies the activity in Temporal. This can be:
/// - ``AsyncActivityHandle/Reference-swift.enum/id(workflowId:runId:activityId:)``: Identified by workflow ID, optional run ID, and activity ID.
/// - ``AsyncActivityHandle/Reference-swift.enum/taskToken(taskToken:)``: Identified by a server-issued binary task token.
///
/// - SeeAlso: ``AsyncActivityHandle/heartbeat(options:)``,
///   ``AsyncActivityHandle/complete(result:options:)``,
///   ``AsyncActivityHandle/fail(_:options:)``,
///   ``AsyncActivityHandle/reportCancellation(options:)``.
public struct AsyncActivityHandle: Sendable {
    /// Reference to an existing activity.
    public enum Reference: Hashable, Sendable {
        /// Reference to an activity by its workflow ID, workflow run ID, and activity ID.
        ///
        /// - Parameters:
        ///    - workflowId: ID for the activity's workflow.
        ///    - runId: Run ID for the activity's workflow.
        ///    - activityId: ID for the activity.
        case id(workflowId: String, runId: String? = nil, activityId: String)
        /// Reference to an activity by its task token.
        ///
        /// - Parameters:
        ///    - taskToken: Task token for the activity.
        case taskToken(taskToken: ActivityTaskToken)
    }

    /// The Temporal interceptor used for all workflow operations.
    package let interceptor: TemporalClient.Interceptor
    /// Reference to the activity for this handle.
    public let reference: Reference
    /// Data converter that will be used, defaults to the one configured in ``TemporalClient/Configuration-swift.struct/dataConverter``.
    ///
    /// The used data converter can be overridden by setting this property.
    public var dataConverter: DataConverter

    /// Creates an async activity handle for performing activity actions for activities that will complete asynchronously.
    ///
    /// - Parameters:
    ///   - interceptor: The Temporal interceptor used for all workflow operations.
    ///   - reference: Reference to the activity for this handle.
    package init(
        interceptor: TemporalClient.Interceptor,
        reference: Reference,
    ) {
        self.interceptor = interceptor
        self.reference = reference
        self.dataConverter = interceptor.workflowService.configuration.dataConverter
    }
}
