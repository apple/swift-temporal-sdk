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
import GRPCNIOTransportHTTP2Posix
import GRPCOTelTracingInterceptors
import GRPCServiceLifecycle
import Logging
import ServiceLifecycle
import TemporalInstrumentation

/// A Temporal worker that processes activities and workflows for a specific namespace and task queue.
///
/// Use a Temporal worker to register activities and workflows, then process tasks from the Temporal server.
/// The worker polls for tasks, executes them, and reports results back to the server.
///
/// You can manage the worker's lifetime as a `swift-service-lifecycle` `Service` within a
/// `ServiceGroup` for structured concurrency and graceful shutdown handling.
///
/// ## Creating a Worker
///
/// Initialize a worker with configuration, transport, activities, workflows, and a logger:
///
/// ```swift
/// let temporalWorker = TemporalWorker(
///     configuration: .init(
///         namespace: "my-namespace",
///         taskQueue: "my-task-queue"
///     ),
///     transport: .http2NIOPosix(
///         target: .host("localhost", port: 7233),
///         transportSecurity: .plaintext
///     ),
///     activityContainers: MyActivityContainer(),
///     activities: [],
///     workflows: [MyWorkflow.self],
///     logger: logger
/// )
/// ```
///
/// ## Running the Worker
///
/// Start processing tasks by calling the `run()` method:
///
/// ```swift
/// try await temporalWorker.run()
/// ```
///
/// The worker runs indefinitely until cancelled or gracefully shut down.
///
/// ## Lifecycle Management
///
/// The worker supports graceful shutdown through the `Service` protocol. When shutdown is initiated,
/// the worker stops polling for new tasks, completes running tasks, and releases resources.
public final class TemporalWorker: Service, Sendable {
    private let implementation:
        GenericTemporalWorker<
            BridgeWorker,
            WorkflowWorker<BridgeWorker>,
            ActivityWorker<BridgeWorker>,
            AnyUInt8GRPCClient
        >

    /// Creates a Temporal worker with the specified configuration and registrations.
    ///
    /// The worker automatically sets up gRPC client interceptors for tracing, metrics, and logging.
    ///
    /// - Parameters:
    ///   - configuration: The worker configuration including namespace, task queue, and
    ///   operational settings.
    ///   - transport: The transport layer for gRPC communication with the Temporal server.
    ///   - activityContainers: One or more containers that provide activity implementations for
    ///   registration.
    ///   - activities: Additional standalone activity definitions to register alongside container
    ///   activities.
    ///   - workflows: The workflow types to register with this worker for task processing.
    ///   - logger: The logger instance used for diagnostic and debugging output.
    public init<each Container: ActivityContainer, Transport: ClientTransport>(
        configuration: Configuration,
        transport: Transport,
        activityContainers: repeat each Container,
        activities: [any ActivityDefinition] = [],
        workflows: [any WorkflowDefinition.Type] = [],
        logger: Logger
    ) {
        self.implementation = GenericTemporalWorker(
            configuration: configuration,
            transport: transport,
            activityContainers: repeat each activityContainers,
            activities: activities,
            workflows: workflows,
            logger: logger
        )
    }

    public func run() async throws {
        try await self.implementation.run()
    }

    package func run(bridgeRuntime: BridgeRuntime) async throws {
        try await self.implementation.run(bridgeRuntime: bridgeRuntime)
    }
}

package final class GenericTemporalWorker<
    BridgeWorker: BridgeWorkerProtocol,
    WorkflowWorker: WorkflowWorkerProtocol,
    ActivityWorker: ActivityWorkerProtocol,
    Client: UnaryGRPCClient
