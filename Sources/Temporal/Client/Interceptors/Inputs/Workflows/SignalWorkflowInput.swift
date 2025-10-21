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

public import struct GRPCCore.CallOptions

/// Input parameters for signaling workflow executions in client interceptors.
public struct SignalWorkflowInput<each Input: Sendable>: Sendable {
    /// The unique identifier of the workflow to signal.
    public var id: String

    /// The specific run ID of the workflow execution to signal.
    public var runID: String?

    /// The name of the signal to send to the workflow.
    public var name: String

    /// Headers to include with the signal request.
    public var headers: [String: TemporalPayload]

    /// The input arguments to pass to the signal handler.
    public var input: (repeat each Input)

    /// Optional gRPC call options for customizing the signal request.
    public var callOptions: CallOptions?

    /// Creates a new signal workflow input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to signal.
    ///   - runID: The specific run ID of the workflow execution to signal.
    ///   - name: The name of the signal to send to the workflow.
    ///   - headers: Headers to include with the signal request.
    ///   - input: The input arguments to pass to the signal handler.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        id: String,
        runID: String? = nil,
        name: String,
        headers: [String: TemporalPayload],
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.runID = runID
        self.name = name
        self.headers = headers
        self.input = (repeat each input)
        self.callOptions = callOptions
    }
}
