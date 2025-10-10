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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A client that manages connections and communication with a Temporal cluster.
///
/// ``TemporalClient`` provides the primary interface for interacting with Temporal's workflow orchestration platform.
/// It automatically handles retries with endpoint-specific configurations, including maximum timeouts and backoff strategies.
///
/// ## Overview
///
/// The client encapsulates three main service interfaces:
/// - ``workflowService`` for workflow lifecycle operations
/// - ``namespaceService`` for namespace management
/// - ``operatorService`` for cluster administration
///
/// ## Creating a client
///
/// Use the ``connect(transport:configuration:isolation:logger:_:)`` method for a lifetime-scoped client:
///
/// ```swift
/// let configuration = TemporalClient.Configuration(
///     target: .dns(host: "localhost", port: 7233),
///     namespace: "default"
/// )
///
/// try await TemporalClient.connect(
///     transport: HTTP2ClientTransport.Posix(
///         target: configuration.target,
///         transportSecurity: .plaintext
///     ),
///     configuration: configuration
/// ) { client in
///     // Use the client
///     return try await client.startWorkflow(...)
/// }
/// ```
///
/// ## Retry Behavior
///
/// The client automatically retries failed requests based on gRPC status codes and configured retry policies.
/// Each service operation has specific retry configurations including exponential backoff and maximum attempt limits.
/// By default, the maximum retry count is 5 attempts, providing a balance between reliability and performance.
public final class TemporalClient: Sendable {
    /// The workflow service client that handles workflow operations and lifecycle management.
    ///
    /// Provides access to workflow execution, querying, signaling, and other workflow-related operations.
    public let workflowService: WorkflowService

    /// The namespace service client that manages namespace operations and configuration.
    ///
    /// Enables namespace creation, updates, listing, and configuration management within the Temporal cluster.
    public let namespaceService: NamespaceService

    /// The operator service client that provides cluster administration and search attribute operations.
    ///
    /// Offers administrative functions including search attribute management and cluster-level operations.
    public let operatorService: OperatorService

    /// The intercepted service client that routes its operations through the configured ``Configuration/interceptors`` chain.
    ///
    /// Offers high-level functionalities that are performed through the configured ``ClientOutboundInterceptor``s
    /// while avoiding ``WorkflowHandle`` / ``WorkflowUpdateHandle`` (or its untyped equivalents
    /// ``UntypedWorkflowHandle`` / ``UntypedWorkflowUpdateHandle``).
    package let interceptedService: InterceptedService

    /// The client outbound interceptor chain.
    let interceptor: Interceptor

    /// The configuration settings that define the client's behavior and connection parameters.
    package var configuration: TemporalClient.Configuration {
        self.workflowService.configuration
    }

    /// Creates a new Temporal client with the specified gRPC client and configuration.
    ///
    /// - Parameters:
    ///   - client: The gRPC client used for network communication.
    ///   - configuration: The configuration settings for the Temporal client.
    package init<Transport: ClientTransport>(
        client: GRPCClient<Transport>,
        configuration: TemporalClient.Configuration
    ) {
        // sadly we cannot set this directly on the gRPC workflow client
        var metadata: GRPCCore.Metadata = [:]
        metadata.addString(configuration.clientName, forKey: "client-name")
        metadata.addString(configuration.clientVersion, forKey: "client-version")

        // Add API key authentication if provided
        if let apiKey = configuration.apiKey {
            metadata.addString("Bearer \(apiKey)", forKey: "authorization")
        }

        // type-erasure of `GRPCClient`
        let configuredClient = ConfiguredClient(
            client: client,
            metadata: metadata
        )

        self.workflowService = .init(
            client: configuredClient,
            configuration: configuration,
            metadata: metadata
        )
        self.operatorService = .init(
            client: configuredClient,
            configuration: configuration,
            metadata: metadata
        )
        self.namespaceService = .init(
            client: configuredClient,
            configuration: configuration,
            metadata: metadata
        )

        self.interceptor = Interceptor(
            workflowService: self.workflowService,
            interceptors: configuration
                .interceptors
                .compactMap { $0.makeClientOutboundInterceptor() }
        )

        self.interceptedService = .init(
            interceptor: self.interceptor
        )
    }

