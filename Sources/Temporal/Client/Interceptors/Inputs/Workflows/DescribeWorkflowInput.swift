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

/// Input parameters for retrieving workflow execution descriptions in client interceptors.
public struct DescribeWorkflowInput: Sendable {
    /// The unique identifier of the workflow to describe.
    public var id: String

    /// The specific run ID of the workflow execution to describe.
    public var runID: String?

    /// Optional gRPC call options for customizing the description request.
    public var callOptions: CallOptions?

    /// Creates a new describe workflow input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow to describe.
    ///   - runID: The specific run ID of the workflow execution to describe.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(id: String, runID: String? = nil, callOptions: CallOptions? = nil) {
        self.id = id
        self.runID = runID
        self.callOptions = callOptions
    }
}
