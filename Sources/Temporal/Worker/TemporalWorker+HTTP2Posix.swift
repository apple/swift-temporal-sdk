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

#if GRPCNIOTransport
import GRPCNIOTransportCore
import GRPCNIOTransportHTTP2Posix
import Logging

extension TemporalWorker {
    /// Creates a Temporal worker with HTTP/2 NIO transport configuration.
    ///
    /// This convenience initializer creates an HTTP/2 transport using NIO and the specified target and
    /// security settings.
    ///
    /// - Parameters:
    ///   - configuration: The worker configuration including namespace, task queue, and
    ///   operational settings.
    ///   - target: The target server address to resolve for the Temporal server connection.
    ///   - transportSecurity: The configuration for securing network traffic (TLS, plaintext, etc.).
    ///   - activityContainers: One or more containers that provide activity implementations for
    ///   registration.
    ///   - activities: Additional standalone activity definitions to register alongside container
    ///   activities.
    ///   - workflows: The workflow types to register with this worker for task processing.
    ///   - logger: The logger instance used for diagnostic and debugging output.
    /// - Throws: Transport configuration errors if the HTTP/2 transport cannot be created.
    public convenience init<each Container: ActivityContainer>(
        configuration: Configuration,
        target: any ResolvableTarget,
        transportSecurity: HTTP2ClientTransport.Posix.TransportSecurity,
        activityContainers: repeat each Container,
        activities: [any ActivityDefinition] = [],
        workflows: [any WorkflowDefinition.Type] = [],
        logger: Logger
    ) throws {
        self.init(
            configuration: configuration,
            transport: try .http2NIOPosix(
                target: target,
                transportSecurity: transportSecurity
            ),
            activityContainers: repeat each activityContainers,
            activities: activities,
            workflows: workflows,
            logger: logger
        )
    }
}
#endif
