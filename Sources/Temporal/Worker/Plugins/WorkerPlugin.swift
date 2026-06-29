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

/// A plugin that customizes a ``TemporalWorker`` before it starts, and optionally a
/// ``WorkflowReplayer`` before it replays.
///
/// A worker plugin can register activities and workflows, append interceptors, or adjust any
/// other field on ``TemporalWorker/Configuration`` such as slot suppliers. Each plugin's
/// ``configure(_:)`` method runs against a mutable ``TemporalWorker/Configuration`` before the
/// worker starts, in the order the plugins appear in ``TemporalWorker/Configuration/plugins``.
///
/// ## Implementing a plugin
///
/// Conform to ``WorkerPlugin`` and override only the requirements you need. The protocol provides
/// default no-op implementations for ``configure(_:)`` and ``configureReplayer(_:)``, plus a
/// default ``name`` derived from the conforming type:
///
/// ```swift
/// struct MetricsPlugin: WorkerPlugin {
///     func configure(_ configuration: inout TemporalWorker.Configuration) {
///         configuration.interceptors.append(MetricsInterceptor())
///     }
/// }
/// ```
///
/// ## Customizing the replayer
///
/// The same plugin can customize a ``WorkflowReplayer`` via ``configureReplayer(_:)``. Use it for
/// instrumentation that should also run during replay, such as logging or metrics.
///
/// ## Wrapping worker and replayer lifetimes
///
/// A plugin can also observe and surround the lifetime of a running worker by overriding
/// ``runWorker(configuration:next:)``, and the lifetime of a replay invocation by overriding
/// ``runReplayer(configuration:next:)``. Both methods receive the merged configuration and a
/// continuation closure, and are expected to invoke the continuation as part of their body.
/// Wrapping is useful for emitting telemetry around startup and shutdown, mapping errors, or
/// running setup and teardown that should bracket the worker's or replayer's run. When plugins
/// compose, the first plugin in ``TemporalWorker/Configuration/plugins`` (or
/// ``WorkflowReplayer/Configuration/plugins``) is the outermost wrap.
public protocol WorkerPlugin: Sendable {
    /// A human-readable name used in diagnostics and ordering.
    ///
    /// Defaults to the conforming type's name.
    var name: String { get }

    /// Activity definitions this plugin contributes to the worker.
    ///
    /// Plugin-contributed activities are appended to the activities supplied to
    /// ``TemporalWorker/init(configuration:transport:activityContainers:activities:workflows:logger:)``
    /// before the worker registers them. Defaults to an empty array, so plugins that customize
    /// the worker without registering activities do not need to override this property.
    var activities: [any ActivityDefinition] { get }

    /// Workflow types this plugin contributes to the worker.
    ///
    /// Plugin-contributed workflows are appended to the workflows supplied to
    /// ``TemporalWorker/init(configuration:transport:activityContainers:activities:workflows:logger:)``
    /// before the worker registers them. Defaults to an empty array.
    var workflows: [any WorkflowDefinition.Type] { get }

    /// Customizes a worker configuration before the worker starts.
    ///
    /// Implementations mutate `configuration` in place to adjust fields such as
    /// ``TemporalWorker/Configuration/interceptors`` or other worker options. The mutated
    /// configuration is handed to the next plugin in the chain, and finally to the worker at
    /// initialization time.
    ///
    /// - Parameter configuration: The configuration to customize.
    func configure(_ configuration: inout TemporalWorker.Configuration)

    /// Customizes a workflow replayer configuration before replay begins.
    ///
    /// Implementations mutate `configuration` in place to adjust fields such as
    /// ``WorkflowReplayer/Configuration/interceptors`` or ``WorkflowReplayer/Configuration/workflows``.
    /// The default implementation does nothing, so worker plugins that only customize live workers
    /// need not implement it.
    ///
    /// - Parameter configuration: The replayer configuration to customize.
    func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration)

    /// Wraps the lifetime of a running worker.
    ///
    /// The default implementation forwards through to `next`, so plugins that do not need to
    /// surround the worker run can omit this method. Override to bracket the worker with custom
    /// logic, such as logging, metrics, or error mapping. Implementations must invoke `next`
    /// exactly once. Calling `next` zero times or more than once is undefined behavior; the SDK
    /// reserves the right to detect and reject it in a future release.
    ///
    /// When the configuration carries multiple plugins, the first plugin in
    /// ``TemporalWorker/Configuration/plugins`` is the outermost wrap and the last plugin is the
    /// innermost. The continuation closure invokes the next plugin in the chain, and ultimately
    /// the worker's underlying poll-and-execute loop.
    ///
    /// - Parameters:
    ///   - configuration: The merged configuration the worker is using. Plugins receive the
    ///     configuration after every plugin's ``configure(_:)`` has run.
    ///   - next: A continuation that, when invoked, runs the rest of the plugin chain and the
    ///     worker's underlying run loop.
    func runWorker(
        configuration: TemporalWorker.Configuration,
        next: () async throws -> Void
    ) async throws

    /// Wraps the lifetime of a workflow replay invocation.
    ///
    /// The default implementation forwards through to `next`, so plugins that do not need to
    /// surround replays can omit this method. Override to bracket replays with custom logic,
    /// such as logging or error mapping. Implementations must invoke `next` exactly once and
    /// return whatever value it produces, so the value returned by the public replay API is
    /// preserved. Calling `next` zero times or more than once is undefined behavior; the SDK
    /// reserves the right to detect and reject it in a future release.
    ///
    /// When the configuration carries multiple plugins, the first plugin in
    /// ``WorkflowReplayer/Configuration/plugins`` is the outermost wrap and the last plugin is the
    /// innermost. The continuation closure invokes the next plugin in the chain, and ultimately
    /// the replayer's underlying replay invocation.
    ///
    /// - Parameters:
    ///   - configuration: The merged configuration the replayer is using. Plugins receive the
    ///     configuration after every plugin's ``configureReplayer(_:)`` has run.
    ///   - next: A continuation that, when invoked, runs the rest of the plugin chain and the
    ///     replayer's underlying invocation. Returns the value produced by the public replay
    ///     entry point.
    /// - Returns: The value produced by `next`, optionally transformed by the plugin.
    func runReplayer<R: Sendable>(
        configuration: WorkflowReplayer.Configuration,
        next: () async throws -> sending R
    ) async throws -> sending R
}

extension WorkerPlugin {
    public var name: String {
        String(describing: Self.self)
    }

    public var activities: [any ActivityDefinition] { [] }

    public var workflows: [any WorkflowDefinition.Type] { [] }

    public func configure(_ configuration: inout TemporalWorker.Configuration) {}

    public func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration) {}

    public func runWorker(
        configuration: TemporalWorker.Configuration,
        next: () async throws -> Void
    ) async throws {
        try await next()
    }

    public func runReplayer<R: Sendable>(
        configuration: WorkflowReplayer.Configuration,
        next: () async throws -> sending R
    ) async throws -> sending R {
        try await next()
    }
}
