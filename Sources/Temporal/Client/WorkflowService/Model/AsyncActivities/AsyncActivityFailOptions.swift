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

/// Options  for failing async activities.
public struct AsyncActivityFailOptions: Sendable {
    /// The details to record as the last heartbeat details.
    public var lastHeartbeatDetails: [any Sendable]
    /// Optional gRPC call options for customizing the description request.
    public var callOptions: CallOptions?

    /// Create options  for failing async activities.
    ///
    /// - Parameters:
    ///   - lastHeartbeatDetails: The details to record as the last heartbeat details.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        lastHeartbeatDetails: [any Sendable],
        callOptions: CallOptions? = nil
    ) {
        self.lastHeartbeatDetails = lastHeartbeatDetails
        self.callOptions = callOptions
    }
}
