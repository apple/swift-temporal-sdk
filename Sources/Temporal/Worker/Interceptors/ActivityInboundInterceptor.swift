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

/// Protocol for intercepting and modifying activity execution requests from the Temporal server before they
/// reach activity implementations.
public protocol ActivityInboundInterceptor: Sendable {
    /// Intercepts activity execution requests from the Temporal server.
    ///
    /// - Parameters:
    ///   - input: The activity execution input containing activity details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The output produced by the activity execution.
    /// - Throws: Any error that occurs during activity execution or interception.
    func executeActivity<Activity>(
        input: ExecuteActivityInput<Activity>,
        next: (ExecuteActivityInput<Activity>) async throws -> Activity.Output
    ) async throws -> Activity.Output
}

extension ActivityInboundInterceptor {
    /// Default implementation that forwards activity execution to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The activity execution input containing activity details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The output produced by the activity execution.
    /// - Throws: Any error that occurs during activity execution or interception.
    public func executeActivity<Activity>(
        input: ExecuteActivityInput<Activity>,
        next: (ExecuteActivityInput<Activity>) async throws -> Activity.Output
    ) async throws -> Activity.Output {
        try await next(input)
    }
}
