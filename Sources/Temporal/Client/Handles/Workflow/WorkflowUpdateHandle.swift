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

/// A handle for managing and tracking Temporal workflow update operations.
///
/// ``WorkflowUpdateHandle`` provides an interface for managing individual workflow update operations
/// after they have been initiated. It allows tracking update progress, retrieving results, and
/// managing the update lifecycle while maintaining compile-time type safety.
///
/// - Note: ``UntypedWorkflowUpdateHandle`` provides the same functionality as ``WorkflowUpdateHandle``
/// without binding to a specific ``WorkflowUpdateDefinition``, simplifying interoperability with
/// Temporal workflows not implemented in Swift and/or do not share the ``WorkflowUpdateDefinition``.
public struct WorkflowUpdateHandle<WorkflowUpdate: WorkflowUpdateDefinition>: Sendable {
    /// The untyped update handle implementation encapsulating core execution logic.
    package let untypedHandle: UntypedWorkflowUpdateHandle

    /// The unique identifier for this specific update operation.
    ///
    /// This ID distinguishes this update from other updates on the same workflow and is used
    /// for tracking the update's progress and retrieving its result.
    public var id: String {
        self.untypedHandle.id
    }

    /// The unique identifier of the workflow that this update targets.
    ///
    /// This identifies the specific workflow execution that the update operation is being
    /// performed against.
    public var workflowID: String {
        self.untypedHandle.workflowID
    }

    /// The specific run ID of the workflow execution targeted by this update.
    ///
    /// When present, this ensures that the update targets a very specific workflow execution run.
    /// This is only set if the originating ``WorkflowHandle`` had a specific ``WorkflowHandle/runID``
    /// configured, providing precise targeting of workflow executions.
    public var workflowRunID: String? {
        self.untypedHandle.workflowRunID
    }

    /// Creates a workflow update handle for managing a specific update operation.
    ///
    /// - Parameters:
    ///   - untypedHandle: Untyped workflow update handle implementation encapsulating core execution logic.
    package init(untypedHandle: UntypedWorkflowUpdateHandle) {
        self.untypedHandle = untypedHandle
    }
}
