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

/// Input parameters for counting workflow executions in client interceptors.
public struct CountWorkflowsInput: Sendable {
    /// The query string used to match and count workflow executions.
    public var query: String

    /// Optional gRPC call options for customizing the count request.
    public var callOptions: CallOptions?

    /// Creates a new count workflows input with the specified parameters.
    ///
    /// - Parameters:
    ///   - query: The query string used to match and count workflow executions.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(query: String, callOptions: CallOptions? = nil) {
        self.query = query
        self.callOptions = callOptions
    }
}
