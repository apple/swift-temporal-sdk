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

/// A plugin that bundles interceptors, activities, workflows, and a data converter transform,
/// for use on clients, workers, and replayers.
///
/// `SimplePlugin` conforms to both ``ClientPlugin`` and ``WorkerPlugin``, so one instance can be set
/// on ``TemporalClient/Configuration/plugins``, ``TemporalWorker/Configuration/plugins``, and
/// ``WorkflowReplayer/Configuration/plugins``. Each side uses only what applies to it; a client
/// ignores activities, workflows, and worker interceptors.
///
/// ```swift
/// let plugin = SimplePlugin(
///     name: "my-org.orders",
///     workerInterceptors: [MetricsInterceptor()],
///     activities: [ChargeCardActivity()],
///     workflows: [PlaceOrderWorkflow.self]
/// )
///
/// let configuration = TemporalWorker.Configuration(
///     namespace: "orders",
///     taskQueue: "orders-queue",
///     instrumentation: .init(serverHostname: "temporal.example.com"),
///     plugins: [plugin]
/// )
/// ```
///
/// ## Transforming the data converter
///
/// Pass a closure that receives the existing converter and returns the one to use:
///
/// ```swift
/// let plugin = SimplePlugin(
///     name: "my-org.encryption",
///     dataConverter: { existing in
///         DataConverter(
///             payloadConverter: existing.payloadConverter,
///             failureConverter: existing.failureConverter,
///             payloadCodec: EncryptionCodec()
///         )
///     }
/// )
/// ```
///
/// - Important: This is currently experimental and may be removed or changed in the future.
public struct SimplePlugin: ClientPlugin, WorkerPlugin {
    /// A human-readable name for this plugin, used in diagnostics.
    public let name: String

    /// Transforms the existing data converter, or `nil` to leave it unchanged.
    public let dataConverter: (@Sendable (DataConverter) -> DataConverter)?

    /// Interceptors appended to a client's interceptors.
    public let clientInterceptors: [any ClientInterceptor]

    /// Interceptors appended to a worker's or replayer's interceptors.
    public let workerInterceptors: [any WorkerInterceptor]

    /// Activities registered with a worker.
    public let activities: [any ActivityDefinition]

    /// Workflows registered with a worker or replayer.
    public let workflows: [any WorkflowDefinition.Type]

    /// Creates a new simple plugin.
    ///
    /// - Parameters:
    ///   - name: A human-readable name for this plugin, used in diagnostics.
    ///   - dataConverter: Transforms the existing data converter. Defaults to `nil`, which leaves it
    ///     unchanged.
    ///   - clientInterceptors: Interceptors appended to a client's interceptors. Defaults to none.
    ///   - workerInterceptors: Interceptors appended to a worker's or replayer's interceptors.
    ///     Defaults to none.
    ///   - activities: Activities registered with a worker. Defaults to none.
    ///   - workflows: Workflows registered with a worker or replayer. Defaults to none.
    public init(
        name: String,
        dataConverter: (@Sendable (DataConverter) -> DataConverter)? = nil,
        clientInterceptors: [any ClientInterceptor] = [],
        workerInterceptors: [any WorkerInterceptor] = [],
        activities: [any ActivityDefinition] = [],
        workflows: [any WorkflowDefinition.Type] = []
    ) {
        self.name = name
        self.dataConverter = dataConverter
        self.clientInterceptors = clientInterceptors
        self.workerInterceptors = workerInterceptors
        self.activities = activities
        self.workflows = workflows
    }

    public func configureClient(_ configuration: inout TemporalClient.Configuration) {
        if let dataConverter {
            configuration.dataConverter = dataConverter(configuration.dataConverter)
        }
        configuration.interceptors.append(contentsOf: clientInterceptors)
    }

    public func configureWorker(_ configuration: inout TemporalWorker.Configuration) {
        if let dataConverter {
            configuration.dataConverter = dataConverter(configuration.dataConverter)
        }
        configuration.interceptors.append(contentsOf: workerInterceptors)
    }

    public func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration) {
        if let dataConverter {
            configuration.dataConverter = dataConverter(configuration.dataConverter)
        }
        configuration.interceptors.append(contentsOf: workerInterceptors)
    }
}
