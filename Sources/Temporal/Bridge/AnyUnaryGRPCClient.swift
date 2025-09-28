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

import GRPCCore

package typealias UnaryCall<Serializer: MessageSerializer, Deserializer: MessageDeserializer> =
    @Sendable (
        _ request: ClientRequest<Serializer.Message>,
        _ descriptor: MethodDescriptor,
        _ serializer: Serializer,
        _ deserializer: Deserializer,
        _ options: CallOptions,
        _ handleResponse:
            @Sendable @escaping (
                _ response: ClientResponse<Deserializer.Message>
            ) async throws -> ClientResponse<Deserializer.Message>
    ) async throws -> ClientResponse<Deserializer.Message> where Serializer.Message: Sendable, Deserializer.Message: Sendable

package protocol UnaryGRPCClient<Serializer, Deserializer>: Sendable {
    associatedtype Serializer: MessageSerializer where Serializer.Message: Sendable
    associatedtype Deserializer: MessageDeserializer where Deserializer.Message: Sendable

    /// Start the client.
    var run: @Sendable () async throws -> Void { get }

    /// Executes a unary RPC.
    var unary: UnaryCall<Serializer, Deserializer> { get }

    /// Close the client.
    var beginGracefulShutdown: @Sendable () -> Void { get }

    init(
        run: @Sendable @escaping () async throws -> Void,
        unary: @escaping UnaryCall<Serializer, Deserializer>,
        beginGracefulShutdown: @Sendable @escaping () -> Void
    )
}

/// A  `Transport` type-erased `GRPCClient` making unary RPCs.
package struct AnyUnaryGRPCClient<Serializer: MessageSerializer, Deserializer: MessageDeserializer>: UnaryGRPCClient
where Serializer.Message: Sendable, Deserializer.Message: Sendable {

    /// Start the client.
    package let run: @Sendable () async throws -> Void

    /// Executes a unary RPC.
    package let unary: UnaryCall<Serializer, Deserializer>

    /// Close the client.
    package let beginGracefulShutdown: @Sendable () -> Void

    package init(
        run: @Sendable @escaping () async throws -> Void,
        unary: @escaping UnaryCall<Serializer, Deserializer>,
        beginGracefulShutdown: @Sendable @escaping () -> Void
    ) {
        self.run = run
        self.unary = unary
        self.beginGracefulShutdown = beginGracefulShutdown
    }
}

/// A  `Transport` type-erased `GRPCClient` making unary `[UInt8]`-serialized RPCs.
package typealias AnyUInt8GRPCClient = AnyUnaryGRPCClient<UInt8ArraySerializer, UInt8ArrayDeserializer>
