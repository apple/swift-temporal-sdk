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

/// Options for heartbeats in async activities.
public struct AsyncActivityHeartbeatOptions: Sendable {
    /// The details for the heartbeat.
    public var details: [any Sendable]
    /// Optional gRPC call options for customizing the description request.
    public var callOptions: CallOptions?

    /// Create options for heartbeats in async activities.
    ///
    /// - Parameters:
    ///   - details: The details for the heartbeat.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        details: [any Sendable],
        callOptions: CallOptions? = nil
    ) {
        self.details = details
        self.callOptions = callOptions
    }
}
