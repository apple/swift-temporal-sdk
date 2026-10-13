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
/// A plugin can append interceptors or adjust options such as slot suppliers.
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
    /// Customizes a worker configuration before the worker starts.
    ///
    /// The mutated configuration is passed to the next plugin, and finally to the worker.
    ///
    /// - Parameter configuration: The configuration to customize.
    func configureWorker(_ configuration: inout TemporalWorker.Configuration)

    /// Customizes a replayer configuration before replay begins.
    ///
    /// - Parameter configuration: The replayer configuration to customize.
    func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration)
}

extension WorkerPlugin {
    public func configureWorker(_ configuration: inout TemporalWorker.Configuration) {}

    public func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration) {}
}
