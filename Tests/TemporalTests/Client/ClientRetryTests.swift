//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import GRPCCore
import GRPCInProcessTransport
import GRPCProtobuf
import Synchronization
import Temporal
import Testing

/// Retries of failures the server sends after response headers.
///
/// The Temporal server sends response headers before failing with `RESOURCE_EXHAUSTED`, so
/// grpc-swift treats the RPC as committed and won't retry it. The test server fails the same way.
@Suite(.tags(.clientTests))
struct ClientRetryTests {
    @Test
    func retriesResourceExhaustedSentAfterResponseHeaders() async throws {
        // Given
        let service = FailingCancelService(failures: 2, code: .resourceExhausted)

        // When
        try await withClient(serving: service) { client in
            try await client.untypedWorkflowHandle(id: "workflow").cancel()
        }

        // Then
        #expect(service.attempts == 3)
    }

    @Test
    func retriesResourceExhaustedSentWithoutResponseHeaders() async throws {
        // Given
        let service = FailingCancelService(failures: 2, code: .resourceExhausted, sendsHeaders: false)

        // When
        try await withClient(serving: service) { client in
            try await client.untypedWorkflowHandle(id: "workflow").cancel()
        }

        // Then
        #expect(service.attempts == 3)
    }

    @Test
    func givesUpOnResourceExhaustedAfterMaxAttempts() async throws {
        // Given
        let service = FailingCancelService(failures: .max, code: .resourceExhausted)

        // When
        let error = await #expect(throws: RPCError.self) {
            try await withClient(serving: service) { client in
                try await client.untypedWorkflowHandle(id: "workflow").cancel(callOptions: .fastRetry)
            }
        }

        // Then
        #expect(error?.code == .resourceExhausted)
        #expect(service.attempts == 5)
    }

    @Test
    func doesNotRetryNonRetryableCodeSentAfterResponseHeaders() async throws {
        // Given
        let service = FailingCancelService(failures: .max, code: .invalidArgument)

        // When
        let error = await #expect(throws: RPCError.self) {
            try await withClient(serving: service) { client in
                try await client.untypedWorkflowHandle(id: "workflow").cancel(callOptions: .fastRetry)
            }
        }

        // Then
        #expect(error?.code == .invalidArgument)
        #expect(service.attempts == 1)
    }

    @Test
    func doesNotRetryWithoutRetryPolicy() async throws {
        // Given
        let service = FailingCancelService(failures: .max, code: .resourceExhausted)

        // When
        await #expect(throws: RPCError.self) {
            try await withClient(serving: service) { client in
                try await client.untypedWorkflowHandle(id: "workflow").cancel(callOptions: .defaults)
            }
        }

        // Then
        #expect(service.attempts == 1)
    }

    private func withClient(
        serving service: FailingCancelService,
        _ body: (TemporalClient) async throws -> Void
    ) async throws {
        let transport = InProcessTransport()
        try await withGRPCServer(transport: transport.server, services: [service]) { _ in
            try await TemporalClient.connect(
                transport: transport.client,
                configuration: .init(
                    instrumentation: .init(serverHostname: "localhost"),
                    interceptors: []
                )
            ) { client in
                try await body(client)
            }
        }
    }
}

extension CallOptions {
    /// Short backoffs, so tests that run out of attempts finish quickly.
    fileprivate static var fastRetry: Self {
        var callOptions = Self.defaults
        callOptions.executionPolicy = .retry(
            .init(
                maxAttempts: 5,
                initialBackoff: .milliseconds(1),
                maxBackoff: .milliseconds(10),
                backoffMultiplier: 2,
                retryableStatusCodes: [.resourceExhausted, .unavailable]
            )
        )
        callOptions.timeout = .seconds(10)
        return callOptions
    }
}

/// Serves `RequestCancelWorkflowExecution` and fails the first `failures` attempts with `code`.
///
/// Fails after sending headers, like the Temporal server. With `sendsHeaders: false` it fails
/// with a trailers-only response instead, which grpc-swift retries on its own.
private final class FailingCancelService: RegistrableRPCService, Sendable {
    private let failures: Int
    private let code: RPCError.Code
    private let sendsHeaders: Bool
    private let attemptCount = Mutex(0)

    var attempts: Int {
        self.attemptCount.withLock { $0 }
    }

    init(failures: Int, code: RPCError.Code, sendsHeaders: Bool = true) {
        self.failures = failures
        self.code = code
        self.sendsHeaders = sendsHeaders
    }

    func registerMethods<Transport: ServerTransport>(with router: inout RPCRouter<Transport>) {
        router.registerHandler(
            forMethod: Api.Workflowservice.V1.WorkflowService.Method.RequestCancelWorkflowExecution.descriptor,
            deserializer: ProtobufDeserializer<Api.Workflowservice.V1.RequestCancelWorkflowExecutionRequest>(),
            serializer: ProtobufSerializer<Api.Workflowservice.V1.RequestCancelWorkflowExecutionResponse>()
        ) { request, _ in
            for try await _ in request.messages {}
            let attempt = self.attemptCount.withLock { count in
                count += 1
                return count
            }

            if attempt <= self.failures {
                let code = self.code
                guard self.sendsHeaders else {
                    return StreamingServerResponse(error: RPCError(code: code, message: "attempt \(attempt) failed"))
                }
                return StreamingServerResponse(
                    metadata: ["x-resource-exhausted-cause": "RpsLimit"]
                ) { _ in
                    throw RPCError(code: code, message: "attempt \(attempt) failed")
                }
            }
            return StreamingServerResponse(
                single: ServerResponse(message: Api.Workflowservice.V1.RequestCancelWorkflowExecutionResponse())
            )
        }
    }
}
