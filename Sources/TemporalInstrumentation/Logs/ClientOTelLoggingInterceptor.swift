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
import Logging
import OTelSemanticConventions
import Tracing

/// Logging interceptor for the `GRPCClient`.
package struct ClientOTelLoggingInterceptor: ClientInterceptor {
    private let logger: Logger
    private let serverHostname: String
    private let networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum
    private var includeRequestMetadata: Bool
    private var includeResponseMetadata: Bool

    /// Initialize an OTel logging interceptor for the gRPC client.
    ///
    /// - Parameters:
    ///   - logger: The `Logger` instance to-be-used in the interceptor. The `Logger.Metadata` should include trace and span IDs for log correlation.
    ///   - severHostname: The hostname of the RPC server. This will be the value for the `server.address` attribute in spans.
    ///   - networkTransportMethod: The transport in use (e.g. "tcp", "unix"). This will be the value for the `network.transport` attribute in spans.
    ///   - includeRequestMetadata: if `true`, **all** metadata keys with string values included in the request will be added to the logger metadata.
    ///   - includeResponseMetadata: if `true`, **all** metadata keys with string values included in the response will be added to the logger metadata.
    package init(
        logger: Logger,
        serverHostname: String,
        networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum,
        includeRequestMetadata: Bool = false,
        includeResponseMetadata: Bool = false
    ) {
        self.logger = logger  // Should include trace and span IDs for log correlation
        self.serverHostname = serverHostname
        self.networkTransportMethod = networkTransportMethod
        self.includeRequestMetadata = includeRequestMetadata
        self.includeResponseMetadata = includeResponseMetadata
    }

    package func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (
            _ request: StreamingClientRequest<Input>,
            _ context: ClientContext
        ) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        // Build logging metadata
        var metadata = context.metadata(
            serverHostname: self.serverHostname,
            networkTransportMethod: self.networkTransportMethod,
            requestMetadata: self.includeRequestMetadata ? request.metadata : [:]
        )

        self.logger.trace("Invoking RPC", metadata: metadata)

        // Invoke RPC
        let response: StreamingClientResponse<Output>
        do {
            response = try await next(request, context)
        } catch {
            // Indicates a failure triggered down the interceptor chain, not a failure in the actual request processing.
            let errorType = String(describing: type(of: error))
            metadata.append(attribute: \.error.type, .init(rawValue: errorType))
            metadata.append(attribute: \.exception.message, "\(error)")
            metadata.append(attribute: \.exception.type, errorType)

            self.logger.log(
                level: error is CancellationError ? .trace : .info,
                "RPC failed in interceptor chain",
                metadata: metadata
            )
            throw error
        }

        // Response metadata
        if self.includeResponseMetadata {
            for responseMetadataEntry in response.metadata {
                metadata[
                    RPCAttributes.GRPCAttributes.NestedSpanAttributes.responseMetadata.name + "." + responseMetadataEntry.key.lowercased()
                ] = .string(responseMetadataEntry.value.encoded())  // encodes binary data in base64
            }
        }

        switch response.accepted {
        case .success:
            // An "accepted" request is one where the the server responds with initial metadata and attempts to process the request.
            // Does NOT guarantee that the request will be processed successfully, server could fail to complete processing the request.
            self.logger.trace("Accepted RPC", metadata: metadata)
        case .failure(let rpcError):
            // A "rejected" request is one where the server responds with a status as the first and only response part and doesn't process the request body.
            // Indicates that the server chose not to process the RPC or the client failed to execute the request.
            metadata.append(attribute: \.rpc.gRPC.statusCode, rpcError.code.description)
            metadata.append(attribute: \.error.type, .init(rawValue: "RPCError"))
            metadata.append(attribute: \.exception.message, rpcError.message)
            metadata.append(attribute: \.exception.type, "RPCError")
            if let cause = rpcError.cause {
                metadata.append(attribute: \.exception.stacktrace, "\(cause)")
            }

            // Error response metadata
            if self.includeResponseMetadata {
                for responseErrorMetadataEntry in rpcError.metadata {
                    metadata[
                        RPCAttributes.GRPCAttributes.NestedSpanAttributes.responseMetadata.name + "." + responseErrorMetadataEntry.key.lowercased()
                    ] = .string(responseErrorMetadataEntry.value.encoded())  // encodes binary data in base64
                }
            }

            self.logger.log(
                level: rpcError.cause is CancellationError ? .trace : .info,
                "Rejected RPC",
                metadata: metadata
            )
        }

        return response
    }
}
