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

import Bridge
import GRPCCore
import Logging

package struct BridgeClient: ~Copyable, Sendable {
    nonisolated(unsafe) let client: OpaquePointer
    private let runtime: BridgeRuntime
    private let logger: Logger

    private init(_ client: OpaquePointer, runtime: consuming BridgeRuntime, logger: Logger) {
        self.client = client
        self.runtime = runtime
        self.logger = logger
    }

    static func withBridgeClient<Result: Sendable>(
        grpcClient: AnyUInt8GRPCClient,
        runtime: consuming BridgeRuntime,
        configuration: TemporalWorker.Configuration,
        logger: Logger,
        isolation: isolated (any Actor)? = #isolation,
        handleBridgeClient: (consuming BridgeClient) async throws -> Result
    ) async throws -> Result {
        // Workaround to capture noncopyable in closure: https://forums.swift.org/t/capture-noncopyable-in-closure/80460
        var runtimeOptional: Optional = runtime

        return try await withThrowingDiscardingTaskGroup { group in
            // Ensure that noncopyable is only consumed once as Swift doesn't have the concept
            // of a closure that is only executed once (yet)
            let runtime = runtimeOptional.take()!

            // Init the worker client queue holding all callback-based RPC tasks
            let queue = WorkerClientQueue<[UInt8]>()

            // Start gRPC client and queue
            // Neither of these is expected to fail. Shutdown only occurs if the provided
            // `handleBridgeClient` closure throws, which it does on cancellation after
            // everything has been shut down (gRPC client no longer needed).
            group.addTask {
                // Block cancellation from propagating.
                try await Task {
                    do {
                        // With the used POIX transport, this only errors if the client is already running or already stopped
                        try await grpcClient.run()
                    } catch {
                        logger.debug("gRPC client error", metadata: ["error": .string("\(error)")])
                        throw error
                    }
                }.value
            }

            group.addTask {
                // Block cancellation from propagating.
                try await Task {
                    do {
                        try await queue.runQueue()  // This should actually never error, just being on the safe side here
                    } catch {
                        logger.debug("Worker client task queue error", metadata: ["error": .string("\(error)")])
                        throw error
                    }
                }.value
            }

            defer {
                // Shutdown gRPC client and queue
                logger.debug("Shutting down task queue")
                queue.shutdown()
                logger.debug("Beginning worker client graceful shutdown")
                grpcClient.beginGracefulShutdown()
                logger.info("Shut down task queue and worker client.")
            }

            // Build user_data context and retain it (as we're in a with style function)
            let context = GrpcOverrideContext(queue: queue, unaryGrpcRequest: grpcClient.unary, apiKey: configuration.apiKey)

            // Swift-based RPC handling
            let grpcCallback: TemporalCoreClientGrpcOverrideCallback = { request_pointer, user_data in
                let context = Unmanaged<GrpcOverrideContext>.fromOpaque(user_data!).takeUnretainedValue()

                // Service and method names
                let serviceName = String(byteArrayRef: temporal_core_client_grpc_override_request_service(request_pointer))
                let rpcName = String(byteArrayRef: temporal_core_client_grpc_override_request_rpc(request_pointer))
                let descriptor = GRPCCore.MethodDescriptor(fullyQualifiedService: serviceName, method: rpcName)
                // Request metadata in format `<key1>\n<value1>\n<key2>\n<value2>`
                let requestMetadataComponents = String(byteArrayRef: temporal_core_client_grpc_override_request_headers(request_pointer)).components(
                    separatedBy: "\n"
                )
                let requestMetadata = Dictionary(
                    uniqueKeysWithValues: stride(from: 0, to: requestMetadataComponents.count - 1, by: 2)
                        .map { (requestMetadataComponents[$0], requestMetadataComponents[$0 + 1]) }
                ).reduce(into: context.metadata) { partialResult, metadata in
                    if metadata.key == "content-type" || metadata.key == "te" {
                        return  // skip reserved gRPC transport-managed headers
                    }

                    partialResult.addString(metadata.value, forKey: metadata.key)
                }
                // Request protobuf bytes, valid until `temporal_core_client_grpc_override_request_respond` is called
                let requestProtoBytesRef = temporal_core_client_grpc_override_request_proto(request_pointer)
                // Make a deep, Swift-owned copy of the underlying Rust vector as we're passing an async boundary
                let requestProtoBytes = Array(UnsafeBufferPointer<UInt8>(start: requestProtoBytesRef.data, count: Int(requestProtoBytesRef.size)))

                // Queue callback is sendable, transfer pointer in
                let requestPointerTransfer = UnsafeTransfer(wrapped: request_pointer)

                // Actual RPC is performed in the background so that the callback returns quickly
                do {
                    // Submit async RPC call to `WorkerClientQueue` that calls back once done
                    // swift-format-ignore: OnlyOneTrailingClosureArgument
                    try context.queue.submit(  // only throws if `WorkerClientQueue` buffer is full, which should basically never happen
                        work: {
                            try await context.unaryGrpcRequest(
                                .init(
                                    message: requestProtoBytes,
                                    metadata: requestMetadata
                                ),
                                descriptor,
                                UInt8ArraySerializer(),
                                UInt8ArrayDeserializer(),
                                .defaults,  // No reties, no timeout, as this is solely done by the Core SDK
                                { $0 }
                            )
                        }
                    ) { responseRaw in
                        Self.withCallbackResponse(responseRaw: responseRaw) { bridgeResponse in
                            // Fire Core SDK response callback
                            temporal_core_client_grpc_override_request_respond(requestPointerTransfer.wrapped, bridgeResponse)
                        }
                    }
                } catch {
                    "Unknown error: \(error)".withByteArrayRef { errorRef in
                        let bridgeResponse = TemporalCoreClientGrpcOverrideResponse(
                            status_code: Int32(GRPCCore.Status.Code.unknown.rawValue),
                            headers: .nil,
                            success_proto: .nil,
                            fail_message: errorRef,
                            fail_details: .nil
                        )

                        temporal_core_client_grpc_override_request_respond(requestPointerTransfer.wrapped, bridgeResponse)
                    }
                }
            }

            // Init the Core SDK TemporalClient with our callback-based RPC strategy
            let temporalClient: UnsafeTransfer<OpaquePointer> = try await withCheckedThrowingContinuation { continuation in
                do {
                    try self.withUnsafeOptions(grpcCallback: grpcCallback, grpcCallbackUserData: context, configuration: configuration) {
                        unsafe_options in
                        let holder = ContinuationHolder(continuation)
                        let opaqueHolder = Unmanaged.passRetained(holder).toOpaque()

                        temporal_core_client_connect(runtime.runtime, unsafe_options, opaqueHolder) { user_data, success, fail in
                            let holder = Unmanaged<ContinuationHolder<UnsafeTransfer<OpaquePointer>>>
                                .fromOpaque(user_data!).takeRetainedValue()

                            if let fail {
                                holder.continuation.resume(throwing: BridgeError(messagePointer: fail))
                                return
                            }

                            holder.continuation.resume(returning: .init(wrapped: success!))
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let bridgeClient = Self.init(temporalClient.wrapped, runtime: runtime, logger: logger)
            let result = try await handleBridgeClient(bridgeClient)

            return result
        }
    }

    private static func withCallbackResponse<T>(
        responseRaw: Result<ClientResponse<[UInt8]>, Error>,
        _ body: (TemporalCoreClientGrpcOverrideResponse) -> T
    ) -> T {
        do {
            // Successful RPC response path
            let response = try responseRaw.get()
            var metadata = response.metadata
            metadata.add(contentsOf: response.trailingMetadata)
            let encodedMetadata =
                metadata
                .lazy
                .filter { !$0.key.hasPrefix(":") }  // pseudo-headers like :status are reserved and invalid in gRPC user-defined metadata
                .map { "\($0)\n\($1.encoded())" }
                .joined(separator: "\n")

            return try encodedMetadata.withByteArrayRef { headersRef in
                try response.message.withByteArrayRef { successRef in
                    let resp = TemporalCoreClientGrpcOverrideResponse(
                        status_code: Int32(GRPCCore.Status.Code.ok.rawValue),
                        headers: headersRef,
                        success_proto: successRef,
                        fail_message: .nil,
                        fail_details: .nil
                    )
                    return body(resp)
                }
            }
        } catch let rpcError as RPCError {
            let encodedMetadata = rpcError.metadata
                .lazy
                .filter { !$0.key.hasPrefix(":") }  // pseudo-headers like :status are reserved and invalid in gRPC user-defined metadata
                .map { "\($0)\n\($1.encoded())" }
                .joined(separator: "\n")
            let errorMessage = "RPC error: \(rpcError.message)\(rpcError.cause.map { "\ncaused by: \($0)" } ?? "")"

            return encodedMetadata.withByteArrayRef { headersRef in
                errorMessage.withByteArrayRef { errorRef in
                    let resp = TemporalCoreClientGrpcOverrideResponse(
                        status_code: Int32(rpcError.code.rawValue),
                        headers: headersRef,
                        success_proto: .nil,
                        fail_message: errorRef,
                        fail_details: .nil
                    )
                    return body(resp)
                }
            }
        } catch {
            return "Unknown error: \(error)".withByteArrayRef { errorRef in
                let resp = TemporalCoreClientGrpcOverrideResponse(
                    status_code: Int32(GRPCCore.Status.Code.unknown.rawValue),
                    headers: .nil,
                    success_proto: .nil,
                    fail_message: errorRef,
                    fail_details: .nil
                )
                return body(resp)
            }
        }
    }

    private static func withUnsafeOptions<T>(
        grpcCallback: TemporalCoreClientGrpcOverrideCallback,
        grpcCallbackUserData: GrpcOverrideContext,
        configuration: TemporalWorker.Configuration,
        _ body: (UnsafePointer<TemporalCoreClientOptions>) throws -> T
    ) throws -> T {
        // Pass in user data fro grpc override
        let grpcCallbackUserDataPointer = Unmanaged.passUnretained(grpcCallbackUserData).toOpaque()

        return try TemporalWorker.Configuration.workerClientName.withByteArrayRef { client_name in
            try TemporalWorker.Configuration.workerClientVersion.withByteArrayRef { client_version in
                try configuration.clientIdentity.withByteArrayRef { identityBytes in
                    // has to be a valid URL, otherwise input validation fails
                    try "https://dummy.temporal.com".withByteArrayRef { dummy_target_url in
                        try "".withByteArrayRef { empty_string in
                            let options = TemporalCoreClientOptions(
                                target_url: dummy_target_url,  // Dummy URL as gRPC connection is handled by Swift
                                client_name: client_name,
                                client_version: client_version,
                                metadata: empty_string,
                                api_key: empty_string,
                                identity: identityBytes,
                                tls_options: nil,  // Empty TLS config as auth is handled by Swift
                                retry_options: nil,  // Default is picked when passing `nil`
                                keep_alive_options: nil,  // Default is picked when passing `nil`, HTTP2 gRPC keep alive enabled.
                                http_connect_proxy_options: nil,
                                grpc_override_callback: grpcCallback,
                                grpc_override_callback_user_data: grpcCallbackUserDataPointer
                            )

                            return try withUnsafePointer(to: options) { unsafe_options in
                                try body(unsafe_options)
                            }
                        }
                    }
                }
            }
        }
    }

    deinit {
        temporal_core_client_free(self.client)
    }
}
