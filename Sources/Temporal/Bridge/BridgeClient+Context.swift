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
        let clientName: String = TemporalWorker.Configuration.workerClientName
        let clientVersion: String = TemporalWorker.Configuration.workerClientVersion
        let apiKey: String?

        // NOTE: When using grpc_override_callback, Swift handles ALL gRPC calls (including worker calls).
        // Since we're not passing the API key to the Rust core, we must set
        // the authorization header here for worker authentication.
        var metadata: Metadata {
            var metadata: Metadata = [:]
            if let apiKey {
                metadata.addString("Bearer \(apiKey)", forKey: "authorization")
            }
            return metadata
        }

        init(
            queue: WorkerClientQueue<[UInt8]>,
            unaryGrpcRequest: @escaping UnaryCall<UInt8ArraySerializer, UInt8ArrayDeserializer>,
            apiKey: String?
        ) {
            self.queue = queue
            self.unaryGrpcRequest = unaryGrpcRequest
            self.apiKey = apiKey
        }
    }
}
