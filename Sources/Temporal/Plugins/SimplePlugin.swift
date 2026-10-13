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

/// A plugin that bundles interceptors, activities, workflows, a data converter transform, and
/// lifecycle closures, for use on clients, workers, and replayers.
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
/// ## Running code before and after connect, run, and replay
///
/// The `before` closures run immediately before the wrapped work, and the `after` closures once it
/// finishes, whether it returned or threw. If a `before` closure throws, neither the work nor the
/// matching `after` closure runs.
///
/// If both the work and the `after` closure throw, the work's error propagates, unless it's a
/// `CancellationError`. A worker's run normally ends with one, so in that case the `after` closure's
/// error propagates instead, and a failed teardown isn't hidden. The `after` closure runs in the
/// same task as the work, so if that task was cancelled, async calls in the `after` closure that
/// check for cancellation throw.
///
/// The `before` and `after` closures only receive the configuration. To see the work's error, or
/// run the work inside a scope such as `TaskLocal.withValue`, conform to ``ClientPlugin`` or
/// ``WorkerPlugin`` directly.
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

    /// Runs before the work inside ``connectClient(configuration:next:)``.
    public let beforeConnect: (@Sendable (TemporalClient.Configuration) async throws -> Void)?

    /// Runs after the work inside ``connectClient(configuration:next:)``, whether it returned or threw.
    public let afterConnect: (@Sendable (TemporalClient.Configuration) async throws -> Void)?

    /// Runs before the work inside ``runWorker(configuration:next:)``.
    public let beforeRunWorker: (@Sendable (TemporalWorker.Configuration) async throws -> Void)?

    /// Runs after the work inside ``runWorker(configuration:next:)``, whether it returned or threw.
    public let afterRunWorker: (@Sendable (TemporalWorker.Configuration) async throws -> Void)?

    /// Runs before the work inside ``runReplayer(configuration:next:)``.
    public let beforeRunReplayer: (@Sendable (WorkflowReplayer.Configuration) async throws -> Void)?

    /// Runs after the work inside ``runReplayer(configuration:next:)``, whether it returned or threw.
    public let afterRunReplayer: (@Sendable (WorkflowReplayer.Configuration) async throws -> Void)?

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
    ///   - beforeConnect: Runs before the work inside ``connectClient(configuration:next:)``.
    ///     Defaults to `nil`.
    ///   - afterConnect: Runs after the work inside ``connectClient(configuration:next:)``, whether
    ///     it returned or threw. Defaults to `nil`.
    ///   - beforeRunWorker: Runs before the work inside ``runWorker(configuration:next:)``.
    ///     Defaults to `nil`.
    ///   - afterRunWorker: Runs after the work inside ``runWorker(configuration:next:)``, whether it
    ///     returned or threw. Defaults to `nil`.
    ///   - beforeRunReplayer: Runs before the work inside ``runReplayer(configuration:next:)``.
    ///     Defaults to `nil`.
    ///   - afterRunReplayer: Runs after the work inside ``runReplayer(configuration:next:)``,
    ///     whether it returned or threw. Defaults to `nil`.
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

    public func connectClient<R: Sendable>(
        configuration: TemporalClient.Configuration,
        next: () async throws -> sending R
    ) async throws -> sending R {
        try await beforeConnect?(configuration)
        let result: R
        do {
            result = try await next()
        } catch {
            try await Self.runAfter(afterConnect, configuration, afterFailure: error)
        }
        try await afterConnect?(configuration)
        return result
    }

    public func runWorker(
        configuration: TemporalWorker.Configuration,
        next: () async throws -> Void
    ) async throws {
        try await beforeRunWorker?(configuration)
        do {
            try await next()
        } catch {
            try await Self.runAfter(afterRunWorker, configuration, afterFailure: error)
        }
        try await afterRunWorker?(configuration)
    }

    public func runReplayer<R: Sendable>(
        configuration: WorkflowReplayer.Configuration,
        next: () async throws -> sending R
    ) async throws -> sending R {
        try await beforeRunReplayer?(configuration)
        let result: R
        do {
            result = try await next()
        } catch {
            try await Self.runAfter(afterRunReplayer, configuration, afterFailure: error)
        }
        try await afterRunReplayer?(configuration)
        return result
    }

    /// Runs `after` once the wrapped work has thrown `failure`, then throws whichever error wins.
    ///
    /// `failure` wins unless it's a `CancellationError`. A worker's run normally ends by throwing
    /// one, so letting it win would hide a failed teardown. This runs from a `catch` because
    /// `defer` can't throw.
    private static func runAfter<Config: Sendable>(
        _ after: (@Sendable (Config) async throws -> Void)?,
        _ configuration: Config,
        afterFailure failure: any Error
    ) async throws -> Never {
        if failure is CancellationError {
            try await after?(configuration)
        } else {
            try? await after?(configuration)
        }
        throw failure
    }
}
