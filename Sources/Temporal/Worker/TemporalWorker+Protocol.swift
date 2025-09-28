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
import Logging
import ServiceLifecycle

/// Defines the requirements for creating and running a Temporal worker.
///
/// A worker polls a Temporal task queue and executes the registered
/// activities and workflows using the provided transport and configuration.
package protocol TemporalWorkerProtocol: Service, Sendable {
    /// Create a new Temporal worker.
    ///
    /// - Parameters:
    ///   - configuration: Worker configuration including namespace and task queue.
    ///   - transport: The transport used to communicate with the Temporal service.
    ///   - activities: Activities to register with the worker.
    ///   - workflows: Workflows to register with the worker.
    ///   - logger: Logger for diagnostic output.
    init<Transport: ClientTransport>(
        for configuration: TemporalWorker.Configuration,
        transport: Transport,
        activities: [any ActivityDefinition],
        workflows: [any WorkflowDefinition.Type],
        logger: Logger
    )

    /// Run the worker with a specific runtime.
    ///
    /// - Parameter bridgeRuntime: The runtime to initialize the worker with.
    func run(bridgeRuntime: BridgeRuntime) async throws
}

extension TemporalWorker: TemporalWorkerProtocol {
    package convenience init<Transport>(
        for configuration: TemporalWorker.Configuration,
        transport: Transport,
        activities: [any ActivityDefinition],
        workflows: [any WorkflowDefinition.Type],
        logger: Logging.Logger
    ) where Transport: GRPCCore.ClientTransport {
        self.init(
            configuration: configuration,
            transport: transport,
            activities: activities,
            workflows: workflows,
            logger: logger
        )
    }
}

extension GenericTemporalWorker: TemporalWorkerProtocol {
    package convenience init<Transport>(
        for configuration: TemporalWorker.Configuration,
        transport: Transport,
        activities: [any ActivityDefinition],
        workflows: [any WorkflowDefinition.Type],
        logger: Logging.Logger
    ) where Transport: GRPCCore.ClientTransport {
        self.init(
            configuration: configuration,
            transport: transport,
            activities: activities,
            workflows: workflows,
            logger: logger
        )
    }
}
