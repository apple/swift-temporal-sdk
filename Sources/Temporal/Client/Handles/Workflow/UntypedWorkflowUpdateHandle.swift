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

/// A handle for managing and tracking Temporal workflow update operations without a concrete ``WorkflowUpdateDefinition``.
///
/// ``UntypedWorkflowUpdateHandle`` provides an interface for managing individual workflow update operations
/// after they have been initiated. It allows tracking update progress, retrieving results, and
/// managing the update lifecycle, without encapsulating the actual type of the ``WorkflowUpdateDefinition``,
/// making it easier to interact with workflows that are not written in Swift and/or do not share the
/// ``WorkflowUpdateDefinition``.
///
/// - Note: ``WorkflowUpdateHandle`` binds to a specific ``WorkflowUpdateDefinition`` for simplified API
/// and compile-time type safety.
public struct UntypedWorkflowUpdateHandle: Sendable {
    /// The Temporal interceptor used for all workflow operations.
    package let interceptor: TemporalClient.Interceptor

    /// The unique identifier for this specific update operation.
    ///
    /// This ID distinguishes this update from other updates on the same workflow and is used
    /// for tracking the update's progress and retrieving its result.
    public let id: String

    /// The unique identifier of the workflow that this update targets.
    ///
    /// This identifies the specific workflow execution that the update operation is being
    /// performed against.
    public let workflowID: String

    /// The specific run ID of the workflow execution targeted by this update.
    ///
    /// When present, this ensures that the update targets a very specific workflow execution run.
    /// This is only set if the originating ``WorkflowHandle`` had a specific ``WorkflowHandle/runID``
    /// configured, providing precise targeting of workflow executions.
    public let workflowRunID: String?

    /// Creates a workflow update handle for managing a specific update operation.
    ///
    /// - Parameters:
    ///   - interceptor: The Temporal interceptor used for all workflow operations.
    ///   - id: The unique identifier for this update operation.
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - workflowRunID: The optional run ID for precise workflow execution targeting.
    package init(
        interceptor: TemporalClient.Interceptor,
        id: String,
        workflowID: String,
        workflowRunID: String? = nil,
    ) {
        self.interceptor = interceptor
        self.id = id
        self.workflowID = workflowID
        self.workflowRunID = workflowRunID
    }
}
