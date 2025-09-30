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

import struct GRPCCore.CallOptions

/// Input parameters for starting workflow executions in client interceptors.
public struct StartWorkflowInput<each Input: Sendable>: Sendable {
    /// The name of the workflow type to start.
    public var name: String

    /// Configuration options controlling workflow execution behavior.
    public var options: WorkflowOptions

    /// Headers to include with the workflow start request.
    public var headers: [String: TemporalPayload]

    /// The input arguments to pass to the workflow.
    public var input: (repeat each Input)

    /// Optional gRPC call options for customizing the start request.
    public var callOptions: CallOptions?

    /// Creates a new start workflow input with the specified parameters.
    ///
    /// - Parameters:
    ///   - name: The name of the workflow type to start.
    ///   - options: Configuration options controlling workflow execution behavior.
    ///   - headers: Headers to include with the workflow start request.
    ///   - input: The input arguments to pass to the workflow.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        name: String,
        options: WorkflowOptions,
        headers: [String: TemporalPayload],
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) {
        self.name = name
        self.options = options
        self.headers = headers
        self.input = (repeat each input)
        self.callOptions = callOptions
    }
}
