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

import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2Posix
import Logging
import NIOPosix
import ServiceLifecycle
import SwiftASN1
import Temporal
import TemporalTestKit
import Testing
import X509

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct ClientTests {
        @Test(
            .enabled(if: TestData.certificateChain != nil && TestData.privateKey != nil)  // only works in CI
        )
        func connectWithMTLS() async throws {
            guard let certificateChain = TestData.certificateChain, let privateKey = TestData.privateKey else {
                preconditionFailure("mTLS certs for remote Temporal cluster connection could not be found.")
            }

            try await TemporalClient.connect(
                transport: .http2NIOPosix(
                    target: .dns(host: "example.temporal.com", port: 7233),  // TODO: Renable
                    transportSecurity: .mTLS(
                        certificateChain: certificateChain.map { chain in
                            .bytes(
                                {
                                    guard let bytes = try? chain.serializeAsPEM().derBytes else {
                                        preconditionFailure("Certificate chain serialization failed. Check that the certificate chain is valid.")
                                    }

                                    return bytes
                                }(),
                                format: .der
                            )
                        },
                        privateKey: .bytes(
                            {
                                guard let bytes = try? privateKey.serializeAsPEM().derBytes else {
                                    preconditionFailure("Private key serialization failed. Check that the key is valid.")
                                }

                                return bytes
                            }(),
                            format: .der
                        )
                    ),
                    config: .defaults,
                    resolverRegistry: .defaults,
                    serviceConfig: .init(),
                    eventLoopGroup: .singletonMultiThreadedEventLoopGroup
                ),
                configuration: .init(
                    instrumentation: .init(serverHostname: "example.temporal.com"),
                    namespace: "TemporalDemo"
                )
            ) { _ in
                // No op. If we get here we were able to connect.
                // Sleep required because of grpc-swift bug: https://github.com/grpc/grpc-swift/issues/2214
                try await Task.sleep(for: .milliseconds(100))
            }
        }

        @Test
        func connectTestServer() async throws {
            let logger = Logger(label: "TestLogger")
            try await TemporalTestServer.testServer!.withConnectedClient(logger: logger) { _ in
                // No op. If we get here we were able to connect.
                // Sleep required because of grpc-swift bug: https://github.com/grpc/grpc-swift/issues/2214
                try await Task.sleep(for: .milliseconds(100))
            }
        }

        @Test
        func connectTimeSkippingTestServer() async throws {
            let logger = Logger(label: "TestLogger")
            try await TemporalTestServer.timeSkippingTestServer!.withConnectedClient(logger: logger) { _ in
                // No op. If we get here we were able to connect.
                // Sleep required because of grpc-swift bug: https://github.com/grpc/grpc-swift/issues/2214
                try await Task.sleep(for: .milliseconds(100))
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func serviceForceShutdown() async throws {
            try await TemporalTestServer.withTestServer { server in
                let (host, port) = server.hostAndPort()

                let task = Task {
                    let client = try TemporalClient(
                        transport: .http2NIOPosix(
                            target: .dns(host: host, port: port),
                            transportSecurity: .plaintext,  // plaintext transport for testing
                            config: .defaults,
                            resolverRegistry: .defaults,
                            serviceConfig: .init(),
                            eventLoopGroup: .singletonMultiThreadedEventLoopGroup
                        ),
                        configuration: .init(
                            instrumentation: .init(serverHostname: host),
                            interceptors: []
                        ),
                        logger: Logger(label: "TestLogger")
                    )

                    try await client.run()
                }

                // Wait until connection is established
                try await Task.sleep(for: .milliseconds(100))

                // Force shutdown
                task.cancel()

                // If connection is established, this should not throw an error upon returning (`CancellationError` is not propagated by `GRPCClient`)
                try await task.value
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func serviceGracefulShutdown() async throws {
            try await TemporalTestServer.withTestServer { server in
                let (host, port) = server.hostAndPort()
                let client = try TemporalClient(
                    transport: .http2NIOPosix(
                        target: .dns(host: host, port: port),
                        transportSecurity: .plaintext,  // plaintext transport for testing
                        config: .defaults,
                        resolverRegistry: .defaults,
                        serviceConfig: .init(),
                        eventLoopGroup: .singletonMultiThreadedEventLoopGroup
                    ),
                    configuration: .init(
                        instrumentation: .init(serverHostname: host),
                        interceptors: []
                    ),
                    logger: Logger(label: "TestLogger")
                )

                let task = Task {
                    try await client.run()
                }

                // Sleep required because of grpc-swift internal state handling: https://github.com/grpc/grpc-swift/issues/2214
                try await Task.sleep(for: .milliseconds(100))

                // Start graceful shutdown
                client.beginGracefulShutdown()

                // If connection is established, this should not throw an error upon returning
                try await task.value
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func serviceGroupGracefulShutdown() async throws {
            try await TemporalTestServer.withTestServer { server in
                let (host, port) = server.hostAndPort()
                let client = try TemporalClient(
                    transport: .http2NIOPosix(
                        target: .dns(host: host, port: port),
                        transportSecurity: .plaintext,  // plaintext transport for testing
                        config: .defaults,
                        resolverRegistry: .defaults,
                        serviceConfig: .init(),
                        eventLoopGroup: .singletonMultiThreadedEventLoopGroup
                    ),
                    configuration: .init(
                        instrumentation: .init(serverHostname: host),
                        interceptors: []
                    ),
                    logger: Logger(label: "TestLogger")
                )
                let serviceGroup = ServiceGroup(
                    services: [client],
                    logger: Logger(label: "TestLogger")
                )

                try await withThrowingTaskGroup { group in
                    group.addTask {
                        try await serviceGroup.run()
                    }

                    // Sleep required because of grpc-swift internal state handling: https://github.com/grpc/grpc-swift/issues/2214
                    try await Task.sleep(for: .milliseconds(100))

                    // Start graceful shutdown of the service group
                    await serviceGroup.triggerGracefulShutdown()

                    // If connection is established, this should not throw an error upon returning
                    try await group.waitForAll()
                }
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func serviceGroupForceShutdown() async throws {
            try await TemporalTestServer.withTestServer { server in
                let (host, port) = server.hostAndPort()
                let client = try TemporalClient(
                    transport: .http2NIOPosix(
                        target: .dns(host: host, port: port),
                        transportSecurity: .plaintext,  // plaintext transport for testing
                        config: .defaults,
                        resolverRegistry: .defaults,
                        serviceConfig: .init(),
                        eventLoopGroup: .singletonMultiThreadedEventLoopGroup
                    ),
                    configuration: .init(
                        instrumentation: .init(serverHostname: host),
                        interceptors: []
                    ),
                    logger: Logger(label: "TestLogger")
                )
                let serviceGroup = ServiceGroup(
                    services: [client],
                    logger: Logger(label: "TestLogger")
                )

                try await withThrowingTaskGroup { group in
                    group.addTask {
                        try await serviceGroup.run()
                    }

                    // Wait until connection is established
                    try await Task.sleep(for: .milliseconds(100))

                    // Force shutdown by cancelling task group
                    group.cancelAll()

                    // If connection is established, this should not throw an error upon returning
                    try await group.waitForAll()
                }
            }
        }
    }
}
