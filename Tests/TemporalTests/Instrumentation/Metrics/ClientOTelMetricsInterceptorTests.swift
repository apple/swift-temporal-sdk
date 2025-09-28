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

import Foundation
import GRPCCore
import Metrics
import TemporalInstrumentation
import Testing

@Suite(.tags(.instrumentationTests))
struct GRPCClientMetricsInterceptorTests {
    @Test
    func interceptorRecordsMetricsForSuccessfulCall() async throws {
        let metricsFactory = TestMetricsFactory()
        let interceptor = ClientOTelMetricsInterceptor(
            serverHostname: "test-server",
            networkTransportMethod: .tcp,
            metricsFactory: metricsFactory
        )
        let (_, requestStreamContinuation) = AsyncStream<String>.makeStream()

        let request = StreamingClientRequest<String> { writer in
            try await writer.write("test-message")
        }

        let responseContent = StreamingClientResponse<String>(
            accepted: .success(
                .init(
                    metadata: [],
                    bodyParts: RPCAsyncSequence(
                        wrapping: AsyncThrowingStream<StreamingClientResponse.Contents.BodyPart, any Error> {
                            $0.yield(.message("response-message"))
                            $0.finish()
                        }
                    )
                )
            )
        )

        let next: (StreamingClientRequest<String>, ClientContext) async throws -> StreamingClientResponse<String> = { request, _ in
            // Make sure the `producer` closure's which includes instrumentation is called.
            let writer = RPCWriter(wrapping: TestWriter(streamContinuation: requestStreamContinuation))
            try await request.producer(writer)
            requestStreamContinuation.finish()

            let activeRequests = try #require(metricsFactory.meters.first(where: { $0.label == "rpc.client.active_requests" }))
            self.checkCommonDimensions(activeRequests.dimensions)
            #expect(activeRequests.lastValue == 1)

            return responseContent
        }

        // Execute the interceptor
        let response = try await interceptor.intercept(
            request: request,
            context: ClientContext(descriptor: .init(fullyQualifiedService: "test-service", method: "test-method"), remotePeer: "", localPeer: ""),
            next: next
        )

        // Consume the response to trigger the hooks
        if case let .success(contents) = response.accepted {
            for try await _ in contents.bodyParts {}
        }

        let activeRequests = try #require(metricsFactory.meters.first(where: { $0.label == "rpc.client.active_requests" }))
        self.checkCommonDimensions(activeRequests.dimensions)
        #expect(activeRequests.lastValue == 0)  // must be 0 after call finishes

        let requestsPerRPC = try #require(metricsFactory.recorders.first(where: { $0.label == "rpc.client.requests_per_rpc" }))
        self.checkCommonDimensions(requestsPerRPC.dimensions)
        #expect(requestsPerRPC.values.reduce(0, +) == 1)

        let responsesPerRPC = try #require(metricsFactory.recorders.first(where: { $0.label == "rpc.client.responses_per_rpc" }))
        self.checkCommonDimensions(responsesPerRPC.dimensions)
        #expect(responsesPerRPC.values.reduce(0, +) == 1)

        let calls = try #require(metricsFactory.counters.first(where: { $0.label == "rpc.client.calls" }))
        self.checkCommonDimensions(calls.dimensions, count: 6)
        #expect(calls.dimensions.first(where: { $0.0 == "rpc.grpc.status_code" })?.1 == "0")
        #expect(calls.lastValue == 1)

        let duration = try #require(metricsFactory.timers.first(where: { $0.label == "rpc.client.duration" }))
        self.checkCommonDimensions(duration.dimensions, count: 6)
        #expect(
            calls.dimensions.first(where: { $0.0 == "rpc.grpc.status_code" })?.1 == GRPCCore.Status(code: .ok, message: "").code.rawValue.description
        )
        let lastDurationValueNanoSeconds = try #require(duration.lastValue)
        let lastDurationValue = Double(lastDurationValueNanoSeconds) / 1_000_000_000
        #expect(0 < lastDurationValue && lastDurationValue < 1)  // between 0 and 1 sec

