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
}

extension WorkerPlugin {
    public var name: String {
        String(describing: Self.self)
    }

    public var activities: [any ActivityDefinition] { [] }

    public var workflows: [any WorkflowDefinition.Type] { [] }

    public func configure(_ configuration: inout TemporalWorker.Configuration) {}

    public func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration) {}
}
