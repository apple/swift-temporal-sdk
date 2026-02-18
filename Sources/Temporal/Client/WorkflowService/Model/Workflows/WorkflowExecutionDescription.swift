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
    public var pendingActivities: [PendingActivityInfo]

    // TODO: Incorporate remaining properties `Api.Workflowservice.V1.DescribeWorkflowExecutionResponse`
}
