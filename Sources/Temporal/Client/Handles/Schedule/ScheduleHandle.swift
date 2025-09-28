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

/// A handle for managing and interacting with Temporal workflow schedules.
///
/// ``ScheduleHandle`` provides an interface for managing workflow schedules after
/// they have been created. It supports retrieving schedule information, updating configurations,
/// controlling schedule execution, and performing administrative operations.
///
/// - Note: ``UntypedScheduleHandle`` provides the same functionality as ``ScheduleHandle``
/// without binding to a specific ``WorkflowDefinition``, simplifying interoperability with
/// Temporal workflows not implemented in Swift and/or do not share the ``WorkflowDefinition``.
public struct ScheduleHandle<Workflow: WorkflowDefinition>: Sendable {
    /// The untyped schedule handle implementation encapsulating core execution logic.
    package let untypedHandle: UntypedScheduleHandle

    /// The unique identifier of the workflow schedule.
    ///
    /// This ID uniquely identifies the schedule within the Temporal namespace and is used
    /// for all schedule operations including updates, queries, and lifecycle management.
    public var id: String {
        self.untypedHandle.id
    }

    /// Creates a schedule handle for managing an existing or newly created schedule.
    ///
    /// - Parameters:
    ///   - untypedHandle: The untyped schedule handle implementation encapsulating core execution logic.
    package init(untypedHandle: UntypedScheduleHandle) {
        self.untypedHandle = untypedHandle
    }
}
