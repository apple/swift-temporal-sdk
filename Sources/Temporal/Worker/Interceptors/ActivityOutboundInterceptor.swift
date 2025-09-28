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

/// Protocol for intercepting and modifying activity heartbeat requests sent from activities to the Temporal server.
public protocol ActivityOutboundInterceptor: Sendable {
    /// Intercepts heartbeat requests sent from activities to the Temporal server.
    ///
    /// - Parameters:
    ///   - input: The heartbeat input containing activity details and progress information.
    ///   - next: A closure to invoke the next interceptor in the chain.
    func heartbeat<each Detail>(
        input: HeartbeatInput<repeat each Detail>,
        next: (HeartbeatInput<repeat each Detail>) -> Void
    )
}

extension ActivityOutboundInterceptor {
    /// Default implementation that forwards heartbeat requests to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The heartbeat input to forward to the next interceptor.
    ///   - next: A closure to invoke the next interceptor in the chain.
    public func heartbeat<each Detail>(
        input: HeartbeatInput<repeat each Detail>,
        next: (HeartbeatInput<repeat each Detail>) -> Void
    ) {
        next(input)
    }
}
