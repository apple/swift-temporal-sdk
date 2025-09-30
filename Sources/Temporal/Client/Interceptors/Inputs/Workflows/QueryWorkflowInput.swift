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

/// Input parameters for querying workflow executions in client interceptors.
public struct QueryWorkflowInput<each Input: Sendable>: Sendable {
    /// The unique identifier of the workflow to query.
    public var id: String

    /// The specific run ID of the workflow execution to query.
    public var runID: String?

    /// The name of the query to execute on the workflow.
    public var queryName: String

    /// Optional condition under which the query should be rejected based on workflow state.
    public var rejectionCondition: QueryRejectionCondition?

    /// Headers to include with the query request.
    public var headers: [String: TemporalPayload]

    /// The input arguments to pass to the query handler.
    public var input: (repeat each Input)

    /// Optional gRPC call options for customizing the query request.
    public var callOptions: CallOptions?

    /// Creates a new query workflow input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to query.
    ///   - runID: The specific run ID of the workflow execution to query.
    ///   - queryName: The name of the query to execute on the workflow.
    ///   - rejectionCondition: Optional condition under which the query should be rejected.
    ///   - headers: Headers to include with the query request.
    ///   - input: The input arguments to pass to the query handler.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        id: String,
        runID: String? = nil,
        queryName: String,
        rejectionCondition: QueryRejectionCondition? = nil,
        headers: [String: TemporalPayload],
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.runID = runID
        self.queryName = queryName
        self.rejectionCondition = rejectionCondition
        self.headers = headers
        self.input = (repeat each input)
        self.callOptions = callOptions
    }
}