    // MARK: Connect

    /// Creates and manages a lifetime-scoped Temporal client that executes the provided closure.
    ///
    /// - Note: grpc-swift’s `ClientTransport` provides an option to configure an additional retry *throttling* policy via `ClientTransport/retryThrottle`, applicable to all retryable status codes.
    /// This throttling mechanism works in conjunction with the retry logic implemented in ``TemporalClient`` and can help reduce server load during periods of high request failure rates.
    ///
    /// The Temporal Rust SDK uses retry throttling specifically for the `RESOURCE_EXHAUSTED` status code, but the Swift implementation applies throttling uniformly across all retryable status codes.
    /// Note that users are not expected to configure a custom retry throttle in most cases, as the ``TemporalClient``already applies a conservative retry attempt count (max is 5), in contrast to the potentially unlimited retries in the Rust SDK.
    ///
    /// - Note: The tracing of the ``TemporalClient`` via ``TemporalClientTracingInterceptor`` is enabled by default, overwrite ``TemporalClient/Configuration-swift.struct/interceptors`` to disable.
    ///
    /// - Parameters:
    ///   - transport: The transport layer that should be used by the gRPC connection of the ``TemporalClient``.
    ///   - configuration: The configuration of the ``TemporalClient``.
    ///   - isolation: The isolation domain of the caller.
    ///   - logger: The logger used in the ``TemporalClient``.
    ///   - body: A closure which is called with the ``TemporalClient``. When the closure returns, the ``TemporalClient`` is shutdown gracefully.
    /// - Returns: The result of the passed closure.
    public static func connect<Transport: ClientTransport, Result: Sendable>(
        transport: Transport,
        configuration: TemporalClient.Configuration,
        isolation: isolated (any Actor)? = #isolation,
        logger: Logger = Logger(label: "NoOpLogger", factory: { _ in SwiftLogNoOpLogHandler() }),
        _ body: (TemporalClient) async throws -> sending Result
    ) async throws -> sending Result {
        try await withGRPCClient(
            transport: transport,
            interceptors: Self.grpcClientInterceptors(serverHostname: configuration.instrumentation.serverHostname, logger: logger),
            isolation: isolation
        ) { client in
            let temporalClient = Self.init(client: client, configuration: configuration)
            return try await body(temporalClient)
        }
    }
}

#if GRPCNIOTransport
import GRPCNIOTransportCore
import GRPCNIOTransportHTTP2Posix

extension TemporalClient {
    /// Creates a new Temporal client with NIO-based HTTP/2 transport.
    ///
    /// This convenience initializer creates a client using the NIO-based HTTP/2 transport implementation.
    /// For automatic lifecycle management, prefer using the static ``connect(transport:configuration:isolation:logger:_:)``
    /// method instead of this initializer.
    ///
    /// The initializer configures an HTTP/2 transport with the specified target and security settings,
    /// then creates the Temporal client with that transport.
    ///
    /// - Parameters:
    ///   - target: The target endpoint for the Temporal server (host and port).
    ///   - transportSecurity: The security configuration for the transport layer (TLS settings).
    ///   - configuration: The client configuration including namespace and retry policies.
    ///   - logger: The logger instance for client operations.
    /// - Throws: An error if the transport cannot be configured or the client cannot be initialized.
    public convenience init(
        target: any ResolvableTarget,
        transportSecurity: HTTP2ClientTransport.Posix.TransportSecurity,
        configuration: TemporalClient.Configuration,
        logger: Logger
    ) throws {
        try self.init(
            transport:
                HTTP2ClientTransport
                .Posix(
                    target: target,
                    transportSecurity: transportSecurity
                ),
            configuration: configuration,
            logger: logger
        )
    }
}
#endif
