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

/// A handle for managing and interacting with Temporal workflow schedules without a concrete ``WorkflowDefinition``.
///
/// ``ScheduleHandle`` provides an interface for managing workflow schedules after
/// they have been created. It supports retrieving schedule information, updating configurations,
/// controlling schedule execution, and performing administrative operations, without encapsulating
/// the actual type of the triggered ``WorkflowDefinition``, making it easier to schedule
/// workflows that are not written in Swift and/or do not share the ``WorkflowDefinition``.
///
/// - Note: ``ScheduleHandle`` binds to a specific ``WorkflowDefinition`` for simplified API
/// and compile-time type safety.
public struct UntypedScheduleHandle: Sendable {
    /// The Temporal interceptor used for all schedule operations.
    package let interceptor: TemporalClient.Interceptor

    /// The unique identifier of the workflow schedule.
    ///
    /// This ID uniquely identifies the schedule within the Temporal namespace and is used
    /// for all schedule operations including updates, queries, and lifecycle management.
    public let id: String

    /// Creates a schedule handle for managing an existing or newly created schedule.
    ///
    /// - Parameters:
    ///   - interceptor: The Temporal interceptor used for all schedule operations.
    ///   - id: The unique identifier of the schedule to manage.
    package init(
        interceptor: TemporalClient.Interceptor,
        id: String
    ) {
        self.interceptor = interceptor
        self.id = id
    }
}
