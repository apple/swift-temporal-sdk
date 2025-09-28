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

/// A handle for managing and interacting with a specific Temporal workflow execution without a concrete ``WorkflowDefinition``.
///
/// ``UntypedWorkflowHandle`` provides an interface for managing workflow instances throughout
/// their lifecycle. It supports querying status, signaling, updating, canceling, and retrieving
/// results from workflow executions, without encapsulating the actual type of the ``WorkflowDefinition``,
/// making it easier to interact with workflows that are not written in Swift and/or do not share the
/// ``WorkflowDefinition``.
///
/// - Note: ``WorkflowHandle`` binds to a specific ``WorkflowDefinition`` for simplified API
/// and compile-time type safety.
public struct UntypedWorkflowHandle: Sendable {
    /// The Temporal interceptor used for all workflow operations.
    package let interceptor: TemporalClient.Interceptor

    /// The unique identifier of the workflow execution.
    ///
    /// This ID remains constant across all runs of a workflow, including retries and
    /// continue-as-new operations.
    public let id: String

    /// The run ID used for targeting specific workflow runs in signal, query, and update operations.
    ///
    /// When present, this ensures that operations target a very specific workflow execution run.
    /// This field is typically set when obtaining a handle to an existing workflow, but remains
    /// `nil` when the handle is created from starting a new workflow.
    public let runID: String?

    /// The run ID used as the starting point for result retrieval operations.
    ///
    /// This run ID determines where to begin following workflow execution chains when retrieving
    /// results. It handles continue-as-new workflows by following the chain from this starting point.
    /// This field is set when starting a workflow but remains `nil` when obtaining a handle to an existing workflow.
    public let resultRunID: String?

    /// The run ID of the original workflow execution for cancel and terminate operations.
    ///
    /// Cancel and terminate operations can target the original workflow execution even if it has
    /// gone through retries or continue-as-new operations. This run ID identifies that original
    /// execution point. This field can be set when obtaining a handle and is automatically set
    /// when starting a workflow.
    public let firstExecutionRunID: String?

    /// Creates a workflow handle for managing a specific workflow execution.
    ///
    /// - Parameters:
    ///   - interceptor: The Temporal interceptor used for all workflow operations.
    ///   - id: The unique workflow identifier.
    ///   - runID: The run ID for signal, query, and update targeting.
    ///   - resultRunID: The starting run ID for result retrieval operations.
    ///   - firstExecutionRunID: The original execution run ID for cancel/terminate operations.
    package init(
        interceptor: TemporalClient.Interceptor,
        id: String,
        runID: String? = nil,
        resultRunID: String? = nil,
        firstExecutionRunID: String? = nil
    ) {
        self.interceptor = interceptor
        self.id = id
        self.runID = runID
        self.resultRunID = resultRunID
        self.firstExecutionRunID = firstExecutionRunID
    }
}
