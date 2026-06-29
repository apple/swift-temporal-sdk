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
///
/// ## Bracketing the connect, run, and replay lifetimes
///
/// To run setup or teardown around the connected-client, worker-run, or replay lifetimes, pass the
/// matching `before`/`after` closures. The before closure runs immediately before the wrapped
/// work, the after closure immediately after it returns successfully; if the wrapped work throws,
/// the after closure does not run. If the before closure itself throws, the error propagates and
/// neither the wrapped work nor the after closure runs. For full wrap semantics, such as
/// short-circuiting or mapping errors, conform to ``ClientPlugin`` or ``WorkerPlugin`` directly
/// and override the `connectClient(configuration:next:)`, `runWorker(configuration:next:)`, or
/// `runReplayer(configuration:next:)` method.
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

    /// A closure invoked immediately before the inner work inside ``connectClient(configuration:next:)``.
    public let beforeConnect: (@Sendable (TemporalClient.Configuration) async throws -> Void)?

    /// A closure invoked immediately after the inner work inside ``connectClient(configuration:next:)``.
    ///
    /// Does not run if the inner work throws.
    public let afterConnect: (@Sendable (TemporalClient.Configuration) async throws -> Void)?

    /// A closure invoked immediately before the inner work inside ``runWorker(configuration:next:)``.
    public let beforeRunWorker: (@Sendable (TemporalWorker.Configuration) async throws -> Void)?

    /// A closure invoked immediately after the inner work inside ``runWorker(configuration:next:)``.
    ///
    /// Does not run if the inner work throws.
    public let afterRunWorker: (@Sendable (TemporalWorker.Configuration) async throws -> Void)?

    /// A closure invoked immediately before the inner work inside ``runReplayer(configuration:next:)``.
    public let beforeRunReplayer: (@Sendable (WorkflowReplayer.Configuration) async throws -> Void)?

    /// A closure invoked immediately after the inner work inside ``runReplayer(configuration:next:)``.
    ///
    /// Does not run if the inner work throws.
    public let afterRunReplayer: (@Sendable (WorkflowReplayer.Configuration) async throws -> Void)?

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
    ///   - beforeConnect: An optional closure run immediately before the connected-client work.
    ///   - afterConnect: An optional closure run immediately after the connected-client work
    ///     returns successfully.
    ///   - beforeRunWorker: An optional closure run immediately before the worker's run loop.
    ///   - afterRunWorker: An optional closure run immediately after the worker's run loop returns
    ///     successfully.
    ///   - beforeRunReplayer: An optional closure run immediately before a single replay.
    ///   - afterRunReplayer: An optional closure run immediately after a single replay returns
    ///     successfully.
    public init(
        name: String,
        dataConverter: (@Sendable (DataConverter) -> DataConverter)? = nil,
        clientInterceptors: [any ClientInterceptor] = [],
        workerInterceptors: [any WorkerInterceptor] = [],
        activities: [any ActivityDefinition] = [],
        workflows: [any WorkflowDefinition.Type] = [],
        beforeConnect: (@Sendable (TemporalClient.Configuration) async throws -> Void)? = nil,
        afterConnect: (@Sendable (TemporalClient.Configuration) async throws -> Void)? = nil,
        beforeRunWorker: (@Sendable (TemporalWorker.Configuration) async throws -> Void)? = nil,
        afterRunWorker: (@Sendable (TemporalWorker.Configuration) async throws -> Void)? = nil,
        beforeRunReplayer: (@Sendable (WorkflowReplayer.Configuration) async throws -> Void)? = nil,
        afterRunReplayer: (@Sendable (WorkflowReplayer.Configuration) async throws -> Void)? = nil
    ) {
        self.name = name
        self.dataConverter = dataConverter
        self.clientInterceptors = clientInterceptors
        self.workerInterceptors = workerInterceptors
        self.activities = activities
        self.workflows = workflows
        self.beforeConnect = beforeConnect
        self.afterConnect = afterConnect
        self.beforeRunWorker = beforeRunWorker
        self.afterRunWorker = afterRunWorker
        self.beforeRunReplayer = beforeRunReplayer
        self.afterRunReplayer = afterRunReplayer
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

    public func connectClient<R: Sendable>(
        configuration: TemporalClient.Configuration,
        next: () async throws -> sending R
    ) async throws -> sending R {
        try await beforeConnect?(configuration)
        let result = try await next()
        try await afterConnect?(configuration)
        return result
    }

    public func runWorker(
        configuration: TemporalWorker.Configuration,
        next: () async throws -> Void
    ) async throws {
        try await beforeRunWorker?(configuration)
        try await next()
        try await afterRunWorker?(configuration)
    }

    public func runReplayer<R: Sendable>(
        configuration: WorkflowReplayer.Configuration,
        next: () async throws -> sending R
    ) async throws -> sending R {
        try await beforeRunReplayer?(configuration)
        let result = try await next()
        try await afterRunReplayer?(configuration)
        return result
    }
}
