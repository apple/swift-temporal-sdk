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

/// Input parameters for listing workflow schedules in client interceptors.
public struct ListSchedulesInput: Sendable {
    /// Optional query string to filter schedules using Temporal's schedule query language.
    public var query: String?

    /// Optional gRPC call options for customizing the listing request.
    public var callOptions: CallOptions?

    /// Creates a new list schedules input with the specified parameters.
    ///
    /// - Parameters:
    ///   - query: Optional query string to filter schedules using the schedule query language.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(query: String? = nil, callOptions: CallOptions? = nil) {
        self.query = query
        self.callOptions = callOptions
    }
}
