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

/// Input parameters for update-with-start workflow operations in client interceptors.
///
/// This type encapsulates the parameters needed to atomically start a workflow (if not already
/// running) and send an update to it.
public struct StartUpdateWithStartWorkflowInput<each Input: Sendable>: Sendable {
    /// The name of the workflow type to start.
    public var name: String

    /// Configuration options controlling workflow execution behavior.
    public var options: WorkflowOptions

    /// Headers to include with the workflow start request.
    public var headers: [String: Api.Common.V1.Payload]

    /// The input arguments to pass to the workflow.
    public var input: (repeat each Input)

    /// A unique identifier for this update request.
    public var updateID: String

    /// The name of the update handler to invoke in the workflow.
    public var updateName: String

    /// Headers to include with the update request.
    public var updateHeaders: [String: Api.Common.V1.Payload]

    // Variadic generic types only support a single pack currently so we need to
    // fall back to any Sendable here
    /// The input data to send with the update.
    public var updateInput: [any Sendable]

    // TODO: Add WorkflowUpdateStage wait for stage support

    /// Optional gRPC call options for customizing the request.
    public var callOptions: CallOptions?

    /// Creates a new update-with-start workflow input with the specified parameters.
    ///
    /// - Parameters:
    ///   - name: The name of the workflow type to start.
    ///   - options: Configuration options controlling workflow execution behavior.
    ///   - headers: Headers to include with the workflow start request.
    ///   - input: The input arguments to pass to the workflow.
    ///   - updateName: The name of the update handler to invoke in the workflow.
    ///   - updateInput: The input data to send with the update.
    ///   - updateID: A unique identifier for this update request.
    ///   - updateHeaders: Headers to include with the update request.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        name: String,
        input: repeat each Input,
        options: WorkflowOptions,
        headers: [String: Api.Common.V1.Payload],
        updateName: String,
        updateInput: [any Sendable],
        updateID: String,
        updateHeaders: [String: Api.Common.V1.Payload],
        callOptions: CallOptions? = nil
    ) {
        self.name = name
        self.options = options
        self.headers = headers
        self.input = (repeat each input)
        self.updateID = updateID
        self.updateName = updateName
        self.updateHeaders = updateHeaders
        self.updateInput = updateInput
        self.callOptions = callOptions
    }
}
