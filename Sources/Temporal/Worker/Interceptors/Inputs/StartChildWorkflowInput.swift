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

/// Input structure containing parameters and context for child workflow startup operations in interceptor chains.
public struct StartChildWorkflowInput<each Input: Sendable>: Sendable {
    /// Information about the current workflow execution.
    public var info: WorkflowInfo

    /// The name identifying the type of child workflow to be started.
    public var name: String

    /// The configuration options controlling how the child workflow should be executed.
    public var options: ChildWorkflowOptions

    /// Headers containing metadata and context information for child workflow startup and execution.
    public var headers: [String: Api.Common.V1.Payload]

    /// The input parameters to be passed to the child workflow for execution.
    public var input: (repeat each Input)

    /// Creates a new start child workflow input.
    ///
    /// - Parameters:
    ///   - info: Information about the current workflow execution.
    ///   - name: The name identifying the type of child workflow to be started.
    ///   - options: The configuration options controlling how the child workflow should be executed.
    ///   - headers: Headers containing metadata and context information for child workflow startup and execution.
    ///   - input: The input parameters to be passed to the child workflow for execution.
    public init(
        info: WorkflowInfo,
        name: String,
        options: ChildWorkflowOptions,
        headers: [String: Api.Common.V1.Payload],
        input: repeat each Input
    ) {
        self.info = info
        self.name = name
        self.options = options
        self.headers = headers
        self.input = (repeat each input)
    }
}
