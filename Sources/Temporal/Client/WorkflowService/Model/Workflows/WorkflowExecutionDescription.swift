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

/// Comprehensive information about a specific workflow execution including its current state and metadata.
public struct WorkflowExecutionDescription: Hashable, Sendable {
    /// Detailed information about the specific workflow execution including status, timing, and configuration.
    public var execution: WorkflowExecution
    /// Information about the currently pending activities of the workflow execution.
    package var pendingActivities: [Api.Workflow.V1.PendingActivityInfo]
    /// Single-line fixed summary for this workflow execution that may appear in UI/CLI.
    ///
    /// This can be in single-line Temporal markdown format.
    ///
    /// - Important: This setting is experimental.
    public var staticSummary: String?
    /// General fixed details for this workflow execution that may appear in UI/CLI.
    ///
    /// This can be in Temporal markdown format and can span multiple lines.
    ///
    /// - Important: This setting is experimental.
    public var staticDetails: String?
}
