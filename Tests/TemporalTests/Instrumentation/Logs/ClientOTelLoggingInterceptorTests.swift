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
import Synchronization
import Temporal
import TemporalInstrumentation
import TemporalTestKit
import Testing
import Tracing

@Suite(.tags(.instrumentationTests))
struct ClientOTelLoggingInterceptorTests {
    @Test
    func loggingClientInterceptorNew() async throws {
        // in-memory log handler
        let logHandler = InMemoryLogHandler(
            metadataProvider: .init {
                [
                    // Fake log correlation via traceId and spanId
                    "trace_id": "1234",
                    "span_id": "5678",
                ]
            }
        )

        let logger = Logger(label: "ClientGRPCInterceptor") { _ in logHandler }

        let serviceName = "ClientOTelLoggingInterceptorTest"
        let serverHostname = "test.com"
        let transport: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum = .tcp
        let descriptor = MethodDescriptor(fullyQualifiedService: serviceName, method: "TestMethod")
        let remotePeer = "ipv4:123.45.67.89:1234"
        let localPeer = "ipv4:145.32.54.12:4321"

        let interceptor = ClientOTelLoggingInterceptor(
            logger: logger,
            serverHostname: serverHostname,
            networkTransportMethod: transport,
            includeRequestMetadata: true,
            includeResponseMetadata: true
        )

        let request = StreamingClientRequest<String> { writer in
            try await writer.write("test-message")
        }
        let context = ClientContext(
            descriptor: descriptor,
            remotePeer: remotePeer,
            localPeer: localPeer
        )
        let next: (StreamingClientRequest<String>, ClientContext) async throws -> StreamingClientResponse<String> = { request, _ in
            var metadata = GRPCCore.Metadata()
            metadata.addString("test-value", forKey: "test-key")

            return StreamingClientResponse<String>(
                accepted: .success(
                    .init(
                        metadata: metadata,
                        bodyParts: RPCAsyncSequence(
                            wrapping: AsyncThrowingStream<StreamingClientResponse.Contents.BodyPart, any Error> {
                                $0.yield(.message("response-message"))
                                $0.finish()
                            }
                        )
                    )
                )
            )
        }

        let response = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )

        guard case .success = response.accepted else {
            Issue.record("Should have been successful")
            return
        }

