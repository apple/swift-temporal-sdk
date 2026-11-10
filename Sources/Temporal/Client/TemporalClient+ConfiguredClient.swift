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

        /// Creates a new type-erased configured gRPC client for performing RPCs.
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
            let clientRequest = ClientRequest(message: encodedRequest, metadata: self.metadata)

            guard let retryPolicy = callOptions.executionPolicy?.retry else {
                let response = try await self.performAttempt(clientRequest, method: method, callOptions: callOptions)
                return try transform(response.message)
            }

            // grpc-swift stops retrying once the server has sent response headers. The Temporal server sends
            // headers before `RESOURCE_EXHAUSTED` (they carry the rate limit's cause), so those were never retried.
            // We retry them here with the same policy. Failures before headers are still grpc-swift's job.
            let deadline = callOptions.timeout.map { ContinuousClock.now + $0 }
            var backoff = RetryBackoff(policy: retryPolicy)
            var attempt = 1
            while true {
                var attemptCallOptions = callOptions
                if let deadline {
                    attemptCallOptions.timeout = ContinuousClock.now.duration(to: deadline)
                }
                let response = try await self.performAttempt(clientRequest, method: method, callOptions: attemptCallOptions)

                guard case .success(let contents) = response.accepted,
                    case .failure(let error) = contents.message,
                    retryPolicy.retryableStatusCodes.contains(Status.Code(error.code)),
                    attempt < retryPolicy.maxAttempts
                else {
                    return try transform(response.message)
                }

                let delay = backoff.next()
                if let deadline, ContinuousClock.now + delay >= deadline {
                    throw error
                }
                try await Task.sleep(for: delay)
                attempt += 1
            }
        }

        private func performAttempt(
            _ request: ClientRequest<[UInt8]>,
            method: GRPCCore.MethodDescriptor,
            callOptions: GRPCCore.CallOptions
        ) async throws -> ClientResponse<[UInt8]> {
            try await self.client.unary(
                request,
                method,
                UInt8ArraySerializer(),
                UInt8ArrayDeserializer(),
                callOptions
            ) { $0 }
        }
    }
}

/// Exponential backoff with full jitter, matching grpc-swift's retry executor.
private struct RetryBackoff {
    private let multiplier: Double
    private let maximum: Double
    private var current: Double

    init(policy: GRPCCore.RetryPolicy) {
        self.multiplier = policy.backoffMultiplier
        self.maximum = policy.maxBackoff.seconds
        self.current = policy.initialBackoff.seconds
    }

    mutating func next() -> Duration {
        let backoff = min(self.current, self.maximum)
        self.current *= self.multiplier
        return .seconds(Double.random(in: 0...backoff))
    }
}

extension Duration {
    fileprivate var seconds: Double {
        Double(self.components.seconds) + Double(self.components.attoseconds) / 1e18
    }
}
