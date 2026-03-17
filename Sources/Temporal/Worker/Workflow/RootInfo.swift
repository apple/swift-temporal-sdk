//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// Information about the root of a workflow.
///
/// The root workflow execution is defined as follows:
/// 1. A workflow without a parent workflow is its own root workflow.
/// 2. A workflow that has a parent workflow has the same root workflow as its parent workflow.
///
/// This information is useful for tracing the origin of a workflow execution chain
/// involving child workflows.
public struct RootInfo: Sendable {
    /// The workflow ID of the root workflow execution.
    public var workflowID: String

    /// The run ID of the root workflow execution.
    public var runID: String

    /// Creates a new root workflow info instance.
    ///
    /// - Parameters:
    ///   - workflowID: The workflow ID of the root workflow execution.
    ///   - runID: The run ID of the root workflow execution.
    public init(workflowID: String, runID: String) {
        self.workflowID = workflowID
        self.runID = runID
    }
}
