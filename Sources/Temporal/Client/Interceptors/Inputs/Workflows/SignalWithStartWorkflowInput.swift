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

public import struct GRPCCore.CallOptions

/// Input parameters for signal-with-start workflow operations in client interceptors.
///
/// This type encapsulates the parameters needed to atomically start a workflow and send a signal
/// to it. If the workflow is already running, only the signal is delivered.
public struct SignalWithStartWorkflowInput<each Input: Sendable>: Sendable {
    /// The name of the workflow type to start.
    public var name: String

    /// Configuration options controlling workflow execution behavior.
    public var options: WorkflowOptions

    /// Headers to include with the workflow start request.
    public var headers: [String: Api.Common.V1.Payload]

    /// The input arguments to pass to the workflow.
    public var input: (repeat each Input)

    /// Optional gRPC call options for customizing the start request.
    public var callOptions: CallOptions?

    /// The name of the signal to send with the start operation.
    public var signalName: String

    // Variadic generic types only support a single pack currently so we need to
    // fall back to any Sendable here
    /// The serialized signal arguments to send with the start operation.
    public var signalInput: [any Sendable]

    /// Creates a new signal-with-start workflow input with the specified parameters.
    ///
    /// - Parameters:
    ///   - name: The name of the workflow type to start.
    ///   - options: Configuration options controlling workflow execution behavior.
    ///   - headers: Headers to include with the workflow start request.
    ///   - input: The input arguments to pass to the workflow.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    ///   - signalName: The name of the signal to send with the start operation.
    ///   - signalInput: The signal input arguments  to send with the start operation.
    public init(
        name: String,
        options: WorkflowOptions,
        headers: [String: Api.Common.V1.Payload],
        input: repeat each Input,
        callOptions: CallOptions? = nil,
        signalName: String,
        signalInput: [any Sendable]
    ) {
        self.name = name
        self.options = options
        self.headers = headers
        self.input = (repeat each input)
        self.callOptions = callOptions
        self.signalName = signalName
        self.signalInput = signalInput
    }
}
