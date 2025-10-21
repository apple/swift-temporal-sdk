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

/// Input parameters for listing workflow executions in client interceptors.
public struct ListWorkflowsInput: Sendable {
    /// The query string to filter workflow executions using Temporal's visibility query language.
    public var query: String

    /// Optional maximum number of workflow executions to return.
    public var limit: Int?

    /// Optional gRPC call options for customizing the listing request.
    public var callOptions: CallOptions?

    /// Creates a new list workflows input with the specified parameters.
    ///
    /// - Parameters:
    ///   - query: The query string to filter workflow executions using the visibility query language.
    ///   - limit: Optional maximum number of workflow executions to return.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(query: String, limit: Int? = nil, callOptions: CallOptions? = nil) {
        self.query = query
        self.limit = limit
        self.callOptions = callOptions
    }
}
