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

import struct GRPCCore.Metadata

extension BridgeClient {
    final class GrpcOverrideContext: Sendable {
        let queue: WorkerClientQueue<[UInt8]>
        // Capture the `unary` gRPC method from `AnyUInt8GRPCClient` so that we avoid generics (C-closures can't capture generics)
        let unaryGrpcRequest: UnaryCall<UInt8ArraySerializer, UInt8ArrayDeserializer>

        // NOTE: Headers (client-name, client-version, temporal-namespace, authorization/api-key)
        // are ALL handled by the Rust core SDK. We return an empty Metadata here and let
        // the Rust core's headers come through via the request_headers in the grpcCallback.
        // This avoids duplicate header definitions and ensures consistency with other language SDKs.
        var metadata: Metadata {
            return [:]
        }

        init(
            queue: WorkerClientQueue<[UInt8]>,
            unaryGrpcRequest: @escaping UnaryCall<UInt8ArraySerializer, UInt8ArrayDeserializer>,
            apiKey: String? = nil
        ) {
            self.queue = queue
            self.unaryGrpcRequest = unaryGrpcRequest
            // apiKey is passed to Rust core via TemporalWorker.Configuration, not used here
        }
    }
}
