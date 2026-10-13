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

/// A plugin that customizes a ``TemporalWorker`` before it starts and a ``WorkflowReplayer`` before
/// it replays.
///
/// Each plugin's ``configureWorker(_:)`` runs against the ``TemporalWorker/Configuration`` before
/// the worker starts, in the order the plugins appear in ``TemporalWorker/Configuration/plugins``.
/// A plugin can append interceptors, adjust options such as slot suppliers, and contribute
/// ``activities`` and ``workflows``.
///
/// ## Implementing a plugin
///
/// Implement only the requirements you need; the others have defaults:
///
/// ```swift
/// struct MetricsPlugin: WorkerPlugin {
///     func configureWorker(_ configuration: inout TemporalWorker.Configuration) {
///         configuration.interceptors.append(MetricsInterceptor())
///     }
/// }
/// ```
///
/// ## Customizing the replayer
///
/// The same plugin can customize a ``WorkflowReplayer`` through ``configureReplayer(_:)``. Use it
/// for anything that replay needs to match the original run, such as the data converter, and
/// for instrumentation such as logging or metrics.
///
/// - Important: This is currently experimental and may be removed or changed in the future.
public protocol WorkerPlugin: TemporalPlugin {
    /// Activities this plugin registers with the worker.
    ///
    /// They're registered alongside the activities passed to
    /// ``TemporalWorker/init(configuration:transport:activityContainers:activities:workflows:logger:)``.
    /// A replayer ignores them, since replay only runs workflow code.
    ///
    /// - Warning: Registrations are not deduplicated, so registering an activity name twice
    ///   is an error.
    var activities: [any ActivityDefinition] { get }

    /// Workflows this plugin registers with the worker and the replayer.
    ///
    /// They're registered alongside the workflows passed to
    /// ``TemporalWorker/init(configuration:transport:activityContainers:activities:workflows:logger:)``,
    /// and appended to ``WorkflowReplayer/Configuration/workflows`` when a ``WorkflowReplayer`` is
    /// created.
    ///
    /// - Warning: Registrations are not deduplicated, so registering a workflow name twice
    ///   is an error.
    var workflows: [any WorkflowDefinition.Type] { get }

    /// Customizes a worker configuration before the worker starts.
    ///
    /// The mutated configuration is passed to the next plugin, and finally to the worker.
    ///
    /// - Parameter configuration: The configuration to customize.
    func configureWorker(_ configuration: inout TemporalWorker.Configuration)

    /// Customizes a replayer configuration before replay begins.
    ///
    /// To contribute workflows, use ``workflows`` rather than appending to
    /// ``WorkflowReplayer/Configuration/workflows`` here; doing both registers them twice.
    ///
    /// - Parameter configuration: The replayer configuration to customize.
    func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration)
}

extension WorkerPlugin {
    public var activities: [any ActivityDefinition] { [] }

    public var workflows: [any WorkflowDefinition.Type] { [] }

    public func configureWorker(_ configuration: inout TemporalWorker.Configuration) {}

    public func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration) {}
}
