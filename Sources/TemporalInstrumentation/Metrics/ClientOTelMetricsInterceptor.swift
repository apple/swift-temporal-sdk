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
import Metrics
import Tracing

/// Instruments the `GRPCClient` with metrics in the OTel convention.
package struct ClientOTelMetricsInterceptor: GRPCCore.ClientInterceptor {
    private let serverHostname: String
    private let networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum
    private let metricsFactory: MetricsFactory

    package init(
        serverHostname: String,
        networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum,
        metricsFactory: MetricsFactory = MetricsSystem.factory
    ) {
        self.serverHostname = serverHostname
        self.networkTransportMethod = networkTransportMethod
        self.metricsFactory = metricsFactory
    }

    package func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        let dimensions = context.dimensions(serverHostname: self.serverHostname, networkTransportMethod: self.networkTransportMethod)

        let metricsContext = GRPCMetricsContext(kind: .client, dimensions: dimensions, metricsFactory: self.metricsFactory)
        metricsContext.startCall()

        var request = request
        let wrappedProducer = request.producer
        request.producer = { writer in
            let metricsWriter = HookedRPCWriter(wrapping: writer) {
                metricsContext.recordSentMessage()
            }
            try await wrappedProducer(RPCWriter(wrapping: metricsWriter))
        }

        var response = try await next(request, context)

        switch response.accepted {
        case var .success(contents):
            let sequence = HookedAsyncSequence(wrapping: contents.bodyParts) { _ in
                metricsContext.recordReceivedMessage()
            } onFinish: { error in
                metricsContext.recordCallFinished(error: error)
            }

            contents.bodyParts = RPCAsyncSequence(wrapping: sequence)
            response.accepted = .success(contents)
        case let .failure(rpcError):
            metricsContext.recordCallFinished(error: rpcError)
        }

        return response
    }
}
