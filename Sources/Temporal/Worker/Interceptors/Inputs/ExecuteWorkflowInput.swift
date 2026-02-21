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

/// Input structure containing parameters and context for workflow execution in interceptor chains.
public struct ExecuteWorkflowInput<Workflow: WorkflowDefinition>: Sendable {
    /// Headers containing metadata and context information for workflow execution.
    public var headers: [String: Api.Common.V1.Payload]

    /// The input parameters to be passed to the workflow for execution.
    public var input: Workflow.Input

    /// Creates workflow execution input with the specified information, headers, and parameters.
    ///
    /// - Parameters:
    ///   - headers: The headers containing metadata and context for execution.
    ///   - input: The input parameters for workflow execution.
    package init(headers: [String: Api.Common.V1.Payload], input: Workflow.Input) {
        self.headers = headers
        self.input = input
    }
}
