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

import GRPCCore

/// A handle for managing and interacting with a specific Temporal workflow execution.
///
/// ``WorkflowHandle`` provides an interface for managing workflow instances throughout
/// their lifecycle. It supports querying status, signaling, updating, canceling, and retrieving
/// results from workflow executions.
///
/// - Note: ``UntypedWorkflowHandle`` provides the same functionality as ``WorkflowHandle``
/// without binding to a specific ``WorkflowDefinition``, simplifying interoperability with
/// Temporal workflows not implemented in Swift and/or do not share the ``WorkflowDefinition``.
public struct WorkflowHandle<Workflow: WorkflowDefinition>: Sendable {
    /// The untyped workflow handle implementation encapsulating core execution logic.
    package let untypedHandle: UntypedWorkflowHandle

    /// The unique identifier of the workflow execution.
    ///
    /// This ID remains constant across all runs of a workflow, including retries and
    /// continue-as-new operations.
    public var id: String {
        self.untypedHandle.id
    }

    /// The run ID used for targeting specific workflow runs in signal, query, and update operations.
    ///
    /// When present, this ensures that operations target a very specific workflow execution run.
    /// This field is typically set when obtaining a handle to an existing workflow, but remains
    /// `nil` when the handle is created from starting a new workflow.
    public var runID: String? {
        self.untypedHandle.runID
    }

    /// The run ID used as the starting point for result retrieval operations.
    ///
    /// This run ID determines where to begin following workflow execution chains when retrieving
    /// results. It handles continue-as-new workflows by following the chain from this starting point.
    /// This field is set when starting a workflow but remains `nil` when obtaining a handle to an existing workflow.
    public var resultRunID: String? {
        self.untypedHandle.resultRunID
    }

    /// The run ID of the original workflow execution for cancel and terminate operations.
    ///
    /// Cancel and terminate operations can target the original workflow execution even if it has
    /// gone through retries or continue-as-new operations. This run ID identifies that original
    /// execution point. This field can be set when obtaining a handle and is automatically set
    /// when starting a workflow.
    public var firstExecutionRunID: String? {
        self.untypedHandle.firstExecutionRunID
    }

    /// Creates a workflow handle for managing a specific workflow execution.
    ///
    /// - Parameters:
    ///   - untypedHandle: Untyped workflow handle implementation encapsulating core execution logic.
    package init(untypedHandle: UntypedWorkflowHandle) {
        self.untypedHandle = untypedHandle
    }
}
