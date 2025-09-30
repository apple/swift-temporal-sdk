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

import GRPCCore
import GRPCServiceLifecycle
import SwiftProtobuf

extension TemporalClient {
    /// Type-erased configured gRPC client of the ``TemporalClient``.
    struct ConfiguredClient: Sendable {
        let client: AnyUInt8GRPCClient
        private let metadata: GRPCCore.Metadata

        /// Initialize a new type-erased configured gRPC client for performing RPCs.
        ///
        /// - Parameters:
        ///   - client: The `GRPCClient` to use.
        ///   - metadata: Metadata for the client.
        init<Transport: ClientTransport>(
            client: GRPCClient<Transport>,
            metadata: GRPCCore.Metadata
        ) {
            // type-erasure
            self.client = AnyUInt8GRPCClient(
                run: client.run,
                unary: client.unary,
                beginGracefulShutdown: client.beginGracefulShutdown
            )
            self.metadata = metadata
        }

        /// Performs a unary RPC.
        ///
        /// - Parameters:
        ///   - method: The gRPC service method to call.
        ///   - request: The request proto.
        ///   - callOptions: Options of the call, such as retries. Defaults to retry options.
        /// - Returns: The decoded response proto.
        func unary<Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message>(
            method: GRPCCore.MethodDescriptor,
            request: Request,
            callOptions: GRPCCore.CallOptions? = nil
        ) async throws -> Response {
            try await self.performUnary(
                method: method,
                request: request,
                callOptions: callOptions ?? .defaultRetryOptions
            ) { bytes in
                try Response(serializedBytes: bytes)
            }
        }

        /// Performs a unary RPC whilst discarding the result.
        ///
        /// - Parameters:
        ///   - method: The gRPC service method to call.
        ///   - request: The request proto.
        ///   - callOptions: Options of the call, such as retries. Defaults to retry options.
        /// - Returns: The decoded response proto.
        func unary<Request: SwiftProtobuf.Message>(
            method: GRPCCore.MethodDescriptor,
            request: Request,
            callOptions: GRPCCore.CallOptions? = nil
        ) async throws {
            _ = try await self.performUnary(
                method: method,
                request: request,
                callOptions: callOptions ?? .defaultRetryOptions
            ) { _ in () }
        }

        private func performUnary<Request: SwiftProtobuf.Message, T>(
            method: GRPCCore.MethodDescriptor,
            request: Request,
            callOptions: GRPCCore.CallOptions,
            transform: @escaping ([UInt8]) throws -> T
        ) async throws -> T {
            let encodedRequest: [UInt8] = try request.serializedBytes(
                partial: false,
                options: {
                    var options = BinaryEncodingOptions()
                    options.useDeterministicOrdering = false
                    return options
                }()
            )

            let responseBytes = try await self.client.unary(
                .init(message: encodedRequest, metadata: self.metadata),
                method,
                UInt8ArraySerializer(),
                UInt8ArrayDeserializer(),
                callOptions
            ) { $0 }

            return try transform(responseBytes.message)
        }
    }
}
