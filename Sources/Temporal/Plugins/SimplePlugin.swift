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

/// A plugin value that carries interceptors, activities, workflows, and an optional data converter
/// transform, and applies them when the client or worker configures.
///
/// `SimplePlugin` conforms to both ``ClientPlugin`` and ``WorkerPlugin``, so a single instance can
/// be set on either ``TemporalClient/Configuration/plugins`` or
/// ``TemporalWorker/Configuration/plugins``. When the same instance is set on both sides, the
/// client side customizes the client configuration and the worker side customizes the worker
/// configuration and registers plugin-contributed activities and workflows.
///
/// ## Example
///
/// ```swift
/// let plugin = SimplePlugin(
///     name: "my-org.observability",
///     clientInterceptors: [authInterceptor],
///     workerInterceptors: [metricsInterceptor],
///     activities: [MyActivity()],
///     workflows: [MyWorkflow.self]
/// )
///
/// let configuration = TemporalClient.Configuration(
///     instrumentation: .init(serverHostname: "temporal.example.com"),
///     plugins: [plugin]
/// )
/// ```
///
/// ## Transforming the data converter
///
/// To wrap or substitute the data converter, pass a closure that receives the existing converter
/// and returns the replacement:
///
/// ```swift
/// let plugin = SimplePlugin(
///     name: "my-org.encryption",
///     dataConverter: { existing in EncryptingDataConverter(wrapping: existing) }
/// )
/// ```
public struct SimplePlugin: ClientPlugin, WorkerPlugin {
    /// A human-readable name used in diagnostics and ordering.
    public let name: String

    /// A closure that wraps or replaces the existing data converter, if non-nil.
    public let dataConverter: (@Sendable (DataConverter) -> DataConverter)?

    /// Client interceptors appended to the client's interceptor chain when this plugin runs.
    public let clientInterceptors: [any ClientInterceptor]

    /// Worker interceptors appended to the worker's interceptor chain when this plugin runs.
    public let workerInterceptors: [any WorkerInterceptor]

    /// Activities the plugin registers with the worker.
    public let activities: [any ActivityDefinition]

    /// Workflows the plugin registers with the worker and replayer.
    public let workflows: [any WorkflowDefinition.Type]

    /// Creates a new simple plugin.
    ///
    /// - Parameters:
    ///   - name: A required human-readable name used in diagnostics and ordering.
    ///   - dataConverter: An optional closure that wraps the existing data converter. If `nil`,
    ///     the data converter is left unchanged.
    ///   - clientInterceptors: Client interceptors appended to the configuration's interceptors.
    ///     Defaults to empty.
    ///   - workerInterceptors: Worker interceptors appended to the configuration's interceptors.
    ///     Defaults to empty.
    ///   - activities: Activities registered with the worker. Defaults to empty.
    ///   - workflows: Workflows registered with the worker and replayer. Defaults to empty.
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

    public func configure(_ configuration: inout TemporalClient.Configuration) {
        if let dataConverter {
            configuration.dataConverter = dataConverter(configuration.dataConverter)
        }
        configuration.interceptors.append(contentsOf: clientInterceptors)
    }

    public func configure(_ configuration: inout TemporalWorker.Configuration) {
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
