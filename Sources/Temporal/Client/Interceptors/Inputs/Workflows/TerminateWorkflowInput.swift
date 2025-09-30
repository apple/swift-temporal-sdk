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

/// Input parameters for terminating workflow executions in client interceptors.
public struct TerminateWorkflowInput<each Detail: Sendable>: Sendable {
    /// The unique identifier of the workflow to terminate.
    public var id: String

    /// The specific run ID of the workflow execution to terminate.
    public var runID: String?

    /// The run ID of the first execution in the workflow chain.
    public var firstExecutionRunID: String?

    /// Human-readable reason for the workflow termination.
    public var reason: String?

    /// Additional structured details about the termination.
    public var details: (repeat each Detail)

    /// Optional gRPC call options for customizing the termination request.
    public var callOptions: CallOptions?

    /// Creates a new terminate workflow input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to terminate.
    ///   - runID: The specific run ID of the workflow execution to terminate.
    ///   - firstExecutionRunID: The run ID of the first execution in the workflow chain.
    ///   - reason: Human-readable reason for the workflow termination.
    ///   - details: Additional structured details about the termination.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        id: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        reason: String? = nil,
        details: repeat each Detail,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.runID = runID
        self.firstExecutionRunID = firstExecutionRunID
        self.reason = reason
        self.details = (repeat each details)
        self.callOptions = callOptions
    }
}
