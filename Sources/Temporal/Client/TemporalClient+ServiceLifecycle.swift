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
import ServiceLifecycle

extension TemporalClient: Service {
    /// Creates a new Temporal client with manual lifecycle management for long-running services.
    ///
    /// This initializer creates a Temporal client that can be managed as a service within a larger
    /// application lifecycle. Unlike the ``connect(transport:configuration:isolation:logger:_:)`` method
    /// which provides automatic lifecycle management, this initializer requires manual management of
    /// the client's lifecycle through the  `Service` protocol methods.
    ///
    /// - Important: Simply instantiating the client is not sufficient to perform requests.
    ///   You must call ``run()`` and manage the lifecycle properly for the client to function.
    ///
    /// - Parameters:
    ///   - transport: The transport used to establish communication with the Temporal server.
    ///   - configuration: The client configuration including interceptors and connection settings.
    ///   - logger: The logger instance for client operations. Defaults to a no-op logger.
    public convenience init<Transport: ClientTransport>(
        transport: Transport,
        configuration: TemporalClient.Configuration,
        logger: Logger = Logger(label: "NoOpLogger", factory: { _ in SwiftLogNoOpLogHandler() })
    ) {
        let grpcClient = GRPCClient(
            transport: transport,
            interceptors: Self.grpcClientInterceptors(serverHostname: configuration.instrumentation.serverHostname, logger: logger)
        )

        self.init(client: grpcClient, configuration: configuration)
    }

    /// Starts the Temporal client and keeps it running until shutdown is initiated.
    ///
    /// This method starts the underlying gRPC client and keeps it running to handle requests.
    ///
    /// - Throws: A runtime error if the client cannot be started or is in an invalid state.
    public func run() async throws {
        // Graceful shutdown is handled by `GRPCServiceLifecycle`
        try await self.workflowService.client.client.run()
    }

    /// Initiates graceful shutdown of the Temporal client.
    public func beginGracefulShutdown() {
        self.workflowService.client.client.beginGracefulShutdown()
    }
}
