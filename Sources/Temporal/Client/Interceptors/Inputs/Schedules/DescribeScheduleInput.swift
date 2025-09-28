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

/// Input parameters for retrieving schedule descriptions in client interceptors.
public struct DescribeScheduleInput: Sendable {
    /// The unique identifier of the schedule to describe.
    public var id: String

    /// Optional gRPC call options for customizing the description request.
    public var callOptions: CallOptions?

    /// Creates a new describe schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to describe.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(id: String, callOptions: CallOptions? = nil) {
        self.id = id
        self.callOptions = callOptions
    }
}