        #expect(metricsFactory.counters.first(where: { $0.label == "rpc.client.request.errors" }) == nil)  // no thrown errors
    }

    @Test
    func interceptorRecordsMetricsForFailedCall() async throws {
        let metricsFactory = TestMetricsFactory()
        let interceptor = ClientOTelMetricsInterceptor(
            serverHostname: "test-server",
            networkTransportMethod: .tcp,
            metricsFactory: metricsFactory
        )

        let (_, requestStreamContinuation) = AsyncStream<String>.makeStream()
        let request = StreamingClientRequest<String> { writer in
            try await writer.write("test-message")
        }

        let next: (StreamingClientRequest<String>, ClientContext) async throws -> StreamingClientResponse<String> = { request, _ in
            // Make sure the `producer` closure's which includes instrumentation is called.
            let writer = RPCWriter(wrapping: TestWriter(streamContinuation: requestStreamContinuation))
            try await request.producer(writer)
            requestStreamContinuation.finish()

            let activeRequests = try #require(metricsFactory.meters.first(where: { $0.label == "rpc.client.active_requests" }))
            self.checkCommonDimensions(activeRequests.dimensions)
            #expect(activeRequests.lastValue == 1)

            return .init(
                metadata: [],
                bodyParts: RPCAsyncSequence(
                    wrapping: AsyncThrowingStream<StreamingClientResponse.Contents.BodyPart, any Error> {
                        $0.finish(throwing: RPCError(code: .unavailable, message: "This should be thrown"))
                    }
                )
            )
        }

        // Execute the interceptor
        do {
            let response = try await interceptor.intercept(
                request: request,
                context: ClientContext(
                    descriptor: .init(fullyQualifiedService: "test-service", method: "test-method"),
                    remotePeer: "",
                    localPeer: ""
                ),
                next: next
            )

            // Consume the response to trigger the hooks
            if case let .success(contents) = response.accepted {
                for try await _ in contents.bodyParts {
                    // We don't care about any received messages here
                }
            }
        } catch {
            let activeRequests = try #require(metricsFactory.meters.first(where: { $0.label == "rpc.client.active_requests" }))
            self.checkCommonDimensions(activeRequests.dimensions)
            #expect(activeRequests.lastValue == 0)  // must be 0 after call finishes

            let requestsPerRPC = try #require(metricsFactory.recorders.first(where: { $0.label == "rpc.client.requests_per_rpc" }))
            self.checkCommonDimensions(requestsPerRPC.dimensions)
            #expect(requestsPerRPC.values.reduce(0, +) == 1)

            let responsesPerRPC = try #require(metricsFactory.recorders.first(where: { $0.label == "rpc.client.responses_per_rpc" }))
            self.checkCommonDimensions(responsesPerRPC.dimensions)
            #expect(responsesPerRPC.values == [])  // empty values, as error is thrown in response

            let calls = try #require(metricsFactory.counters.first(where: { $0.label == "rpc.client.calls" }))
            self.checkCommonDimensions(calls.dimensions, count: 6)
            #expect(
                calls.dimensions.first(where: { $0.0 == "rpc.grpc.status_code" })?.1
                    == RPCError(code: .unavailable, message: "").code.rawValue.description
            )
            #expect(calls.lastValue == 1)

            let duration = try #require(metricsFactory.timers.first(where: { $0.label == "rpc.client.duration" }))
            self.checkCommonDimensions(duration.dimensions, count: 6)
            #expect(
                calls.dimensions.first(where: { $0.0 == "rpc.grpc.status_code" })?.1
                    == RPCError(code: .unavailable, message: "").code.rawValue.description
            )
            let lastDurationValueNanoSeconds = try #require(duration.lastValue)
            let lastDurationValue = Double(lastDurationValueNanoSeconds) / 1_000_000_000
            #expect(0 < lastDurationValue && lastDurationValue < 1)  // between 0 and 1 sec

            let errors = try #require(metricsFactory.counters.first(where: { $0.label == "rpc.client.request.errors" }))
            self.checkCommonDimensions(errors.dimensions, count: 6)
            #expect(
                errors.dimensions.first(where: { $0.0 == "rpc.grpc.status_code" })?.1
                    == RPCError(code: .unavailable, message: "").code.rawValue.description
            )
            #expect(errors.lastValue == 1)
        }
    }

    @Test
    func interceptorCountsMessagesCorrectly() async throws {
        let metricsFactory = TestMetricsFactory()
        let interceptor = ClientOTelMetricsInterceptor(
            serverHostname: "test-server",
            networkTransportMethod: .tcp,
            metricsFactory: metricsFactory
        )
        let (_, requestStreamContinuation) = AsyncStream<String>.makeStream()

        let request = StreamingClientRequest<String> { writer in
            // write multiple requests
            try await writer.write("test-message-1")
            try await writer.write("test-message-2")
            try await writer.write("test-message-3")
        }

        let responseContent = StreamingClientResponse<String>(
            accepted: .success(
                .init(
                    metadata: [],
                    bodyParts: RPCAsyncSequence(
                        wrapping: AsyncThrowingStream<StreamingClientResponse.Contents.BodyPart, any Error> {
                            // write multiple responses
                            $0.yield(.message("response-message-1"))
                            $0.yield(.message("response-message-2"))
                            $0.finish()
                        }
                    )
                )
            )
        )

        let next: (StreamingClientRequest<String>, ClientContext) async throws -> StreamingClientResponse<String> = { request, _ in
            // Make sure the `producer` closure's which includes instrumentation is called.
            let writer = RPCWriter(wrapping: TestWriter(streamContinuation: requestStreamContinuation))
            try await request.producer(writer)
            requestStreamContinuation.finish()

            let activeRequests = try #require(metricsFactory.meters.first(where: { $0.label == "rpc.client.active_requests" }))
            self.checkCommonDimensions(activeRequests.dimensions)
            #expect(activeRequests.lastValue == 1)

            return responseContent
        }

        // Execute the interceptor
        let response = try await interceptor.intercept(
            request: request,
            context: ClientContext(descriptor: .init(fullyQualifiedService: "test-service", method: "test-method"), remotePeer: "", localPeer: ""),
            next: next
        )

        // Consume the response to trigger the hooks
        if case let .success(contents) = response.accepted {
            for try await _ in contents.bodyParts {}
        }

        let activeRequests = try #require(metricsFactory.meters.first(where: { $0.label == "rpc.client.active_requests" }))
        self.checkCommonDimensions(activeRequests.dimensions)
        #expect(activeRequests.lastValue == 0)  // must be 0 after call finishes

        let requestsPerRPC = try #require(metricsFactory.recorders.first(where: { $0.label == "rpc.client.requests_per_rpc" }))
        self.checkCommonDimensions(requestsPerRPC.dimensions)
        #expect(requestsPerRPC.values.reduce(0, +) == 3)  // 3 requests

        let responsesPerRPC = try #require(metricsFactory.recorders.first(where: { $0.label == "rpc.client.responses_per_rpc" }))
        self.checkCommonDimensions(responsesPerRPC.dimensions)
        #expect(responsesPerRPC.values.reduce(0, +) == 2)  // 2 requests

        let calls = try #require(metricsFactory.counters.first(where: { $0.label == "rpc.client.calls" }))
        self.checkCommonDimensions(calls.dimensions, count: 6)
        #expect(calls.dimensions.first(where: { $0.0 == "rpc.grpc.status_code" })?.1 == "0")
        #expect(calls.values.reduce(0, +) == 1)

        let duration = try #require(metricsFactory.timers.first(where: { $0.label == "rpc.client.duration" }))
        self.checkCommonDimensions(duration.dimensions, count: 6)
        #expect(
            calls.dimensions.first(where: { $0.0 == "rpc.grpc.status_code" })?.1 == GRPCCore.Status(code: .ok, message: "").code.rawValue.description
        )
        let lastDurationValueNanoSeconds = try #require(duration.lastValue)
        let lastDurationValue = Double(lastDurationValueNanoSeconds) / 1_000_000_000
        #expect(0 < lastDurationValue && lastDurationValue < 1)  // between 0 and 1 sec

        #expect(metricsFactory.counters.first(where: { $0.label == "rpc.client.request.errors" }) == nil)  // no thrown errors
    }

    private func checkCommonDimensions(_ dimensions: [(String, String)]?, count: Int = 5) {
        #expect(dimensions?.count == count)
        #expect(dimensions?.first(where: { $0.0 == "rpc.system" })?.1 == "grpc")
        #expect(dimensions?.first(where: { $0.0 == "server.address" })?.1 == "test-server")
        #expect(dimensions?.first(where: { $0.0 == "network.transport" })?.1 == "tcp")
        #expect(dimensions?.first(where: { $0.0 == "rpc.service" })?.1 == "test-service")
        #expect(dimensions?.first(where: { $0.0 == "rpc.method" })?.1 == "test-method")
    }
}