>: Service
where
    WorkflowWorker.BridgeWorker == BridgeWorker,
    ActivityWorker.BridgeWorker == BridgeWorker,
    Client.Deserializer == UInt8ArrayDeserializer,
    Client.Serializer == UInt8ArraySerializer
{
    /// The worker configuration containing namespace, task queue, and operational settings.
    private let configuration: TemporalWorker.Configuration
    /// The underlying gRPC client used for communication with the Temporal server.
    let workerClient: AnyUInt8GRPCClient
    /// The activity definitions registered with this worker for task execution.
    private let activities: [any ActivityDefinition]
    /// The workflow types registered with this worker for task execution.
    private let workflows: [any WorkflowDefinition.Type]
    /// The logger instance used for diagnostic and debugging output.
    private let logger: Logger

    package convenience init<each Container: ActivityContainer, Transport: ClientTransport>(
        configuration: TemporalWorker.Configuration,
        transport: Transport,
        activityContainers: repeat each Container,
        activities: [any ActivityDefinition],
        workflows: [any WorkflowDefinition.Type],
        logger: Logger
    ) {
        let client = GRPCClient(
            transport: transport,
            interceptors: [
                ClientOTelTracingInterceptor(
                    serverHostname: configuration.instrumentation.serverHostname,
                    networkTransportMethod: "tcp",
                    traceEachMessage: true,
                    includeRequestMetadata: true,
                    includeResponseMetadata: true
                ),
                ClientOTelMetricsInterceptor(
                    serverHostname: configuration.instrumentation.serverHostname,
                    networkTransportMethod: .tcp
                ),
                ClientOTelLoggingInterceptor(
                    logger: logger,
                    serviceName: "swift-temporal-sdk.TemporalWorker.WorkerClient",
                    serverHostname: configuration.instrumentation.serverHostname,
                    networkTransportMethod: .tcp,
                    serviceVersion: Constants.sdkVersion,
                    includeRequestMetadata: true,
                    includeResponseMetadata: true
                ),
            ]
        )

        self.init(
            configuration: configuration,
            client: Client(
                run: client.run,
                unary: client.unary,
                beginGracefulShutdown: client.beginGracefulShutdown
            ),
            activityContainers: repeat each activityContainers,
            activities: activities,
            workflows: workflows,
            logger: logger
        )
    }

    package init<each Container: ActivityContainer>(
        configuration: TemporalWorker.Configuration,
        client: Client,
        activityContainers: repeat each Container,
        activities: [any ActivityDefinition],
        workflows: [any WorkflowDefinition.Type],
        logger: Logger
    ) {
        self.configuration = configuration

        // Extract required gRPC client closures from `GRPCClient<Transport: ClientTransport>`,
        // as C-closures can't capture the generic `Transport` and the `TemporalWorker` stays non-generic
        self.workerClient = .init(
            run: client.run,
            unary: client.unary,
            beginGracefulShutdown: client.beginGracefulShutdown
        )

        var combinedActivities = activities
        for container in repeat each activityContainers {
            combinedActivities.append(contentsOf: container.allActivities)
        }
        self.activities = combinedActivities
        self.workflows = workflows

        self.logger = logger
    }

    /// Runs the Temporal worker to process activities and workflows.
    ///
    /// Creates a new `BridgeRuntime` internally and uses it to start the worker.
    /// Suspends until cancellation or graceful shutdown.
    ///
    /// - Throws: An error when the worker is cancelled, or other errors during startup or operation.
    package func run() async throws {
        try await self.run(bridgeRuntime: .init(telemetryOptions: .init()))  // TODO: Capture telemetry from bridge
    }

    /// Runs the Temporal worker to process activities and workflows.
    ///
    /// Uses the provided `BridgeRuntime` to start the worker.
    /// Suspends until cancellation or graceful shutdown.
    ///
    /// - Parameter bridgeRuntime: The bridge runtime to use for initializing the worker.
    /// - Throws: An error when the worker is cancelled, or other errors during startup or operation.
    package func run(bridgeRuntime: BridgeRuntime) async throws {
        self.logger.debug("Running Temporal worker")

        try await BridgeClient.withBridgeClient(
            grpcClient: self.workerClient,
            runtime: bridgeRuntime,
            configuration: self.configuration,
            logger: self.logger
        ) { client in
            var optionalWorker: BridgeWorker?

            do {
                let worker = try BridgeWorker(
                    client: client,
                    configuration: self.configuration
                )
                optionalWorker = worker

                let activityWorker = ActivityWorker(
                    worker: worker,
                    configuration: self.configuration,
                    activities: self.activities,
                    logger: self.logger
                )
                let workflowWorker = WorkflowWorker(
                    worker: worker,
                    configuration: self.configuration,
                    workflows: self.workflows,
                    logger: self.logger
                )

                try await self.runWorkersIgnoringCancellation(
                    worker: worker,
                    activityWorker: activityWorker,
                    workflowWorker: workflowWorker
                )
            } catch {
                // Activity and workflow worker have shutdown, now finalize it.
                if let worker = optionalWorker {
                    self.logger.debug("Finalizing shut down of Temporal worker")
                    do {
                        try await worker.finalizeShutdown()
                    } catch {
                        // Swallow the error so that we can finish shutdown.
                        self.logger.warning(
                            "Temporal worker failed finalizing shutdown",
                            metadata: [
                                LoggingKeys.error: "\(error)"
                            ]
                        )
                    }
                    self.logger.debug("Finished shutting down bridge worker.")
                }

                self.logger.info("Shut down task queue and worker client.")
                throw error
            }
        }
    }

    // NOTE: The only way for this to return is by throwing
    // an error since the run methods should infinitely loop.
    func runWorkersIgnoringCancellation(
        worker: BridgeWorker,
        activityWorker: ActivityWorker,
        workflowWorker: WorkflowWorker,
        isRunningForShutdown: Bool = false
    ) async throws {
        try await cancelWhenGracefulShutdown {
            try await withTaskCancellationHandler {
                // Block cancellation from propagating inwards.
                try await Task {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            try await activityWorker.run()
                        }
                        group.addTask {
                            try await workflowWorker.run()
                        }

                        if isRunningForShutdown {
                            try await group.waitForAll()
                        } else {
                            // Wait for one of the tasks to fail and then initiate shutdown.
                            self.logger.debug("Waiting for cancellation or graceful shutdown of Temporal worker")
                            do {
                                try await group.next()
                            } catch {
                                self.logger.error(
                                    "Initiating shut down of Temporal worker due to temporal activity / workflow worker error",
                                    metadata: [
                                        LoggingKeys.error: "\(error)"
                                    ]
                                )
                                worker.initiateShutdown()

                                // If the poll task actually completed with an exception to cause this shutdown, we need
                                // to run that poll task again after shutdown since it needs to handle post-shutdown
                                // messages: https://github.com/temporalio/sdk-dotnet/blob/5b15fb8523879db47c3442cf3cfc739643d1ed14/src/Temporalio/Worker/TemporalWorker.cs#L345
                                // TODO: Add a timeout when waiting for all?
                                self.logger.debug("Rerunning workers to clean up and finish work.")
                                try? await self.runWorkersIgnoringCancellation(
                                    worker: worker,
                                    activityWorker: activityWorker,
                                    workflowWorker: workflowWorker,
                                    isRunningForShutdown: true
                                )
                                self.logger.debug(
                                    "Finished rerunning workers for cleanup. Throwing back error.",
                                    metadata: [
                                        LoggingKeys.error: "\(error)"
                                    ]
                                )
                                throw error
                            }

                            fatalError("Activity / workflow worker run method unexpectedly exited cleanly.")
                        }
                    }
                }.value
            } onCancel: {
                self.logger.info("Initiating shut down of Temporal worker")
                worker.initiateShutdown()
            }
        }
    }
}
