//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import struct GRPCCore.CallOptions

/// Input parameters for cancelling workflow executions in client interceptors.
public struct CancelWorkflowInput: Sendable {
    /// The unique identifier of the workflow to cancel.
    public var id: String

    /// The specific run ID of the workflow execution to cancel.
    public var runID: String?

    /// The run ID of the first execution in the workflow's chain.
    public var firstExecutionRunID: String?

    /// Optional gRPC call options for customizing the cancellation request.
    public var callOptions: CallOptions?

    /// Creates a new cancel workflow input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to cancel.
    ///   - runID: The specific run ID of the workflow execution to cancel. If `nil`, applies to the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the workflow's chain for validation. If `nil`, no chain validation is performed.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(id: String, runID: String? = nil, firstExecutionRunID: String? = nil, callOptions: CallOptions? = nil) {
        self.id = id
        self.runID = runID
        self.firstExecutionRunID = firstExecutionRunID
        self.callOptions = callOptions
    }
}
