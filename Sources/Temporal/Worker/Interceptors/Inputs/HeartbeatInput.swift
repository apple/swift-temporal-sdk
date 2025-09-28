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

/// Input structure containing parameters for activity heartbeat operations in interceptor chains.
public struct HeartbeatInput<each Detail: Sendable>: Sendable {
    /// Progress details to be sent with the heartbeat to the Temporal server.
    public var details: (repeat each Detail)

    /// Creates heartbeat input with the specified progress details.
    ///
    /// - Parameters:
    ///   - details: The progress details to include in the heartbeat.
    public init(
        details: repeat each Detail
    ) {
        self.details = (repeat each details)
    }
}