        try logHandler.entries.withLock { entries in
            // Exactly two log entries should exist
            #expect(entries.count == 2)

            // First "invoke RPC" log
            let log1 = try #require(entries.first)

            #expect(log1.level == .trace)
            #expect(log1.source == "TemporalInstrumentation")
            #expect(log1.message == "Invoking RPC")

            // check association with trace and span id
            let traceId = try #require(log1.metadata?["trace_id"])
            #expect(traceId == "1234")
            let spanId = try #require(log1.metadata?["span_id"])
            #expect(spanId == "5678")

            // rpc metadata
            let rpcSystem = try #require(log1.metadata?["rpc.system"])
            #expect(rpcSystem == "grpc")
            let rpcServiceName = try #require(log1.metadata?["rpc.service"])
            #expect(rpcServiceName == .string(descriptor.service.fullyQualifiedService))
            let rpcMethodName = try #require(log1.metadata?["rpc.method"])
            #expect(rpcMethodName == .string(descriptor.method))

            // network metadata
            let type = try #require(log1.metadata?["network.type"])
            #expect(type == "ipv4")
            let transport = try #require(log1.metadata?["network.transport"])
            #expect(transport == .string(transport.description))
            let networkLocalAddress = try #require(log1.metadata?["network.local.address"])
            #expect(networkLocalAddress == .string(String(localPeer.split(separator: ":").dropFirst().first!)))
            let networkLocalPort = try #require(log1.metadata?["network.local.port"])
            #expect(networkLocalPort == .string(String(localPeer.split(separator: ":").dropFirst().dropFirst().first!)))
            let networkRemoteAddress = try #require(log1.metadata?["network.peer.address"])
            #expect(networkRemoteAddress == .string(String(remotePeer.split(separator: ":").dropFirst().first!)))
            let networkRemotePort = try #require(log1.metadata?["network.peer.port"])
            #expect(networkRemotePort == .string(String(remotePeer.split(separator: ":").dropFirst().dropFirst().first!)))
            let serverAddress = try #require(log1.metadata?["server.address"])
            #expect(serverAddress == serverAddress)
            let serverPort = try #require(log1.metadata?["server.port"])
            #expect(serverPort == .string(String(remotePeer.split(separator: ":").dropFirst().dropFirst().first!)))

            // Second "accept RPC" log
            let log2 = try #require(entries.dropFirst().first)
            #expect(log2.message == "Accepted RPC")
            #expect(log2.level == .trace)

            // only check if the second log contains all metadata from the first log
            let metadataKeys1 = try #require(log1.metadata?.keys)
            let metadataKeys2 = try #require(log2.metadata?.keys)
            #expect(Set(metadataKeys2).isSuperset(of: Set(metadataKeys1)))
            // check additional response header
            let responseHeader = try #require(log2.metadata?["rpc.grpc.response.metadata.test-key"])
            #expect(responseHeader == "test-value")
        }
    }

    @Test
    func loggingClientInterceptorFailure() async throws {
        // in-memory log handler
        let logHandler = InMemoryLogHandler(
            metadataProvider: .init {
                [
                    // Fake log correlation via traceId and spanId
                    "trace_id": "1234",
                    "span_id": "5678",
                ]
            }
        )

        let logger = Logger(label: "ClientGRPCInterceptor") { _ in logHandler }

        let serviceName = "ClientOTelLoggingInterceptorTest"
        let descriptor = MethodDescriptor(fullyQualifiedService: serviceName, method: "TestMethod")

        let interceptor = ClientOTelLoggingInterceptor(
            logger: logger,
            serverHostname: "test.com",
            networkTransportMethod: .tcp,
            includeRequestMetadata: true,
            includeResponseMetadata: true
        )

        let request = StreamingClientRequest<String> { writer in
            try await writer.write("test-message")
        }
        let next: (StreamingClientRequest<String>, ClientContext) async throws -> StreamingClientResponse<String> = { request, _ in
            var metadata = GRPCCore.Metadata()
            metadata.addString("test-value-error", forKey: "test-key-error")

            return StreamingClientResponse(
                accepted: .failure(
                    .init(
                        code: .aborted,
                        message: "Test failure",
                        metadata: metadata,
                        cause: TestError()
                    )
                )
            )
        }

        let response = try await interceptor.intercept(
            request: request,
            context: ClientContext(descriptor: descriptor, remotePeer: "", localPeer: ""),
            next: next
        )

        guard case .failure = response.accepted else {
            Issue.record("Should have failed")
            return
        }

        try logHandler.entries.withLock { entries in
            // Exactly two log entries should exist
            #expect(entries.count == 2)

            // First "invoke RPC" log
            let log1 = try #require(entries.first)

            #expect(log1.level == .trace)
            #expect(log1.source == "TemporalInstrumentation")
            #expect(log1.message == "Invoking RPC")

            // check association with trace and span id
            let traceId = try #require(log1.metadata?["trace_id"])
            #expect(traceId == "1234")
            let spanId = try #require(log1.metadata?["span_id"])
            #expect(spanId == "5678")

            // rpc metadata
            let rpcSystem = try #require(log1.metadata?["rpc.system"])
            #expect(rpcSystem == "grpc")
            let rpcServiceName = try #require(log1.metadata?["rpc.service"])
            #expect(rpcServiceName == .string(descriptor.service.fullyQualifiedService))
            let rpcMethodName = try #require(log1.metadata?["rpc.method"])
            #expect(rpcMethodName == .string(descriptor.method))

            // Second "rejected RPC" log
            let log2 = try #require(entries.dropFirst().first)
            #expect(log2.message == "Rejected RPC")
            #expect(log2.level == .info)  // info level for failure, except cancellation error

            // error descriptions
            let grpcStatusCode = try #require(log2.metadata?["rpc.grpc.status_code"])
            #expect(grpcStatusCode == .string(GRPCCore.Status.Code.aborted.description))
            let exceptionType = try #require(log2.metadata?["exception.type"])
            #expect(exceptionType == "RPCError")
            let exceptionMessage = try #require(log2.metadata?["exception.message"])
            #expect(exceptionMessage == "Test failure")
            let exceptionStacktrace = try #require(log2.metadata?["exception.stacktrace"])
            #expect(exceptionStacktrace == "TestError()")
            let metadata = try #require(log2.metadata?["rpc.grpc.response.metadata.test-key-error"])
            #expect(metadata == "test-value-error")
        }
    }
}
