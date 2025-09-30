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

/// Input parameters for starting workflow updates in client interceptors.
public struct StartWorkflowUpdateInput<each Input: Sendable>: Sendable {
    /// The unique identifier of the workflow to update.
    public var id: String

    /// The specific run ID of the workflow execution to update.
    public var runID: String?

    /// A unique identifier for this specific update request.
    public var updateID: String

    /// The name of the update handler to invoke in the workflow.
    public var updateName: String

    /// The run ID of the first execution in the workflow chain.
    public var firstExecutionRunID: String?

    /// Headers to include with the update request.
    public var headers: [String: TemporalPayload]

    /// The input arguments to pass to the update handler.
    public var input: (repeat each Input)

    /// Optional gRPC call options for customizing the update request.
    public var callOptions: CallOptions?

    /// Creates a new start workflow update input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to update.
    ///   - runID: The specific run ID of the workflow execution to update.
    ///   - updateID: A unique identifier for this specific update request.
    ///   - updateName: The name of the update handler to invoke in the workflow.
    ///   - firstExecutionRunID: The run ID of the first execution in the workflow chain.
    ///   - headers: Headers to include with the update request.
    ///   - input: The input arguments to pass to the update handler.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        id: String,
        runID: String? = nil,
        updateID: String,
        updateName: String,
        firstExecutionRunID: String? = nil,
        headers: [String: TemporalPayload],
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.runID = runID
        self.updateID = updateID
        self.updateName = updateName
        self.firstExecutionRunID = firstExecutionRunID
        self.headers = headers
        self.input = (repeat each input)
        self.callOptions = callOptions
    }
}
